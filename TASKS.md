# Tasks

## claude-yolo

- [ ] Add `--headless` flag for non-interactive execution (cron/automation)
  - See PLAN.md "Plan: Add Headless Mode (`--headless`)" for implementation details
  - See PLAN.md "Refactoring Recommendations" for suggested improvements

- [ ] Add execution time tracking
  - Record start time at script launch
  - Calculate and display elapsed time when script exits (e.g., "Completed in 2m 34s")
  - Write execution time to log file

- [ ] Refactor to reduce code duplication
  - See PLAN.md "Refactoring Recommendations" section 1: "Extract Common Container Setup Script"
  - Currently 5+ near-identical docker run blocks
