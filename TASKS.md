# Tasks

## claude-yolo

- [x] Add `--headless` flag for non-interactive execution (cron/automation)
  - See PLAN.md "Plan: Add Headless Mode (`--headless`)" for implementation details
  - Implemented: `--headless` runs Docker without TTY, validates mutual exclusion with `--debug`

- [x] Add execution time tracking
  - Record start time at script launch
  - Calculate and display elapsed time when script exits (e.g., "Completed in 2m 34s")
  - Write execution time to log file
  - Implemented: Uses EXIT trap to log "Completed in Xm Xs" to console and log file

- [x] Refactor to reduce code duplication
  - See PLAN.md "Refactoring Recommendations" section 1: "Extract Common Container Setup Script"
  - Implemented: Extracted CONTAINER_USER_SETUP, CONTAINER_BANNER, CONTAINER_SAVE_HOME, CONTAINER_DEBUG_SHELL
  - Reduced from 661 lines to 545 lines (17% reduction while adding new features)
