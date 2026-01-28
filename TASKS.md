# Tasks

## claude-yolo

- [ ] Fix bash terminal control warnings (cannot set terminal process group, no job control)
- [ ] Add an output message to confirm an existing container is detected
- [x] Pass command line parameters to Claude Code (e.g., `claude-yo -p "Review the docs"`)

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

## GitHub Repository Protection (for public release)

### Branch protection (Settings → Branches → main)

- [ ] Require pull request reviews (1+ approver)
- [ ] Require status checks to pass (when CI is added)
- [ ] Require signed commits (optional)
- [ ] Do not allow force pushes
- [ ] Do not allow deletions

### Repository security (Settings → Security)

- [ ] Enable Dependabot alerts
- [ ] Enable secret scanning
- [x] Add SECURITY.md

### Pre-release checks

- [ ] Verify no secrets in git history
- [x] Add LICENSE file
