# Contributing to Claude YOLO Docker

Thanks for your interest in contributing!

## Reporting Bugs

Open an issue using the **Bug Report** template. Include:
- What you expected to happen
- What actually happened
- Steps to reproduce
- Your environment (OS, Docker version)

## Suggesting Features

Open an issue using the **Feature Request** template. Describe the use case and why it would be valuable.

## Submitting Pull Requests

1. Fork the repository
2. Create a feature branch (`git checkout -b my-feature`)
3. Make your changes
4. Ensure CI passes (ShellCheck + Docker build)
5. Submit a PR against `main`

### Code Style

- Shell scripts are checked with [ShellCheck](https://www.shellcheck.net/)
- Use descriptive variable names
- Add comments for non-obvious logic
- Keep changes focused — one feature or fix per PR

### Commit Messages

We use [Conventional Commits](https://www.conventionalcommits.org/):

- `feat:` — new feature
- `fix:` — bug fix
- `docs:` — documentation only
- `chore:` — maintenance tasks
- `ci:` — CI/CD changes

### What Makes a Good PR

- Solves one problem
- Includes context on *why* the change is needed
- Passes CI checks
- Follows existing code patterns

## Development Setup

```bash
# Clone your fork
git clone https://github.com/YOUR_USERNAME/claude-yolo-docker.git
cd claude-yolo-docker

# Build the Docker image
docker build -t claude-yolo:latest .

# Run the wrapper
./claude-yo
```

## Questions?

Open an issue — we're happy to help.
