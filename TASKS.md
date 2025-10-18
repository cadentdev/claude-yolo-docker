# Tasks

## claude-yolo

- [x] Remove code to import authorization token from ~/.claude on the host machine
- [x] Fix variable escaping in home directory save operation (cp: cannot stat '/home/$CONTAINER_USER/.')
- [x] Add a "rebuild" to force a container rebuild (`-r` or `--rebuild`)
- [x] Fix UID collision with node user (removed node user from Dockerfile)
- [ ] Write script output to a log file by default (tee to console too)
- [ ] Fix bash terminal control warnings (cannot set terminal process group, no job control)
- [ ] Add a "verbose" option to display messages to the console (`-v` or `--verbose`)
- [ ] Add an output message to confirm an existing container is detected

## container

- [x] Prevent UID/GID collision with base image users
- [ ] Enable Claude Code updates on the container (deferred - see APPROACH.md for analysis)
  - Current approach: Manual updates via `--rebuild` flag
  - Future option: Dual installation (system + user-local) if auto-updates prove necessary
