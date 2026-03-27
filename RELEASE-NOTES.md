# Release Notes

## v1.2.0 — Security Hardening (2026-03-27)

Comprehensive security hardening addressing all findings from a 3-layer security review (static analysis, adversarial threat modeling, and structured code review).

### Security

- **Network isolation by default**: All containers now run with `--network=none`. Use the new `--network` flag to opt in to internet access when needed. This prevents exfiltration of credentials or source code via prompt injection attacks.
- **Base image allowlist**: Custom base images in `.claude-yo.yml` are validated against a strict allowlist of official Docker Hub images (python, node, ubuntu, debian, alpine, golang, rust, ruby). Arbitrary third-party images are rejected.
- **`run:` directive filtering**: Commands in the `run:` section are validated against a blocklist of dangerous operations (network tools, package managers, privilege escalation). Use the `apt:`, `pip:`, `npm:` sections for package installation instead.
- **Selective home persistence**: Only `~/.claude/` is persisted across sessions. Shell init files (`.bashrc`, `.profile`, `.ssh/`) are excluded, preventing cross-session backdoor persistence.
- **Credential cleanup**: `.credentials.json` is deleted before the volume save, preventing credential leakage to other containers on the same host.
- **Docker hardening flags**: All containers now run with `--cap-drop=ALL` and `--security-opt=no-new-privileges`.
- **Package name validation**: All apt/pip/npm package names validated against `[a-zA-Z0-9._@/+-]+` regex.
- **TOCTOU protection**: `.claude-yo.yml` is copied to a temp file before validation and use, preventing race condition attacks.
- **Log file permissions**: Log directory created with 0700, log files with 0600 permissions.

### New Features

- `--network` flag for opt-in container network access

### Documentation

- Added security audit workflow example to README
- Updated SECURITY.md with v1.2.0 hardening details
- Updated base image documentation to reflect allowlist

### Quality

- shellcheck: 0 warnings
- All 10 security findings from SECURITY-REVIEW.md addressed (3 critical, 2 high, 3 medium, 2 low)

---

## v1.1.2 (2025-02-17)

- Host credential mounting documentation
- Version bump

## v1.1.0 (2025-02-17)

- Native Claude Code installer
- Host `~/.claude` read-only mount for authentication
- Non-root container user support

## v1.0.0 (2025-10-20)

- Initial release
- Docker container isolation with `--dangerously-skip-permissions`
- Per-project customization via `.claude-yo.yml`
- Debug, verbose, and headless modes
- Session logging and execution time tracking
