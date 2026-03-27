# Release Checklist: v1.2.0

**Started:** 2026-03-27 | **Project:** claude-yo

## Current Step: Step 3 — Fix Blockers

| Step | Status | Notes |
|------|--------|-------|
| Pre-flight | [x] | Branch release/v1.2.0 created, clean tree, bash project |
| 1. Security Audit | [x] | Using existing SECURITY-REVIEW.md (Feb 2026) |
| 2. Triage Findings | [x] | 3 critical → blocker, 2 high → blocker, 3 medium → should-fix, 2 low → should-fix |
| 3. Fix Blockers | [ ] | |
| --- GATE: Security | [ ] | |
| 4. Test Coverage | [ ] | |
| --- GATE: Quality | [ ] | |
| 5. Dependency Audit | [ ] | |
| 6. Documentation Final Pass | [ ] | |
| 7. Version Bump | [ ] | |
| 8. Release Notes | [ ] | |
| 9. PR Creation/Update | [ ] | |
| 10. Issue Triage | [ ] | |
| 11. Merge & Verify | [ ] | |
| --- GATE: CI | [ ] | |
| 12. Tag & GitHub Release | [ ] | |
| 13. Post-Release | [ ] | |
| 14. Branch Cleanup | [ ] | |
| 15. Retrospective | [ ] | |

## Findings

From SECURITY-REVIEW.md — triaged:

**Blockers (must fix):**
- C1: Unrestricted base image injection → ISC-1, 2
- C2: Unrestricted network egress → ISC-3, 4
- C3: run: directive bypass → ISC-5, 6
- H1: Persistent volume backdoor → ISC-7, 8
- H2: Credential persistence → ISC-9

**Should-fix:**
- M1: Package name injection → ISC-13
- M2: Log file permissions → ISC-10, 11
- M3: TOCTOU race condition → ISC-12
- L1: Missing Docker hardening flags → ISC-14, 15
- L2: Root home exposure → addressed by Dockerfile changes

## Detours

<!-- Log unplanned work -->
