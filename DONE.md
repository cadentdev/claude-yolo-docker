# Completed Tasks

## claude-yolo

- [x] Remove code to import authorization token from ~/.claude on the host machine
- [x] Fix variable escaping in home directory save operation (cp: cannot stat '/home/$CONTAINER_USER/.')
- [x] Add a "rebuild" to force a container rebuild (`-r` or `--rebuild`)
- [x] Fix UID collision with node user (removed node user from Dockerfile)
- [x] Write script output to a log file by default (tee to console too)
  - Logs stored in `~/.claude-yolo/logs/` with timestamp format
  - Default mode: logs only wrapper messages (small, readable logs)
  - Verbose mode: logs full Docker session using `script` command
  - Graceful fallback if `script` unavailable
- [x] Add a "verbose" option (`-v` or `--verbose`)
  - Default mode: skip "Press Enter" prompt, no Docker session logging (fast workflow)
  - Verbose mode: show "Press Enter" prompt, log full session (debugging)
- [x] Add a "debug" option (-d or --debug)
  - Debug mode: user must press Enter, persistent container shell after Claude exits
  - Default mode: no "Press Enter" prompt, immediate exit to host after Claude
  - Flags can be combined: --debug --verbose for persistent shell with full logging
- [x] Fix symlink resolution when finding Dockerfile location
  - Script now properly resolves symlinks to find the actual script directory
  - Allows `claude-yo` to be symlinked to PATH directories
- [x] Add per-project customization via `.claude-yo.yml`
  - Support for `apt`, `pip`, `npm`, and `run` sections
  - Support for custom `base` images (e.g., `node:20-bookworm-slim`)
  - Project images cached with hash-based tags
  - Automatic cleanup of old cached images
- [x] Switch default base image from Node.js to Python
  - Default: `python:3.12-slim-bookworm` with Node.js 20 installed
  - Node.js-only projects can use `base: node:20-bookworm-slim`
  - No more UID collision issues (Python image has no pre-existing users)
