# Claude YOLO Docker

[![CI](https://github.com/cadentdev/claude-yolo-docker/actions/workflows/ci.yml/badge.svg)](https://github.com/cadentdev/claude-yolo-docker/actions/workflows/ci.yml)

A Docker wrapper for running Claude Code with `--dangerously-skip-permissions` in isolated environments.

## What This Does

This project creates a safe, isolated Docker container for running Claude Code in "YOLO mode" (skipping permission prompts). The container only has access to your current project directory, protecting the rest of your system.

The `--headless` option enables non-interactive execution without TTY allocation, making it ideal for cron jobs, CI/CD pipelines, and even running `claude-yo` from within Claude Code itself for automated workflows.

## Philosophy

- **Keep it simple**: The container and launch script are intended for one thing: run YOLO Claude Code in a restricted environment. The container includes Python 3.12 and Node.js 20 for running code, but intentionally excludes version control tools.
- **Git belongs on the host**: Git is **intentionally not included** in the container. All git operations (commit, push, pull, branch) should be performed on your host system before or after running `claude-yo`. This keeps the container focused and prevents accidental commits from inside the sandbox.
- **Keep it fast**: The Docker container is built to reduce size and ensure fast load times. The default options get you right into Claude Code without delay.
- **Helpful options for advanced use**: The script includes options like `--rebuild` to get the latest version of Claude Code, `--verbose` for full session logging, `--debug` for troubleshooting, and per-project customization via `.claude-yo.yml`.

## Features

- **Isolation**: Claude Code runs in a Docker container, not directly on your host
- **Directory Mounting**: Only your current directory is accessible to Claude
- **Persistent Authentication**: Auth tokens stored in a Docker volume, shared across all projects
- **User Mapping**: Files created by Claude maintain your user ownership
- **Interactive Mode**: Drop directly into Claude Code's CLI prompt
- **Debug Mode**: Optional persistent shell access after Claude exits for exploration and troubleshooting
- **Headless Mode**: Non-interactive execution for cron jobs and CI/CD automation
- **Session Logging**: Automatic logging of all sessions with verbose mode for full capture
- **Execution Time Tracking**: Displays elapsed time when sessions complete
- **Flexible Workflows**: Combine flags for different use cases (fast, debugging, auditing, automation)
- **Per-Project Customization**: Install project-specific tools via `.claude-yo.yml` config file

## Default Docker Image

The default container is based on `python:3.12-slim-bookworm` and includes:

- **Python 3.12** - Full Python environment with pip
- **Node.js 20** - Available for user projects (installed via NodeSource)
- **Claude Code** - Installed via native installer (recommended by Anthropic)
- **Basic Linux utilities** - Standard tools like `ls`, `grep`, `cat`, etc.

**What's NOT included by design:**
- Git (use on host before/after running `claude-yo`)
- Build tools (gcc, make, etc.)
- Database clients
- Cloud CLIs

This keeps the image small and fast. For projects needing additional tools, use [Per-Project Customization](#per-project-customization).

## Per-Project Customization

You can customize the Docker environment for each project by creating a `.claude-yo.yml` file in your project root. This is useful when your project requires additional tools, npm packages, or custom dependencies.

### Example Configuration

```yaml
# .claude-yo.yml - all sections are optional

# System packages installed via apt-get
apt:
  - git
  - curl

# Python packages (Python 3.12 is included in the default image)
pip:
  - pytest
  - black
  - mypy

# Global npm packages
npm:
  - typescript
  - eslint

# Custom shell commands (escape hatch for advanced users)
run:
  - "curl -sSL https://install.python-poetry.org | python3 -"
```

### Using a Custom Base Image

For Node.js-heavy projects, you can specify the Node.js base image to avoid the Python overhead:

```yaml
# .claude-yo.yml - Node.js project example
base: node:20-bookworm-slim

npm:
  - typescript
  - eslint
```

When you specify `base:`, claude-yo will:
1. Start from your specified image instead of the default Python base
2. Automatically install Claude Code via native installer
3. Apply your apt/pip/npm/run customizations

**Supported base images**: Any Debian-based image from [Docker Hub Official Images](https://hub.docker.com/search?image_filter=official&q=). Common choices:
- `node:20-bookworm-slim` - Node.js projects (smaller, no Python)
- `python:3.11-slim-bookworm` - Different Python version
- `ruby:3.2-bookworm` - Ruby projects
- `golang:1.22-bookworm` - Go projects

Alpine-based images (e.g., `python:3.12-alpine`) are **not supported** due to missing glibc.

### How It Works

1. When you run `claude-yo`, it checks for `.claude-yo.yml` in the current directory
2. If found, it generates a project-specific Docker image extending the base image (or your custom `base:`)
3. The project image is cached based on a hash of your config file
4. Subsequent runs use the cached image for fast startup
5. When you modify `.claude-yo.yml`, the image is automatically rebuilt

### Image Caching

- Project images are tagged like `claude-yolo-project:myproject-a1b2c3d4`
- The hash suffix ensures config changes trigger a rebuild
- Old cached images for the same project are automatically cleaned up
- Use `--rebuild` to force a fresh build of both base and project images

### Tips

- **Python included by default**: The default image includes Python 3.12, so you can use `pip` directly without adding Python to `apt`
- **Keep configs in version control**: Commit your `.claude-yo.yml` so team members get the same environment
- **Use `run` sparingly**: Prefer `apt`, `pip`, and `npm` sections when possible for better caching

## Prerequisites

- Docker installed and running
- Bash shell
- Claude account with one of:
  - **Pro/Max subscription**: Requires GUI environment with browser for OAuth authentication
  - **API key**: Can authenticate in any terminal (no browser needed)

## Installation

1. Clone this repository:
```bash
git clone https://github.com/cadentdev/claude-yolo-docker.git
cd claude-yolo-docker
```

2. Make the wrapper script executable:
```bash
chmod +x claude-yo
```

3. (Optional) Add to your PATH or create a symlink:

**Check your PATH first**

```bash
echo $PATH
```

**Option A:** Symlink to a directory in your PATH

```bash
# Create ~/.local/bin if it doesn't exist, then symlink
[ -d "$HOME/.local/bin" ] || mkdir -p "$HOME/.local/bin"
ln -s "$(pwd)/claude-yo" "$HOME/.local/bin/claude-yo"
```

**Note:** Ensure `~/.local/bin` is in your PATH (see Option B below)

**Option B:** Add this directory to your PATH

**macOS (zsh):**

```bash
echo 'export PATH="$PATH:'$(pwd)'"' >> ~/.zshrc
source ~/.zshrc
```

**Linux (bash):**

```bash
echo 'export PATH="$PATH:'$(pwd)'"' >> ~/.bashrc
source ~/.bashrc
```

## Usage

### Basic Usage

Navigate to your project directory and run:
```bash
cd ~/my-project
/path/to/claude-yolo-docker/claude-yo
```

Or if you added it to your PATH:
```bash
cd ~/my-project
claude-yo
```

On first run, you'll need to authenticate. Run Claude Code interactively (without `--headless`) and use the `/login` command:

- **Pro/Max users**: Authentication opens a browser for OAuth. You must run from a GUI environment (not SSH without X11 forwarding).
- **API key users**: Enter your API key directly in the terminal. Works in any environment.

Once authenticated, the session persists in a Docker volume, so subsequent runs (including `--headless` and SSH sessions) work without re-authenticating.

After authentication, you'll be dropped directly into Claude Code's interactive prompt where you can type your commands.

**Default behavior**: When you exit Claude (type `/exit`), the container exits immediately and returns you to your host shell.

**Debug mode** (`--debug`): When you exit Claude, you'll drop into a persistent bash shell inside the container for exploration. Type `exit` to save your authentication data and leave the container.

### Typical Workflow (with Git)

Since git is intentionally excluded from the container, use this workflow:

```bash
# 1. On host: Pull latest changes
cd ~/my-project
git pull

# 2. Run Claude Code in container
claude-yo

# 3. (Inside container) Work with Claude...
#    Claude can read/write files, run tests, etc.
#    Type /exit when done

# 4. Back on host: Review and commit changes
git status
git diff
git add -A && git commit -m "feat: add new feature"
git push
```

This keeps your git history clean and prevents accidental commits from inside the sandbox.

**Tip:** For long, uninterrupted Claude Code sessions, consider switching to a new git branch to isolate your changes even further.

### Command-Line Options

**Display help:**
```bash
claude-yo --help
# or
claude-yo -h
```

**Pass arguments to Claude Code:**

Any arguments not recognized by the wrapper are passed directly to Claude Code:
```bash
# Pass a prompt
claude-yo -p "Review the README and suggest improvements"

# Use a specific model
claude-yo --model sonnet

# Combine wrapper flags with Claude Code flags
claude-yo -d -p "Fix the failing tests" --model opus
```

Wrapper flags (`-r`, `-v`, `-d`, `-h`, `--headless`) are intentionally chosen to avoid collision with Claude Code's flags.

**Force rebuild (update Claude Code or start fresh):**
```bash
claude-yo --rebuild
# or
claude-yo -r
```

The `--rebuild` flag will:
- Remove the existing Docker image
- Rebuild from scratch without using cache
- Install the latest version of Claude Code
- Preserve your authentication (no need to log in again)

**Enable verbose mode (full session logging):**
```bash
claude-yo --verbose
# or
claude-yo -v
```

The `--verbose` flag will:
- Show a "Press Enter" prompt before starting Claude (time to review container setup)
- Log the complete Docker session including all Claude Code output
- Create larger log files useful for debugging issues
- Use the `script` command to capture terminal output with ANSI codes

**Enable debug mode (persistent container shell):**
```bash
claude-yo --debug
# or
claude-yo -d
```

The `--debug` flag will:
- Show a "Press Enter" prompt before starting Claude (time to review container setup)
- Keep the container shell running after Claude exits
- Allow you to explore the container, test commands, or inspect files
- Save authentication data when you type `exit` to leave

**Enable headless mode (for cron/automation):**
```bash
claude-yo --headless -p "Run the test suite"
```

The `--headless` flag will:
- Run Docker without TTY allocation (no interactive terminal)
- Skip all prompts and banners for clean output
- Preserve Claude's exit code for error handling in scripts
- Cannot be combined with `--debug` (mutually exclusive)

**Combine flags for different workflows:**
```bash
# Fast workflow (default)
claude-yo

# Full session logging (for review/debugging)
claude-yo --verbose

# Persistent shell for exploration
claude-yo --debug

# Persistent shell + full logging (complete audit trail)
claude-yo --debug --verbose

# Non-interactive for cron/CI
claude-yo --headless -p "Run tests and report results"

# Rebuild with any mode
claude-yo --rebuild --debug
```

### Workflow Modes

The `--debug` and `--verbose` flags control two independent aspects of `claude-yo`:

| Mode | Flags | Press Enter | Exit Behavior | Logging | Use Case |
|------|-------|-------------|---------------|---------|----------|
| **Fast** | (none) | ❌ No | Immediate exit | Wrapper only | Production workflow |
| **Verbose** | `--verbose` | ✅ Yes | Immediate exit | Full session | Review/debugging |
| **Debug** | `--debug` | ✅ Yes | Persistent shell | Wrapper only | Interactive exploration |
| **Debug + Verbose** | `--debug --verbose` | ✅ Yes | Persistent shell | Full session | Complete audit trail |
| **Headless** | `--headless` | ❌ No | Immediate exit | Wrapper only | Cron/CI automation |

**When to use each mode:**

- **Fast (default)**: Day-to-day development. Quick startup, clean exit.
- **Verbose**: When you need to review Claude's changes or debug issues. Creates complete session logs.
- **Debug**: When you want to explore the container, test commands, or inspect file changes before exiting.
- **Debug + Verbose**: When you need both exploration and a complete log for debugging complex issues.
- **Headless**: For automated tasks like cron jobs, CI pipelines, or scripts. No TTY required.

### Updating Claude Code

To get the latest version of Claude Code, simply rebuild the Docker image:
```bash
claude-yo --rebuild
```

This is the recommended way to update Claude Code, as it ensures you're always running the latest version in a clean environment.

## How It Works

1. The wrapper script (`claude-yo`) captures your user ID, group ID, and current directory
2. It builds a Docker image (first run only) with Python 3.12, Node.js 20, and Claude Code (via native installer)
3. It starts a container that:
   - Mounts your current directory to `/workspace`
   - Mounts a persistent Docker volume for authentication data
   - Creates a user inside the container matching your host UID/GID
   - Restores authentication from previous sessions (if available)
   - Runs `claude --dangerously-skip-permissions` as that user
   - Saves authentication data back to the volume when you exit

## Session Logging

All `claude-yo` sessions are automatically logged to help with debugging and tracking script operations.

### Execution Time Tracking

Every session displays the total elapsed time when it completes:
```
Completed in 2m 34s
```

This is logged to both the console and the log file, making it easy to track how long tasks take.

### Log Location

Logs are stored in: `~/.claude-yolo/logs/`

Each session creates a timestamped log file: `claude-yolo-YYYY-MM-DD-HHMMSS.log`

### Default Mode (Fast & Clean)

By default (without `--verbose`), `claude-yo` logs only wrapper script operations:
- Build output (when building or rebuilding the Docker image)
- Container setup information (user, UID/GID, working directory)
- Error messages from the script or Docker
- **Does NOT log** Claude Code session output or debug shell commands

This applies to both normal mode and `--debug` mode (unless combined with `--verbose`).

**Benefits:**
- Small, readable log files (~10-15 lines typically)
- Easy to review build errors or script issues
- Container setup info for debugging UID/permission issues
- Minimal disk space usage
- Fast workflow (no "Press Enter" prompt in default mode)

**Example log contents:**
```
Session log: /home/user/.claude-yolo/logs/claude-yolo-2025-10-17-143522.log
═══════════════════════════════════════════════════════════════
Container Setup
═══════════════════════════════════════════════════════════════
Container user:      user
UID:GID:             1000:1000
Working directory:   /home/user/my-project
                     → mounted at /workspace
═══════════════════════════════════════════════════════════════
```

### Verbose Mode (Full Session Capture)

Run with `--verbose` to capture everything:
```bash
# Verbose mode (immediate exit after Claude)
claude-yo --verbose

# Verbose + Debug mode (persistent shell + full logging)
claude-yo --debug --verbose
```

**What gets logged:**
- Everything from default mode
- Full Claude Code session output (all messages, responses, file changes)
- Debug shell commands and output (if using `--debug --verbose`)
- Terminal control sequences and ANSI color codes

**Benefits:**
- Complete session trace for debugging
- Reproduce what happened during a Claude session
- Share logs with others for troubleshooting
- With `--debug --verbose`, captures everything including exploration commands

**Trade-offs:**
- Large log files (can be thousands of lines)
- Includes terminal control codes (may be hard to read)
- Shows "Press Enter" prompt before starting (gives time to review setup)

### Viewing Logs

**List all session logs:**
```bash
ls -lh ~/.claude-yolo/logs/
```

**View the most recent log:**
```bash
cat ~/.claude-yolo/logs/$(ls -t ~/.claude-yolo/logs/ | head -1)
```

**Search logs for errors:**
```bash
grep -i error ~/.claude-yolo/logs/*.log
```

**Clean up old logs:**
```bash
# Remove logs older than 30 days
find ~/.claude-yolo/logs/ -name "*.log" -mtime +30 -delete
```

## Important Security Notes

⚠️ **Always `cd` to your specific project directory before running!** 

Claude will have FULL ACCESS to the current directory and all subdirectories. Never run this in:
- Your home directory (`~`)
- System directories (`/`, `/etc`, `/usr`)
- Any directory containing sensitive data

The container provides isolation, but Claude still has unrestricted access to whatever directory you mount.

## Troubleshooting

**Image won't build**: Check that Docker is running and you have internet access for the Claude Code native installer. If you see "no such file or directory" for the Dockerfile, ensure you're using the latest version of `claude-yo` which properly resolves symlinks.

**Authentication fails over SSH (Pro/Max users)**: OAuth authentication requires browser access. For first-time authentication:
- Run `claude-yo` from a local terminal in a GUI environment, OR
- Use SSH with X11 forwarding enabled (`ssh -X` or `ssh -Y`), OR
- Authenticate on a different machine first, then copy the `claude-yolo-home` volume to your SSH server

**API key users** can authenticate directly over SSH by running `/login` and entering their API key.

**Authentication not persisting**: The auth data is stored in a Docker volume named `claude-yolo-home`. Check it exists with `docker volume ls`. To reset authentication, remove the volume: `docker volume rm claude-yolo-home`

**Permission errors**: The script automatically matches your UID/GID, but if you still see issues, check Docker permissions.

**Terminal warnings**: You may see "cannot set terminal process group" warnings when dropping to the debug shell. These are harmless and don't affect functionality.

**Inspect persistent data**: View the volume contents with:
```bash
docker volume inspect claude-yolo-home
```

**Need to update Claude Code?**: Use the `--rebuild` flag to rebuild the image and get the latest version:
```bash
claude-yo --rebuild
```

## Learning Resources

This project was built as a learning exercise to understand:
- Docker basics (Dockerfiles, images, containers)
- Volume mounting and bind mounts
- User ID mapping between host and container
- Writing wrapper scripts for Docker workflows

## License

MIT

## Contributing

Issues and pull requests welcome!
