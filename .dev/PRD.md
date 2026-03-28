# claude-yo — Product Requirements Document

**Last updated:** 2026-03-27
**Current version:** v1.2.1 (pending merge of PR #12)
**Repo:** https://github.com/cadentdev/claude-yolo-docker

---

## Vision

Run Claude Code with full analytical freedom inside maximum containment. claude-yo wraps Claude Code in a hardened Docker container so it can analyze, audit, and work on code without risking the host system.

**Primary use case:** Sandboxed security auditing of third-party codebases — clone an unfamiliar repo, run `claude-yo`, get a comprehensive audit, container dies.

**Secondary use case:** General-purpose YOLO mode for development — run Claude Code with `--dangerously-skip-permissions` in a container instead of on bare metal.

---

## Architecture

```
Host System
├── claude-yo (bash wrapper script)
├── ~/.claude.json (auth config, mounted read-only)
├── ~/.claude/ (Claude Code state, mounted read-only)
├── $PWD (project dir, mounted read-write at /workspace)
└── Docker
    ├── claude-yolo:latest (base image: Python 3.12 + Node.js 20 + Claude Code)
    ├── claude-yolo-home (persistent volume for ~/.claude/ across sessions)
    └── per-project images (cached, hash-tagged from .claude-yo.yml)
```

**Key design decisions:**
- Git intentionally excluded from container (git belongs on host)
- Auto-updates disabled; use `--rebuild` for controlled updates
- Python 3.12 + Node.js 20 by default; customizable via `.claude-yo.yml`
- Container user matches host UID/GID for file ownership

---

## Current State (v1.2.1)

### What works
- Container isolation with capability dropping (all caps dropped, 5 added back for user setup)
- `--security-opt=no-new-privileges`
- Selective home persistence (~/.claude/ only, no shell init files)
- Credential cleanup before volume save
- Base image allowlist (official Docker Hub images only)
- Run directive filtering (blocks network tools, package managers, privilege escalation)
- TOCTOU protection (config copied to temp before validation)
- Package name validation (regex)
- Log file permission hardening (0700 dirs, 0600 files)
- Five execution modes (default, verbose, debug, debug+verbose, headless)
- Per-project customization via .claude-yo.yml
- Host auth mounting (~/.claude.json + ~/.claude/)

### Known limitations
- **No network isolation** — Claude Code requires HTTPS to api.anthropic.com. Full `--network=none` makes the tool non-functional. (#11)
- **No bats test suite** — All testing is manual
- **No CI runtime tests** — CI has shellcheck + Docker build but no behavioral tests
- **Container starts as root** — Needs root for useradd/su; cap-adds mitigate but don't eliminate

---

## v1.3.0 Roadmap — Selective Network Isolation

**Theme:** Deliver on the network isolation promise from v1.2.0 using iptables-based allowlisting, plus improve test coverage.

### P0: Network allowlisting (the unfinished v1.2.0 promise)

**Problem:** The #1 security value proposition — "the code literally cannot phone home" — is currently false. Containers have full network access because Claude Code needs API connectivity.

**Solution:** Use iptables rules inside the container to allow only:
- `api.anthropic.com` (Claude Code API)
- `claude.ai` (auth/updates)
- DNS resolution (required for the above)

Block all other outbound traffic. This delivers the security promise: audited code cannot exfiltrate data, but Claude Code can still function.

**Implementation approach:**
1. Resolve API hostnames to IP ranges at container startup
2. Apply iptables rules before switching to the container user
3. Optionally allow additional hosts via `--allow-host <domain>` flag
4. `--allow-all-network` flag for full network access when needed (replaces old `--network`)

**Open questions:**
- Do we need `--cap-add=NET_ADMIN` for iptables? (Yes — adds one more capability)
- Should we use nftables instead of iptables for modern systems?
- How to handle IP rotation for api.anthropic.com? (Resolve at startup, accept staleness during session)

### P1: Eliminate root requirement

**Problem:** Container starts as root for `useradd`/`su`, requiring 5 cap-adds that weaken the security posture.

**Solution:** Refactor to use Docker `--user` flag instead of runtime user creation:
1. Build a user into the Docker image at build time (or use `--user` with dynamic UID)
2. Use `docker run --user $(id -u):$(id -g)` to run as host user directly
3. Handle home directory setup via entrypoint script that doesn't need root

**Benefit:** Can truly use `--cap-drop=ALL` with zero cap-adds.

### P2: Test suite

**Problem:** No automated tests. Both v1.2.0 bugs (cap-drop, auth mounting) would have been caught by basic integration tests.

**Solution:**
- Add bats test suite for argument parsing, flag validation, config parsing
- Add integration tests that actually start containers and verify:
  - User creation succeeds
  - Auth files are present
  - Network rules applied correctly (when P0 ships)
  - Exit codes propagate
  - Home persistence works
- Add CI job to run tests on PR

### P3: Quality of life improvements

- **Signal handlers:** Ensure home directory save on Ctrl+C in debug mode
- **`--allow-host <domain>`**: Granular network access for specific use cases
- **Container naming:** Allow multiple simultaneous sessions
- **Startup time improvement:** Layer caching optimization for project images
- **CLAUDE.md support:** Auto-mount a container-specific CLAUDE.md with audit prompts

### Deferred (not v1.3.0)

- **`--no-persist` flag:** Skip home directory save for faster testing
- **Multi-arch support:** ARM64 builds for Apple Silicon Docker Desktop
- **Compose file:** For complex audit setups with multiple containers
- **Result extraction:** Auto-copy generated reports (like SECURITY_AUDIT.md) to host

---

## Issue Tracker

| Issue | Status | Version | Description |
|-------|--------|---------|-------------|
| #9 | Fix in PR #12 | v1.2.1 | --cap-drop=ALL blocks useradd/su |
| #10 | Fix in PR #12 | v1.2.1 | Auth file (.claude.json) not mounted |
| #11 | Partial fix in PR #12 | v1.2.1 (flag removed), v1.3.0 (iptables) | Network isolation blocks API |
| #2 | Closed (not planned) | — | User config files (conflicts with security model) |
| #3 | Closed (not planned) | — | Git status check (git excluded by design) |

---

## Release History

| Version | Date | Theme |
|---------|------|-------|
| v1.0.0 | 2025-10-20 | Initial release |
| v1.1.0 | 2025-02-17 | Native installer, host credential mounting |
| v1.1.2 | 2025-02-17 | Credential docs, version bump |
| v1.2.0 | 2026-03-27 | Security hardening (10 findings addressed) |
| v1.2.1 | 2026-03-27 | Bugfix: 3 blockers from v1.2.0 |
| v1.3.0 | TBD | Selective network isolation, rootless containers, test suite |
