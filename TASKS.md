# Tasks

## claude-yolo

- [x] Remove code to import authorization token from ~/.claude on the host machine
- [x] Fix variable escaping in home directory save operation (cp: cannot stat '/home/$CONTAINER_USER/.')
- [ ] Fix bash terminal control warnings (cannot set terminal process group, no job control)
- [ ] Write script output to a log file by default.
- [ ] Add a "verbose" option to display messages to the console (`-v` or `--verbose`)
- [ ] Add a "rebuild" to force a container rebuild (`-r` or `--rebuild`)
- [ ] Add an output message to confirm an existing container is detected

## container

- [ ] Enable Claude Code updates on the container (currently fails - requires sudo permissions)
- [ ] Consider installing Claude Code without sudo to enable auto-updates