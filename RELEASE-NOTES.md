# Release Notes

## v1.2.2 — Smoke Tests & Process Validation (2026-03-27)

Adds a local smoke test suite that would have caught all three v1.2.0 blocker bugs before release. This is the process improvement from the v1.2.0/v1.2.1 retrospective.

### Testing

- **Smoke test suite** (`tests/smoke-test.sh`): 8 tests across 3 tiers (offline, container, auth). Pure bash, no external framework. Run with `./tests/smoke-test.sh` or `./tests/smoke-test.sh --no-auth` for CI.
- Tests verify: flag parsing, container user setup, auth file mounting, security flags, and headless prompt completion.
- All tests pass on Zorin5 with Docker 28.2.2.

### Documentation

- Added Testing section to README with usage instructions
- Added project PRD (`.dev/PRD.md`) with v1.3.0 roadmap
- Updated PRD with smoke test status in P2 (Test Suite)

### Quality

- shellcheck: 0 warnings on both `claude-yo` and `tests/smoke-test.sh`
- Smoke tests: 8/8 pass (including auth tier)

---

## v1.2.1 — Security Bugfixes (2026-03-27)

Fixes three blocker bugs in v1.2.0 discovered during real-world testing (security audit of tw93/Mole).

### Bug Fixes

- **`--cap-drop=ALL` blocked container user setup** (#9): The container entrypoint needs `useradd` and `su` to create a matching host user, which require specific Linux capabilities. Fixed by adding back minimum required capabilities: SETUID, SETGID, CHOWN, DAC_OVERRIDE, FOWNER. All other capabilities remain dropped.
- **Authentication file not mounted** (#10): Claude Code stores auth config at `~/.claude.json` (home root), not inside `~/.claude/` (directory). v1.2.0 only mounted the directory. Fixed by also mounting `~/.claude.json` read-only into the container.
- **Network isolation blocked API access** (#11): Claude Code requires HTTPS access to `api.anthropic.com`. `--network=none` made the tool non-functional. Both `--network` and `--no-network` flags removed — containers now always have network access. Future versions may implement selective allowlisting (iptables) to permit only API traffic.

### Breaking Changes

- `--network` flag removed (containers always have network access)
- Network isolation (`--network=none`) is not currently possible — Claude Code requires API connectivity

### Security Notes

The security model remains strong despite these changes:
- All Linux capabilities still dropped except the 5 required for user setup
- `--security-opt=no-new-privileges` still enforced
- Selective home persistence still excludes shell init files
- Credentials still cleaned before volume save
- Base image allowlist and run directive filtering unchanged
- Network isolation planned for v1.3.0 via iptables allowlisting (#11)

---

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
