# Tasks

## claude-yolo

- [x] Pass command line parameters to Claude Code (e.g., `claude-yo -p "Review the docs"`)

## container

- [x] Prevent UID/GID collision with base image users (solved by switching to Python base)
- [x] Add per-project customization via `.claude-yo.yml`
- [x] Support custom base images for projects

## Documentation

- [x] Document git exclusion policy (git belongs on host, not in container)
- [x] Document default Docker image (Python 3.12 + Node.js 20)
- [x] Document per-project customization options
- [x] Add link to Docker Hub official images for custom base selection

## GitHub Repository Protection (for public release)

### Branch protection (Settings → Branches → main)

- [x] Require pull request reviews (1+ approver)
- [x] Require status checks to pass (lint, build)
- [x] Do not allow force pushes
- [x] Do not allow deletions

### Repository security (Settings → Security)

- [x] Enable Dependabot alerts
- [x] Enable secret scanning
- [x] Add SECURITY.md

### Pre-release checks

- [x] Verify no secrets in git history
- [x] Add LICENSE file
