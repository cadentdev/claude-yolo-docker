# Release Checklist: v1.2.2

**Started:** 2026-03-27 | **Project:** claude-yo

## Current Step: Complete

| Step | Status | Notes |
|------|--------|-------|
| Pre-flight | [x] | 3 commits since v1.2.1 — docs/tests only |
| 1. Security Audit | [x] | No code changes — no new attack surface |
| 2. Triage Findings | [x] | No findings (docs/tests only) |
| 3. Fix Blockers | [x] | N/A — no blockers |
| --- GATE: Security | [x] | Pass — no code changes |
| 4. Test Coverage | [x] | shellcheck 0 warnings (both files), smoke tests 8/8 on Zorin5 |
| --- GATE: Quality | [x] | Pass — shellcheck clean + smoke tests pass |
| 5. Dependency Audit | [x] | Bash project — no package deps, external tools (docker, curl, yq) trusted |
| 6. Documentation Final Pass | [x] | README, PRD, --help all current |
| 7. Version Bump | [x] | 1.2.1 → 1.2.2 |
| 8. Release Notes | [x] | RELEASE-NOTES.md updated |
| 9. PR Creation/Update | [x] | PR #13 |
| 10. Issue Triage | [x] | No open issues |
| 11. Merge & Verify | [x] | PR #13 merged |
| --- GATE: CI | [x] | Pass |
| 12. Tag & GitHub Release | [x] | v1.2.2 tagged, release published |
| 13. Post-Release | [x] | No social media needed for test/docs patch |
| 14. Branch Cleanup | [x] | release/v1.2.2 deleted, Zorin5 updated |
| 15. Retrospective | [x] | See below |

## Findings

No security findings — release contains only documentation and test files.

## Detours

None.

## Retrospective

### What the smoke tests validated
The Quality Gate (Step 4) now has real teeth for bash projects. Instead of just "shellcheck passes" (which passed for v1.2.0 despite three blocker bugs), we now run actual container tests that verify:
- User setup works with the security flags we ship
- Auth files are mounted correctly
- The full headless flow completes end-to-end

### Process improvement: smoke tests as a release gate
**Before v1.2.2:** Step 4 for bash was "shellcheck clean + bats tests pass." No bats tests existed, so it was just shellcheck — pure static analysis that can't catch runtime failures.

**After v1.2.2:** Step 4 for bash is "shellcheck clean + `smoke-test.sh` pass." The smoke tests are a local-only gate (can't run in CI due to auth), but they're fast (~30s) and cover the actual failure modes we hit.

### Recommendation for FullRelease workflow
Update the bash variant of Step 4 to explicitly mention smoke tests:
```
🐚 Bash: shellcheck 0 warnings + smoke tests pass (if tests/smoke-test.sh exists).
Auth-tier tests require local Docker + credentials — run on a machine with both.
```

### What would still be painful
- No CI coverage for container tests (auth requirement blocks this)
- iptables testing (v1.3.0 P0) will need new smoke test tiers
- No way to test `.claude-yo.yml` config parsing without building project-specific images
