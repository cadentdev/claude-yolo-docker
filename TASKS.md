# Tasks

## claude-yolo

- [ ] Fix bash terminal control warnings (cannot set terminal process group, no job control)
- [ ] Add an output message to confirm an existing container is detected

## container

- [x] Prevent UID/GID collision with base image users (solved by switching to Python base)
- [x] Add per-project customization via `.claude-yo.yml`
- [x] Support custom base images for projects
- [ ] Enable Claude Code auto-updates (deferred - see APPROACH.md for analysis)
  - Current approach: Manual updates via `--rebuild` flag
  - Future option: Dual installation (system + user-local) if auto-updates prove necessary

## Documentation

- [x] Document git exclusion policy (git belongs on host, not in container)
- [x] Document default Docker image (Python 3.12 + Node.js 20)
- [x] Document per-project customization options
- [x] Add link to Docker Hub official images for custom base selection
