# Security Policy

## Reporting a Vulnerability

If you discover a security vulnerability in this project, please report it privately using [GitHub's security advisory feature](https://github.com/cadentdev/claude-yolo-docker/security/advisories/new).

Alternatively, you can email security concerns to the repository maintainers.

Please include:
- Description of the vulnerability
- Steps to reproduce
- Potential impact
- Suggested fix (if any)

We will acknowledge receipt within 48 hours and aim to provide a fix or mitigation plan within 7 days for critical issues.

## Scope

Security issues we're interested in:
- Container escape vulnerabilities
- Privilege escalation within the container
- Vulnerabilities in the wrapper script (e.g., command injection)
- Unsafe handling of user-provided `.claude-yo.yml` configurations

## Known Security Considerations

This project intentionally runs Claude Code with `--dangerously-skip-permissions`, which grants Claude full access to the mounted directory. Users should:

1. **Never mount sensitive directories** — Always `cd` to a specific project directory before running `claude-yo`
2. **Review `.claude-yo.yml` files** — The `run:` directive is validated but executes commands during image build
3. **Understand container isolation** — The container can only read/write the mounted directory. Network access is required for Claude Code's API calls

These are design decisions, not vulnerabilities, but users should understand the trust model before using this tool.

## Security Hardening (v1.2.0, updated v1.2.1)

v1.2.0 addresses findings from a comprehensive 3-layer security review (SECURITY-REVIEW.md). v1.2.1 fixes three blockers discovered during real-world testing.

### Network Access
- Containers have network access (required for Claude Code API calls to `api.anthropic.com`)
- **Limitation:** `--network=none` is not currently possible because Claude Code requires HTTPS connectivity to Anthropic's servers. A future version may implement iptables-based allowlisting to permit only API traffic while blocking all other outbound connections ([#11](https://github.com/cadentdev/claude-yolo-docker/issues/11))

### Base Image Allowlist
- Only official Docker Hub images are accepted as custom base images
- Allowed patterns: `python:*`, `node:*`, `ubuntu:*`, `debian:*`, `alpine:*`, `golang:*`, `rust:*`, `ruby:*`
- Prevents malicious trojan images from being specified in `.claude-yo.yml`

### Run Directive Filtering
- `run:` commands are validated against a blocklist of dangerous operations
- Blocked: network tools (curl, wget, nc), package managers (apt, pip, npm), privilege escalation (sudo, su, chmod, chown)
- Use the `apt:`, `pip:`, `npm:` sections for package installation instead

### Selective Home Persistence
- Only `~/.claude/` is persisted across sessions (not the full home directory)
- Shell init files (`.bashrc`, `.profile`, `.ssh/`) are excluded from persistence
- Credentials (`.credentials.json`) are deleted before volume save

### Docker Hardening
- `--cap-drop=ALL` with minimum cap-adds for container user setup (SETUID, SETGID, CHOWN, DAC_OVERRIDE, FOWNER)
- `--security-opt=no-new-privileges` prevents privilege escalation
- Package names validated against strict regex (`[a-zA-Z0-9._@/+-]+`)
- Config files copied to temp before validation/use (TOCTOU protection)
- Log files created with restricted permissions (0700 dirs, 0600 files)
