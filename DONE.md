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
