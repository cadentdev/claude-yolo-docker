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
2. **Review `.claude-yo.yml` files** — The `run:` directive executes arbitrary commands during image build
3. **Understand container isolation limits** — The container has network access and can read/write the mounted directory

These are design decisions, not vulnerabilities, but users should understand the trust model before using this tool.
