# Plan: Write Script Output to Log File

## Task Overview
Implement logging for the `claude-yo` wrapper script to capture wrapper script output to a log file while also displaying it in the console. Full Docker session capture is available via the `--verbose` flag.

## Current Behavior
- All script output goes directly to stdout/stderr
- No persistent record of sessions
- Debugging requires manually re-running and capturing output

## Desired Behavior (REVISED after user testing)

### Default Mode (no flags)
- Log **only wrapper script messages** to timestamped log file
- Skip "Press Enter" prompt for faster workflow
- **Do not** capture Docker session (Claude Code output)
- Small, readable log files focused on script operations

### Verbose Mode (`--verbose` flag)
- Log wrapper script messages **and** full Docker session
- Include "Press Enter" prompt to give user time to review setup
- Capture everything including Claude Code output and debug shell
- Large log files useful for debugging

**Rationale for change:**
- Default Docker session logs are massive (thousands of lines with ANSI codes)
- Terminal control sequences make logs hard to read
- User already sees Claude output in their terminal
- Script messages (build status, errors) are what need persistence
- Power users can opt into full capture when debugging

## Design Decisions

### Log File Location
**Option 1: Store in repository directory** (`./logs/`)
- ✅ Easy to find alongside the script
- ✅ Gitignore can exclude them
- ❌ Pollutes project directory
- ❌ Logs mix with code

**Option 2: Store in user's home directory** (`~/.claude-yolo/logs/`)
- ✅ Cleaner separation of concerns
- ✅ Centralized location for all projects
- ✅ Follows Unix conventions
- ❌ Slightly harder to discover

**Recommendation: Option 2** - Store in `~/.claude-yolo/logs/`

### Log File Naming
Format: `claude-yolo-YYYY-MM-DD-HHMMSS.log`

Example: `claude-yolo-2025-10-17-143522.log`

**Rationale:**
- ISO 8601-ish date format sorts chronologically
- Includes time to allow multiple runs per day
- Descriptive prefix identifies the tool
- No special characters that cause shell escaping issues

### What to Log

**Default mode:**
1. Build output (if triggered) - both stdout and stderr
2. Container setup messages (UID, working directory, etc.)
3. Error messages from script or Docker
4. **NOT** Claude Code session output
5. **NOT** Debug shell session

**Verbose mode (`--verbose`):**
1. Everything from default mode
2. Full Docker session output (includes Claude Code)
3. Debug shell session (if user uses it)
4. All terminal control codes and ANSI sequences

**Scope boundaries:**
- Start logging immediately when script starts
- Each invocation creates a new log file
- In default mode, logging stops before Docker session starts
- In verbose mode, logging continues until container exits

### Integration with `-v`/`--verbose` Flag

| Scenario | Console Output | Log File | "Press Enter" Prompt |
|----------|----------------|----------|---------------------|
| Default (no flags) | All wrapper messages + Claude output | Wrapper messages only | Skipped (faster) |
| `--verbose` | All wrapper messages + Claude output | Everything including Docker session | Shown (time to review) |

This means:
- Logging always happens (wrapper messages at minimum)
- Verbose flag controls **both** log capture depth and workflow speed
- Default mode optimizes for speed and readable logs
- Verbose mode optimizes for debugging and full traceability

## Implementation Approach

### High-Level Steps

1. **Create log directory on first run**
   - Check if `~/.claude-yolo/logs/` exists
   - Create it if missing (with appropriate permissions)

2. **Generate timestamped log filename**
   - Use `date` command: `date +%Y-%m-%d-%H%M%S`
   - Construct full path: `~/.claude-yolo/logs/claude-yolo-$TIMESTAMP.log`

3. **Redirect all output through `tee`**
   - Wrapper script output: Direct `tee` usage
   - Docker container output: Harder - need to handle `docker run` output

4. **Handle the complexity of Docker output**
   - `docker run` with `-it` (interactive + TTY) makes output redirection tricky
   - Need to preserve interactivity while logging

### Technical Challenges

#### Challenge 1: Logging Docker Interactive Sessions
The script uses `docker run -it` which allocates a pseudo-TTY. This is needed for:
- The `read` prompt (line 93)
- Claude Code's interactive interface
- The debug shell (line 104)

**Problem:** `tee` doesn't work cleanly with TTY allocation - you can't just pipe `docker run -it` through `tee`.

**Potential Solutions:**

**A) Use `script` command (Unix session recorder)**
```bash
script -q -c "docker run -it ..." "$LOGFILE"
```
- ✅ Designed for this exact use case
- ✅ Preserves TTY behavior
- ✅ Captures all output including control sequences
- ❌ Includes terminal control codes (may make logs messy)
- ❌ Not available on all systems (rare on Linux, might be issue elsewhere)

**B) Split logging: wrapper separate from Docker**
```bash
# Log wrapper messages
echo "Starting..." | tee -a "$LOGFILE"

# Run Docker without logging (interactive session)
docker run -it ...

# Log completion
echo "Finished" | tee -a "$LOGFILE"
```
- ✅ Simple and reliable
- ✅ No TTY conflicts
- ❌ Doesn't capture Claude Code output
- ❌ Defeats the purpose of logging

**C) Use `docker logs` after the fact**
```bash
# Run with container name
docker run --name claude-session-$TIMESTAMP -it ...

# After exit, extract logs
docker logs claude-session-$TIMESTAMP > "$LOGFILE" 2>&1
```
- ✅ Clean separation
- ❌ Requires `--rm` removal (conflicts with current design)
- ❌ Doesn't capture interactive prompts properly
- ❌ Adds complexity

**Recommendation: Solution A (`script` command)** with a fallback message if `script` is unavailable.

#### Challenge 2: Log File Path Communication
Since the log is created on the host but we're immediately entering a Docker container, we need to inform the user where the log is being written.

**Solution:** Print log location before entering Docker:
```bash
echo "Logging session to: $LOGFILE"
```

#### Challenge 3: Handling Partial Logs on Error
If the script fails early (e.g., Docker build fails), we should still have a log.

**Solution:** Create log file and start logging before any Docker operations.

### Detailed Implementation Plan

```bash
# 1. Early in script (after argument parsing, before any operations)
LOG_DIR="$HOME/.claude-yolo/logs"
mkdir -p "$LOG_DIR"
TIMESTAMP=$(date +%Y-%m-%d-%H%M%S)
LOGFILE="$LOG_DIR/claude-yolo-$TIMESTAMP.log"

# 2. Notify user
echo "Session log: $LOGFILE"

# 3. Wrap the main execution in script command
script -q -f -c '
  # ... rest of the script (build, docker run, etc)
  # Everything goes here
' "$LOGFILE"
```

**Alternative if we want more control:**
```bash
# Use process substitution to tee everything
exec > >(tee -a "$LOGFILE")
exec 2>&1

# Then rest of script runs normally
```

**Issue with above:** Doesn't work well with `docker run -it` because TTY conflicts.

### Recommended Implementation (REVISED)

**Default mode implementation:**
1. Parse `--verbose` flag during argument processing
2. Log wrapper script messages using `tee`
3. Show container setup info without "Press Enter" prompt
4. Run Docker session **without** `script` wrapper (no logging)
5. Simple, fast, clean logs

**Verbose mode implementation:**
1. Log wrapper script messages using `tee`
2. Show container setup info **with** "Press Enter" prompt
3. Wrap `docker run` with `script` command to capture full session
4. Fall back gracefully if `script` unavailable

```bash
# Early setup
VERBOSE=false  # Set from argument parsing
LOG_DIR="$HOME/.claude-yolo/logs"
mkdir -p "$LOG_DIR"
TIMESTAMP=$(date +%Y-%m-%d-%H%M%S)
LOGFILE="$LOG_DIR/claude-yolo-$TIMESTAMP.log"

# Log function for wrapper messages
log_message() {
  echo "$@" | tee -a "$LOGFILE"
}

# Use log_message for all wrapper echo statements
log_message "Session log: $LOGFILE"
log_message "Building Docker image..."

# Docker run command varies by mode
if [ "$VERBOSE" = true ]; then
  # Verbose mode: capture full session with script command
  if command -v script &> /dev/null; then
    script -q -f -c "docker run ... (with read prompt)" "$LOGFILE"
  else
    log_message "Warning: 'script' command not found. Docker session will not be logged."
    docker run ... (with read prompt)
  fi
else
  # Default mode: no session capture, no prompt, just run
  docker run ... (without read prompt)
fi
```

## Edge Cases to Consider

1. **Log directory permissions**: What if `~/.claude-yolo` isn't writable?
   - Check and fail gracefully with error message

2. **Disk space**: Log files could accumulate
   - Document that users should periodically clean logs
   - Consider: Add `--clean-logs` flag in future? (out of scope for this task)

3. **Special characters in output**: Claude might output Unicode, ANSI codes, etc.
   - `script` handles this natively
   - No special handling needed

4. **Multiple simultaneous runs**: Timestamp includes seconds, so collision unlikely
   - If needed, add PID to filename: `claude-yolo-$TIMESTAMP-$$.log`

5. **Interrupted sessions**: Ctrl+C or kill signal
   - Log will be incomplete but still useful
   - No special handling needed - this is acceptable

## Testing Plan

After implementation, test:

**Default mode (no flags):**
1. **Normal run**: Verify log contains wrapper messages but NOT Claude session
2. **No Enter prompt**: Verify container starts immediately without pause
3. **Build run**: Verify Docker build output is logged
4. **Rebuild run**: Verify rebuild output is logged
5. **Error scenario**: Trigger build failure, verify error is logged
6. **Log size**: Verify log file is small (< 100 lines for typical run)

**Verbose mode (`--verbose`):**
1. **Full capture**: Verify log contains wrapper messages AND Claude session
2. **Enter prompt present**: Verify "Press Enter" prompt appears
3. **Debug shell logged**: Verify debug shell commands are in log
4. **Large log**: Verify log captures full session (thousands of lines OK)
5. **Fallback**: Test on system without `script` command

## Future Enhancements (Out of Scope)

- Automatic log rotation/cleanup after N days
- `--no-log` flag to disable logging
- `--log-dir` flag to specify custom log location
- Compress old logs automatically
- Log viewer/search utility

## Summary

**REVISED Implementation:**

1. Add `--verbose` flag to argument parsing
2. Create `~/.claude-yolo/logs/` directory
3. Generate timestamped log filename
4. Log wrapper messages using `tee` in all modes
5. Inform user of log location at start

**Default mode (fast & clean):**
- Skip "Press Enter" prompt in Docker container setup
- Run Docker session without `script` wrapper
- Log contains only wrapper messages (small files)

**Verbose mode (debugging):**
- Keep "Press Enter" prompt in Docker container setup
- Wrap Docker session with `script` command for full capture
- Log contains everything including Claude output (large files)
- Fallback gracefully if `script` unavailable

This approach balances UX (fast default) with debugging capability (verbose option).
