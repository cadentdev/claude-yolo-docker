# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Docker wrapper for running Claude Code with `--dangerously-skip-permissions` in isolated environments. The project consists of:

- **Dockerfile**: Minimal Node.js 20 container that installs Claude Code globally
- **claude-yo**: Bash wrapper script that handles container lifecycle and user mapping
- **Architecture**: Single-container design with persistent authentication via Docker volumes

## Key Architecture Decisions

### User ID Mapping
The wrapper script (`claude-yo:32-36`) captures the host user's UID/GID and creates a matching user inside the container. This ensures files created by Claude maintain proper ownership on the host system.

The Dockerfile (`Dockerfile:3-4`) removes the default `node` user from the base image to prevent UID collisions. Most Linux host users have UID 1000, which would conflict with the node image's built-in `node` user (also UID 1000). By removing it, the wrapper script can cleanly create a user with the exact host UID.

### Persistent Authentication
Authentication tokens are stored in a Docker volume (`claude-yolo-home`) rather than mounting the host's `~/.claude` directory. The container:
1. Restores the user's home directory from the volume on startup (`claude-yo:77-80`)
2. Runs Claude Code as the mapped user
3. Saves the home directory back to the volume on exit (`claude-yo:107-109`)

This approach allows authentication to persist across container runs and different projects without exposing host credentials.

### Debug Shell Access
After Claude exits, the container drops into an interactive bash shell (`claude-yo:96-105`). This allows users to inspect the container state, test commands, or debug issues before the container is removed.

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
The script checks for existing users with matching UID before creating new ones (`claude-yo:66-75`). This handles edge cases where the UID already exists in the base image.

### Working Directory
The Dockerfile sets `/workspace` as the working directory, and the wrapper ensures Claude Code runs there (`claude-yo:97`).

## Security Considerations

**Directory Isolation**: Claude has full access to whatever directory is mounted. Users must `cd` to their specific project directory before running `./claude-yo`. Never run from home directory or system directories.

**Container Isolation**: The container is isolated from the host except for the mounted project directory. No network restrictions are applied.

**Permissions**: The container runs with `--rm` flag to ensure cleanup after exit.
