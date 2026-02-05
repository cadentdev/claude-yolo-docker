# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Docker wrapper for running Claude Code with `--dangerously-skip-permissions` in isolated environments. The project consists of:

- **Dockerfile**: Python 3.12 container with Node.js 20 that installs Claude Code via native installer
- **claude-yo**: Bash wrapper script that handles container lifecycle and user mapping
- **Architecture**: Single-container design with persistent authentication via Docker volumes

## Key Architecture Decisions

### User ID Mapping
The wrapper script (`claude-yo:254-258`) captures the host user's UID/GID and creates a matching user inside the container. This ensures files created by Claude maintain proper ownership on the host system.

### Persistent Authentication
Authentication tokens are stored in a Docker volume (`claude-yolo-home`) rather than mounting the host's `~/.claude` directory. The container uses reusable script components:
1. `CONTAINER_USER_SETUP` (`claude-yo:331-345`): Creates user and restores home directory from volume
2. Runs Claude Code as the mapped user
3. `CONTAINER_SAVE_HOME` (`claude-yo:360-363`): Saves home directory back to volume on exit

This approach allows authentication to persist across container runs and different projects without exposing host credentials.

### Debug Shell Access
When run with `--debug` flag, after Claude exits the container drops into an interactive bash shell. This allows users to inspect the container state, test commands, or debug issues before the container is removed. Without `--debug`, the container exits immediately after Claude.

### Git Exclusion Policy
Git is **intentionally not included** in the container. All version control operations should happen on the host system before or after running `claude-yo`. This design:
- Prevents accidental commits from inside the sandbox
- Keeps the container focused on code execution
- Ensures clean separation between development and version control

### Command-Line Argument Passthrough
The wrapper parses its own flags (`-r`, `-v`, `-d`, `-h`, `--headless`) and passes all other arguments directly to Claude Code. This allows users to pass prompts, model selection, and other Claude Code options:

```bash
claude-yo -p "Review the README"
claude-yo --model sonnet
claude-yo -d -p "Fix the tests" --model opus
claude-yo --headless -p "Run tests"  # Non-interactive mode for cron/CI
```

**Flag naming convention**: Wrapper flags are intentionally chosen to avoid collision with Claude Code's flags. Claude Code uses long-form flags like `--model`, `--allowedTools`, `--print`, etc. The wrapper uses short flags (`-r`, `-v`, `-d`) and the long-form `--headless` (which Claude Code doesn't use).

### Headless Mode
When run with `--headless` flag, the container runs without TTY allocation for use in cron jobs, CI pipelines, and automated scripts. Headless mode is mutually exclusive with `--debug` (validated at `claude-yo:80-83`).

### Per-Project Customization
Projects can include a `.claude-yo.yml` file to specify additional tools and packages. The wrapper script:
1. Detects `.claude-yo.yml` in the mounted project directory
2. Validates the YAML syntax and security (no shell metacharacters)
3. Generates a project-specific Dockerfile extending `claude-yolo:latest` (or custom base)
4. Builds and caches the project image with a hash-based tag
5. Uses the project image instead of the base image for that session

The YAML schema supports:
- `base`: Custom Docker base image (e.g., `node:20-bookworm-slim` for Node.js-only projects). When specified, Claude Code is automatically installed via native installer.
- `apt`: System packages via apt-get
- `pip`: Python packages (Python 3.12 is included in the default image)
- `npm`: Global npm packages
- `run`: Custom shell commands

Image caching uses the pattern `claude-yolo-project:<project-name>-<config-hash>` to ensure rebuilds happen only when the config changes.

## Common Commands

### Building and Running

**Build the Docker image:**
```bash
docker build -t claude-yolo:latest .
```

**Run the wrapper (builds automatically if needed):**
```bash
./claude-yo
```

**Force rebuild (get latest Claude Code version):**
```bash
./claude-yo --rebuild
```

### Testing and Development

**Test the Dockerfile directly:**
```bash
docker build -t claude-yolo:latest .
docker run -it --rm -v $(pwd):/workspace claude-yolo:latest bash
```

**Inspect persistent authentication volume:**
```bash
docker volume inspect claude-yolo-home
```

**Reset authentication (remove volume):**
```bash
docker volume rm claude-yolo-home
```

**View build without cache:**
```bash
docker build --no-cache -t claude-yolo:latest .
```

## Important Implementation Details

### Volume Mounts
The wrapper uses two mounts:
- `-v "$MOUNTDIR":/workspace`: Current directory (project code)
- `-v claude-yolo-home:/home-persist`: Persistent authentication data

### Container User Creation
The `CONTAINER_USER_SETUP` script component (`claude-yo:331-345`) checks for existing users with matching UID before creating new ones. This handles edge cases where the UID already exists in the base image.

### Working Directory
The Dockerfile sets `/workspace` as the working directory, and the wrapper ensures Claude Code runs there via the container scripts.

### Execution Time Tracking
The wrapper records start time (`claude-yo:101`) and uses an EXIT trap (`claude-yo:133`) to display elapsed time when the session ends. The `format_elapsed_time` function (`claude-yo:108-122`) converts seconds to human-readable format (e.g., "2m 34s").

### Refactored Container Scripts
To reduce code duplication across the 5 execution modes, common container setup logic is extracted into reusable shell script variables (`claude-yo:325-379`):
- `CONTAINER_USER_SETUP`: User creation and home directory restoration
- `CONTAINER_BANNER`: Setup complete message display
- `CONTAINER_SAVE_HOME`: Home directory persistence
- `CONTAINER_DEBUG_SHELL`: Debug shell messaging and user switch

## Versioning

This project uses **dual versioning**: a VERSION variable in the script AND git tags.

### How It Works
- `VERSION` variable at top of `claude-yo` (~line 5) - displayed by `--version` flag
- Git tags (e.g., `v1.0.0`) - used for GitHub releases and commit references

### When Releasing a New Version

**IMPORTANT:** Always update BOTH:

1. **Update the VERSION variable** in `claude-yo`:
   ```bash
   VERSION="1.1.0"  # Change this line
   ```

2. **Create a matching git tag**:
   ```bash
   git add claude-yo
   git commit -m "chore: bump version to 1.1.0"
   git tag -a v1.1.0 -m "Release v1.1.0"
   git push && git push --tags
   ```

### Version Format
Follow [Semantic Versioning](https://semver.org/):
- **MAJOR.MINOR.PATCH** (e.g., `1.2.3`)
- MAJOR: Breaking changes
- MINOR: New features (backwards compatible)
- PATCH: Bug fixes

## Security Considerations

**Directory Isolation**: Claude has full access to whatever directory is mounted. Users must `cd` to their specific project directory before running `./claude-yo`. Never run from home directory or system directories.

**Container Isolation**: The container is isolated from the host except for the mounted project directory. No network restrictions are applied.

**Permissions**: The container runs with `--rm` flag to ensure cleanup after exit.
