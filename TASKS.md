# Tasks

## claude-yolo

- [ ] Fix bash terminal control warnings (cannot set terminal process group, no job control)
- [ ] Add an output message to confirm an existing container is detected
- [ ] Add the ability to check git status with `git status && git pull --rebase && git push` as an option (-g)
- [ ] Display the git status in the info header before running claude code.
- [ ] Give users the chance to cancel loading claude code if the working tree is not clean.

## container

- [x] Prevent UID/GID collision with base image users
- [ ] Enable Claude Code updates on the container (deferred - see APPROACH.md for analysis)
  - Current approach: Manual updates via `--rebuild` flag
  - Future option: Dual installation (system + user-local) if auto-updates prove necessary
