# Plan: Add Debug Mode (`-d` or `--debug`)

> **Status: IMPLEMENTED** - This plan has been fully implemented. See `claude-yo` for the current implementation.

## Task Overview
Implement a debug mode that gives users more control over the container lifecycle and allows shell access after Claude Code exits. Debug mode is orthogonal to logging - users can combine flags for different workflows.

## Current Behavior

### Default Mode (no flags)
- Container setup displays immediately
- Claude Code starts automatically (no "Press Enter" prompt)
- After Claude exits, user drops to debug shell
- **Issue**: Exiting the debug shell returns to host shell (container removed)

### Verbose Mode (`--verbose`)
- Shows "Press Enter" prompt before starting Claude
- Captures full session with `script` command
- After Claude exits, user drops to debug shell
- **Same issue**: Exiting the debug shell returns to host shell

## Desired Behavior

### Orthogonal Concerns: Debug vs Logging

**Key insight**: Debug mode and logging are independent features that can be combined:

- **Debug mode (`--debug`)**: Controls container lifecycle (persistent shell vs immediate exit)
- **Logging (`--verbose`)**: Controls session capture (wrapper only vs full session)

Users should be able to combine these flags:
- `./claude-yo` - Fast workflow, no debug shell
- `./claude-yo --debug` - Persistent shell, no session logging
- `./claude-yo --verbose` - Session logging, no debug shell
- `./claude-yo --debug --verbose` - Persistent shell AND full session logging

### Feature Matrix

| Flag Combination | Enter Prompt | Session Logging | Debug Shell | Use Case |
|-----------------|--------------|-----------------|-------------|----------|
| (none) | ❌ No | Wrapper only | ❌ No | Fast production workflow |
| `--verbose` | ✅ Yes | Full session | ❌ No | Capture logs for review |
| `--debug` | ✅ Yes | Wrapper only | ✅ Yes | Interactive exploration |
| `--debug --verbose` | ✅ Yes | Full session | ✅ Yes | Debug with full audit trail |

### Debug Mode Behavior

When `--debug` is enabled (with or without `--verbose`):

1. **Manual entry**: Show "Press Enter" prompt
   - Gives user time to review container setup
   - User explicitly chooses when to start Claude

2. **Shell persistence**: After Claude exits, stay in container shell
   - User can inspect state, test commands, debug issues
   - Container persists until user explicitly types `exit`
   - Home directory saved when user exits shell

3. **Logging behavior**: Respects `--verbose` flag
   - Without `--verbose`: Wrapper messages only (console + log file)
   - With `--verbose`: Full session capture using `script` command

4. **Clear messaging**: User understands they're in control
   - Clear prompts explaining what happens next
   - Explicit instructions on how to exit

## Implementation Analysis

### Current Container Flow

Looking at `claude-yo:260-269` (default mode):
```bash
su - \$CONTAINER_USER -c '
  cd /workspace
  claude --dangerously-skip-permissions
  echo ""
  echo "═══════════════════════════════════════════════════════════════"
  echo "Claude exited. You are still in the container for debugging."
  echo "Type exit to leave the container."
  echo "═══════════════════════════════════════════════════════════════"
  exec bash -i
'
```

**Current behavior**:
- `su` creates a subshell as `$CONTAINER_USER`
- Claude runs in that subshell
- When Claude exits, `exec bash -i` replaces the shell process
- When user types `exit`, the `su` command completes
- The outer Docker container bash script continues to line 271-273 (saves home dir)
- Container exits because of `--rm` flag

**Problem**: There's no persistent shell. The bash session is inside the `su -c '...'` command string.

### Design Decision: How to Implement Persistent Shell?

**Option A: Remove `su -c` wrapper, use `su -l` instead**
```bash
# Run Claude
su - \$CONTAINER_USER -c 'cd /workspace && claude --dangerously-skip-permissions'

# Then drop to persistent shell
echo "Claude exited. Starting debug shell..."
exec su -l \$CONTAINER_USER
```

**Analysis**:
- ✅ Simple and clean
- ✅ Shell persists after Claude exits
- ❌ **Problem**: `exec` replaces the bash process, so home directory save (lines 271-273) never runs
- ❌ Authentication tokens won't persist!

**Option B: Use bash to wait for user exit (RECOMMENDED)**
```bash
# Run Claude
su - \$CONTAINER_USER -c 'cd /workspace && claude --dangerously-skip-permissions'

# Drop to debug shell that can be exited
su -l \$CONTAINER_USER

# This line runs after user exits shell
# Save home directory to persistent volume
mkdir -p /home-persist/\$CONTAINER_USER
cp -a /home/\$CONTAINER_USER/. /home-persist/\$CONTAINER_USER/
```

**Analysis**:
- ✅ Shell persists after Claude
- ✅ Home directory save runs after user exits
- ✅ Clean separation of concerns
- ✅ Works with existing container flow
- ✅ Compatible with `script` wrapper for logging

**Recommendation: Option B** - Sequential `su` calls with home directory save at the end.

### Logging Integration

The `script` command wrapper (used for `--verbose`) can wrap the entire container flow:

**Without debug shell** (current verbose mode, to be modified):
```bash
script -q -f -c "docker run ... (Claude runs, then exits)" "$LOGFILE"
```

**With debug shell** (`--debug --verbose`):
```bash
script -q -f -c "docker run ... (Claude runs, then persistent shell)" "$LOGFILE"
```

The debug shell behavior is controlled by the Docker container's bash script, not the `script` wrapper. The `script` wrapper just captures everything.

## Implementation Plan

### 1. Add `--debug` flag parsing

Location: `claude-yo:3-54` (argument parsing section)

Add:
```bash
DEBUG=false
VERBOSE=false
for arg in "$@"; do
  case $arg in
    # ... existing cases ...
    -d|--debug)
      DEBUG=true
      shift
      ;;
```

### 2. Update help text

Location: `claude-yo:8-38`

Add debug option documentation:
```bash
echo "  -d, --debug      Enable debug mode with persistent container shell"
```

Update the modes documentation to show flag combinations:
```bash
echo "Modes:"
echo "  Default (no flags):"
echo "    - Fast startup with no 'Press Enter' prompt"
echo "    - Claude exits → returns to host immediately"
echo "    - Logs wrapper messages only"
echo ""
echo "  Verbose mode (--verbose):"
echo "    - Shows 'Press Enter' prompt to review setup"
echo "    - Logs full session including Claude Code output"
echo "    - Claude exits → returns to host immediately"
echo ""
echo "  Debug mode (--debug):"
echo "    - Shows 'Press Enter' prompt to review setup"
echo "    - Claude exits → drops to persistent container shell"
echo "    - Type 'exit' to save and leave container"
echo "    - Logs wrapper messages only"
echo ""
echo "  Debug + Verbose (--debug --verbose):"
echo "    - Combines debug mode with full session logging"
echo "    - Useful for debugging with complete audit trail"
```

### 3. Restructure container execution logic

Current structure:
```bash
if [ "$VERBOSE" = true ]; then
  # Verbose mode with script wrapper
elif
  # Default mode
fi
```

New structure (matrix of debug × logging):
```bash
if [ "$DEBUG" = true ]; then
  if [ "$VERBOSE" = true ]; then
    # Debug mode WITH logging
  else
    # Debug mode WITHOUT logging
  fi
else
  if [ "$VERBOSE" = true ]; then
    # No debug WITH logging (current verbose mode, modified)
  else
    # No debug WITHOUT logging (current default mode, modified)
  fi
fi
```

### 4. Implement four modes

#### Mode 1: Default (no debug, no verbose)
```bash
else
  # Default mode: fast start, immediate exit, wrapper logging only
  docker run \
    -v "$MOUNTDIR":/workspace \
    -v claude-yolo-home:/home-persist \
    -it \
    --rm \
    claude-yolo:latest \
    /bin/bash -c "
      # User setup...
      # Restore home directory...

      # Display setup (no prompt)
      echo \"Starting Claude Code with --dangerously-skip-permissions...\"

      # Run Claude and EXIT (no debug shell)
      su - \$CONTAINER_USER -c 'cd /workspace && claude --dangerously-skip-permissions'

      # Save home directory
      mkdir -p /home-persist/\$CONTAINER_USER
      cp -a /home/\$CONTAINER_USER/. /home-persist/\$CONTAINER_USER/
    "
fi
```

#### Mode 2: Verbose only (no debug, with logging)
```bash
if [ "$VERBOSE" = true ]; then
  log_message "Verbose mode enabled - full session will be logged"

  if command -v script &> /dev/null; then
    script -q -f -c "docker run \
      -v \"$MOUNTDIR\":/workspace \
      -v claude-yolo-home:/home-persist \
      -it \
      --rm \
      claude-yolo:latest \
      /bin/bash -c \"
        # User setup...
        # Restore home directory...

        # Display setup WITH prompt
        echo \\\"Press Enter to start Claude Code with --dangerously-skip-permissions\\\"
        read

        # Run Claude and EXIT (no debug shell)
        su - \\\$CONTAINER_USER -c 'cd /workspace && claude --dangerously-skip-permissions'

        # Save home directory
        mkdir -p /home-persist/\\\$CONTAINER_USER
        cp -a /home/\\\$CONTAINER_USER/. /home-persist/\\\$CONTAINER_USER/
      \"" "$LOGFILE"
  else
    # Fallback without script command (same logic, no logging wrapper)
  fi
```

#### Mode 3: Debug only (with debug, no logging)
```bash
else
  # Debug mode WITHOUT logging
  log_message "Debug mode enabled - container will persist after Claude exits"

  docker run \
    -v "$MOUNTDIR":/workspace \
    -v claude-yolo-home:/home-persist \
    -it \
    --rm \
    claude-yolo:latest \
    /bin/bash -c "
      # User setup...
      # Restore home directory...

      # Display setup WITH prompt
      echo \"Press Enter to start Claude Code with --dangerously-skip-permissions\"
      read

      # Run Claude
      su - \$CONTAINER_USER -c 'cd /workspace && claude --dangerously-skip-permissions'

      # Drop to PERSISTENT debug shell
      echo \"\"
      echo \"═══════════════════════════════════════════════════════════════\"
      echo \"Claude exited. Starting debug shell...\"
      echo \"═══════════════════════════════════════════════════════════════\"
      echo \"You are now in the container as \$CONTAINER_USER\"
      echo \"Working directory: /workspace\"
      echo \"\"
      echo \"Type 'exit' to save your home directory and leave the container.\"
      echo \"═══════════════════════════════════════════════════════════════\"
      echo \"\"

      su -l \$CONTAINER_USER

      # Save home directory AFTER user exits
      echo \"Saving authentication data...\"
      mkdir -p /home-persist/\$CONTAINER_USER
      cp -a /home/\$CONTAINER_USER/. /home-persist/\$CONTAINER_USER/
      echo \"Done. Exiting container.\"
    "
fi
```

#### Mode 4: Debug + Verbose (with debug, with logging)
```bash
if [ "$VERBOSE" = true ]; then
  log_message "Debug + Verbose mode enabled - full session logged, container persists"

  if command -v script &> /dev/null; then
    script -q -f -c "docker run \
      -v \"$MOUNTDIR\":/workspace \
      -v claude-yolo-home:/home-persist \
      -it \
      --rm \
      claude-yolo:latest \
      /bin/bash -c \"
        # User setup...
        # Restore home directory...

        # Display setup WITH prompt
        echo \\\"Press Enter to start Claude Code with --dangerously-skip-permissions\\\"
        read

        # Run Claude
        su - \\\$CONTAINER_USER -c 'cd /workspace && claude --dangerously-skip-permissions'

        # Drop to PERSISTENT debug shell
        echo \\\"\\\"
        echo \\\"═══════════════════════════════════════════════════════════════\\\"
        echo \\\"Claude exited. Starting debug shell...\\\"
        echo \\\"═══════════════════════════════════════════════════════════════\\\"
        echo \\\"You are now in the container as \\\$CONTAINER_USER\\\"
        echo \\\"Working directory: /workspace\\\"
        echo \\\"\\\"
        echo \\\"Type 'exit' to save your home directory and leave the container.\\\"
        echo \\\"═══════════════════════════════════════════════════════════════\\\"
        echo \\\"\\\"

        su -l \\\$CONTAINER_USER

        # Save home directory AFTER user exits
        echo \\\"Saving authentication data...\\\"
        mkdir -p /home-persist/\\\$CONTAINER_USER
        cp -a /home/\\\$CONTAINER_USER/. /home-persist/\\\$CONTAINER_USER/
        echo \\\"Done. Exiting container.\\\"
      \"" "$LOGFILE"
  else
    # Fallback without script command (same logic as mode 3)
  fi
fi
```

### 5. Code organization strategy

To avoid massive code duplication, we can use a helper approach:

```bash
# Define common container script as a function
build_container_script() {
  local WITH_PROMPT=$1
  local WITH_DEBUG_SHELL=$2

  cat <<'CONTAINER_SCRIPT'
    # User setup (always the same)
    EXISTING_USER=$(getent passwd USERID_PLACEHOLDER | cut -d: -f1)
    if [ -n "$EXISTING_USER" ]; then
      CONTAINER_USER=$EXISTING_USER
    else
      CONTAINER_USER=USERNAME_PLACEHOLDER
      groupadd -g GROUPID_PLACEHOLDER $CONTAINER_USER 2>/dev/null || true
      useradd -u USERID_PLACEHOLDER -g GROUPID_PLACEHOLDER -m -s /bin/bash $CONTAINER_USER
    fi

    # Restore home directory (always the same)
    if [ -d /home-persist/$CONTAINER_USER ]; then
      cp -a /home-persist/$CONTAINER_USER/. /home/$CONTAINER_USER/
    fi

    # Setup display (varies by WITH_PROMPT)
CONTAINER_SCRIPT

  if [ "$WITH_PROMPT" = true ]; then
    cat <<'PROMPT_SCRIPT'
    echo "Press Enter to start Claude Code with --dangerously-skip-permissions"
    read
PROMPT_SCRIPT
  else
    cat <<'NO_PROMPT_SCRIPT'
    echo "Starting Claude Code with --dangerously-skip-permissions..."
NO_PROMPT_SCRIPT
  fi

  cat <<'RUN_CLAUDE'
    # Run Claude
    su - $CONTAINER_USER -c 'cd /workspace && claude --dangerously-skip-permissions'
RUN_CLAUDE

  if [ "$WITH_DEBUG_SHELL" = true ]; then
    cat <<'DEBUG_SHELL'
    # Debug shell
    echo ""
    echo "═══════════════════════════════════════════════════════════════"
    echo "Claude exited. Starting debug shell..."
    echo "═══════════════════════════════════════════════════════════════"
    echo "You are now in the container as $CONTAINER_USER"
    echo "Working directory: /workspace"
    echo ""
    echo "Type 'exit' to save your home directory and leave the container."
    echo "═══════════════════════════════════════════════════════════════"
    echo ""

    su -l $CONTAINER_USER
DEBUG_SHELL
  fi

  cat <<'SAVE_HOME'
    # Save home directory
    mkdir -p /home-persist/$CONTAINER_USER
    cp -a /home/$CONTAINER_USER/. /home-persist/$CONTAINER_USER/
SAVE_HOME
}
```

**Actually, this function approach is too complex with escaping.** Better to keep the four explicit cases but use a shared user setup snippet.

**Revised approach**: Accept some duplication, keep four clear cases. The user setup and home directory save/restore are identical, so those can be referenced in comments to a canonical version.

### 6. Remove existing flag conflict check

The plan previously suggested treating `--verbose` and `--debug` as mutually exclusive. **Remove this** - they should work together.

## Edge Cases and Considerations

### 1. Flag Combinations
**Scenario**: User runs `./claude-yo --verbose --debug`

**Expected behavior**: Debug mode with full session logging (Mode 4)

**Implementation**: Both flags set to true, use appropriate branch

### 2. Authentication Persistence
**Scenario**: User doesn't exit cleanly (Ctrl+C, terminal crash) in debug mode

**Impact**: Home directory save won't run, authentication tokens might not persist

**Mitigation**: Document this limitation. Consider adding signal handlers in future.

### 3. Working Directory in Debug Shell
**Scenario**: User changes directory inside debug shell

**Expected behavior**: Fine - they're exploring the container. `su -l` starts in home directory, not /workspace.

**Note**: Document that `/workspace` is the mounted project directory. Users need to `cd /workspace` if they want to work there.

### 4. Logging Debug Shell Activity
**Scenario**: User runs `./claude-yo --debug --verbose` and uses debug shell

**Expected behavior**: All debug shell commands are logged (because `script` wrapper captures everything)

**Benefit**: Complete audit trail of debugging session

### 5. File Ownership
**Scenario**: User creates files as root in debug shell

**Risk**: Files created as root won't be accessible on host

**Mitigation**: Debug shell runs as mapped user (`su -l $CONTAINER_USER`), not root. Creating files as root requires `sudo` which isn't available in the container.

## Testing Plan

### Test Case 1: Default Mode (no flags)
```bash
./claude-yo
# Expected:
# - No "Press Enter" prompt
# - Claude starts immediately
# - When Claude exits, container exits (back to host)
# - No debug shell
# - Log file contains wrapper messages only (~10-15 lines)
```

### Test Case 2: Verbose Mode (`--verbose`)
```bash
./claude-yo --verbose
# Expected:
# - "Press Enter" prompt shown
# - User presses Enter
# - Claude starts
# - Full session logged to file
# - When Claude exits, container exits (back to host)
# - No debug shell
# - Log file contains full session (large)
```

### Test Case 3: Debug Mode (`--debug`)
```bash
./claude-yo --debug
# Expected:
# - "Press Enter" prompt shown
# - Container setup details displayed
# - User presses Enter
# - Claude starts
# - When Claude exits, debug shell appears
# - User can run commands (ls, pwd, cd /workspace, etc.)
# - User types 'exit'
# - Home directory is saved
# - Container exits, returns to host
# - Log file contains wrapper messages only (~15-20 lines)
```

### Test Case 4: Debug + Verbose Mode (`--debug --verbose`)
```bash
./claude-yo --debug --verbose
# Expected:
# - "Press Enter" prompt shown
# - Claude starts
# - When Claude exits, debug shell appears
# - User can run commands in debug shell
# - User types 'exit'
# - Home directory is saved
# - Container exits
# - Log file contains EVERYTHING: wrapper, Claude session, AND debug shell commands
```

### Test Case 5: Authentication Persistence in Debug Mode
```bash
# First run
./claude-yo --debug
# Inside container: Authenticate with Claude
# Exit cleanly

# Second run
./claude-yo --debug
# Expected: Already authenticated (tokens persisted)
```

### Test Case 6: File Creation in Debug Shell
```bash
./claude-yo --debug
# Inside debug shell:
cd /workspace
touch test-file.txt
ls -la test-file.txt
exit

# On host:
ls -la test-file.txt
# Expected: File exists with host user ownership
```

### Test Case 7: Debug Shell Starting Directory
```bash
./claude-yo --debug
# Inside debug shell:
pwd
# Expected: /home/$CONTAINER_USER (not /workspace)
# User must `cd /workspace` to work in project directory
```

## Implementation Checklist

- [ ] Add `DEBUG=false` variable initialization
- [ ] Add `-d|--debug` case to argument parsing
- [ ] Update help text with debug mode documentation and flag combinations
- [ ] Remove any flag conflict validation between debug and verbose
- [ ] Implement Mode 1: Default (no debug, no verbose)
- [ ] Implement Mode 2: Verbose only (no debug, with logging) - remove debug shell
- [ ] Implement Mode 3: Debug only (with debug, no logging)
- [ ] Implement Mode 4: Debug + Verbose (with debug, with logging)
- [ ] Handle fallback case when `script` command unavailable (for modes 2 and 4)
- [ ] Test all four modes independently
- [ ] Test flag combinations work correctly
- [ ] Verify authentication persistence in all modes
- [ ] Verify file ownership in debug shell
- [ ] Update TASKS.md to mark debug feature complete
- [ ] Update README.md with debug mode documentation
- [ ] Update CLAUDE.md to clarify debug shell is debug-mode-only

## Documentation Updates

After implementation, update:

1. **README.md**:
   - Add debug mode explanation
   - Show flag combination examples
   - Explain use cases for each mode

2. **CLAUDE.md**:
   - Update "Debug Shell Access" section to clarify it's debug-mode-only
   - Add note about `su -l` starting in home directory (not /workspace)

3. **TASKS.md**:
   - Mark debug task as complete
   - Note that debug and verbose can be combined

## Future Enhancements (Out of Scope)

- Signal handlers to ensure home directory save on Ctrl+C in debug mode
- `--no-persist` flag to skip home directory save (faster testing)
- Automatic cleanup of old authentication tokens
- Container naming to allow multiple simultaneous sessions
- `cd /workspace` automatically when entering debug shell
- Color-coded mode indicators in prompts

## Summary

The debug mode adds a second dimension to `claude-yo` operation:

**Two orthogonal flags**:
- `--debug`: Controls container lifecycle (exit immediately vs persistent shell)
- `--verbose`: Controls logging depth (wrapper only vs full session)

**Four possible modes**:
1. **Default**: Fast, clean, automatic exit
2. **Verbose only**: Session logging, automatic exit
3. **Debug only**: Persistent shell, wrapper logging
4. **Debug + Verbose**: Persistent shell, full session logging

**Key implementation points**:
- Flags are NOT mutually exclusive - users can combine them
- Sequential `su` calls (Claude, then shell) instead of nested
- Clear user messaging about what mode they're in
- Home directory save happens after debug shell exit
- Four explicit branches to handle all combinations clearly

This design maximizes flexibility while keeping the default fast and simple.

---

# Plan: Add Headless Mode (`--headless`)

> **Status: IMPLEMENTED** - This plan has been fully implemented. See `claude-yo` for the current implementation.

## Problem

`claude-yo` currently requires a TTY because all `docker run` invocations use the `-it` flags. This fails when running from cron or other non-interactive contexts:

```
the input device is not a TTY
```

The AI workload itself doesn't need a TTY - Claude Code can run non-interactively with `-p "prompt"`. The TTY requirement is solely from Docker's `-t` flag.

## Solution

Add a `--headless` flag that runs Docker without TTY allocation, enabling cron and other automated execution.

## Implementation

### 1. Add flag to argument parsing (around line 8)

```bash
REBUILD=false
VERBOSE=false
DEBUG=false
HEADLESS=false  # <-- Add this
CLAUDE_ARGS=()
```

### 2. Add case in the argument loop (around line 66)

```bash
    -d|--debug)
      DEBUG=true
      ;;
    --headless)           # <-- Add this block
      HEADLESS=true
      ;;
    *)
```

### 3. Update help text (around line 22)

```bash
echo "  --headless       Run without TTY (for cron/automation)"
```

### 4. Add validation - headless is incompatible with debug mode (after argument parsing)

```bash
# Validate flag combinations
if [ "$HEADLESS" = true ] && [ "$DEBUG" = true ]; then
  echo "Error: --headless and --debug are mutually exclusive"
  exit 1
fi
```

### 5. Add new execution mode for headless

The headless mode should:
- Use `docker run` without `-it` (no TTY, no interactive stdin)
- Skip verbose logging via `script` (which also needs a TTY)
- Not prompt for Enter or drop to debug shell
- Preserve exit code from Claude for proper error handling
- Still save home directory for auth persistence

```bash
if [ "$HEADLESS" = true ]; then
  # Headless mode: no TTY, no interactive prompts
  log_message "Headless mode - running non-interactively"

  docker run \
    -v "$MOUNTDIR":/workspace \
    -v claude-yolo-home:/home-persist \
    --rm \
    "$DOCKER_IMAGE" \
    /bin/bash -c "
      # User setup (same as other modes)
      EXISTING_USER=\$(getent passwd $USERID | cut -d: -f1)

      if [ -n \"\$EXISTING_USER\" ]; then
        CONTAINER_USER=\$EXISTING_USER
      else
        CONTAINER_USER=$USERNAME
        groupadd -g $GROUPID \$CONTAINER_USER 2>/dev/null || true
        useradd -u $USERID -g $GROUPID -m -s /bin/bash \$CONTAINER_USER
      fi

      # Restore home directory from persistent volume
      if [ -d /home-persist/\$CONTAINER_USER ]; then
        cp -a /home-persist/\$CONTAINER_USER/. /home/\$CONTAINER_USER/
      fi

      # Run Claude directly (no prompts, no TTY)
      su - \$CONTAINER_USER -c \"cd /workspace && $CLAUDE_CMD\"
      EXIT_CODE=\$?

      # Save home directory
      mkdir -p /home-persist/\$CONTAINER_USER
      cp -a /home/\$CONTAINER_USER/. /home-persist/\$CONTAINER_USER/

      exit \$EXIT_CODE
    "
elif [ "$DEBUG" = true ]; then
  # ... existing debug mode code
```

## Usage

```bash
# From cron
0 4 * * * /path/to/claude-yo --headless -p "/hello" >> /path/to/log 2>&1

# Manual testing
claude-yo --headless -p "/hello"
```

## Testing

1. `claude-yo --headless -p "echo hello"` - should complete without TTY error
2. `claude-yo --headless --debug` - should error with mutual exclusion message
3. Run from cron and verify execution completes
4. Verify auth persists across headless runs (the home-persist volume mount)

---

## Refactoring Recommendations

The `--headless` implementation will add a 5th execution mode to a script that already has significant code duplication. Consider these improvements:

### 1. Extract Common Container Setup Script

The user setup, home restore, and home save logic is identical across all modes. Extract to a variable:

```bash
CONTAINER_SETUP='
  EXISTING_USER=$(getent passwd USERID_PLACEHOLDER | cut -d: -f1)
  if [ -n "$EXISTING_USER" ]; then
    CONTAINER_USER=$EXISTING_USER
  else
    CONTAINER_USER=USERNAME_PLACEHOLDER
    groupadd -g GROUPID_PLACEHOLDER $CONTAINER_USER 2>/dev/null || true
    useradd -u USERID_PLACEHOLDER -g GROUPID_PLACEHOLDER -m -s /bin/bash $CONTAINER_USER
  fi

  if [ -d /home-persist/$CONTAINER_USER ]; then
    cp -a /home-persist/$CONTAINER_USER/. /home/$CONTAINER_USER/
  fi
'

CONTAINER_SAVE='
  mkdir -p /home-persist/$CONTAINER_USER
  cp -a /home/$CONTAINER_USER/. /home-persist/$CONTAINER_USER/
'
```

Then use `sed` to substitute the placeholders before use.

### 2. Headless + Verbose Consideration

The current proposal doesn't address headless+verbose. The `script` command also requires a TTY, so verbose logging would need a different approach in headless mode (simple output redirection rather than `script`). Consider:

- `--headless` alone: output goes to stdout/stderr (captured by cron redirection)
- `--headless --verbose`: redirect docker output to log file directly

### 3. Auto-Detection Option

Consider auto-detecting no TTY with `[ -t 0 ]` as a fallback:

```bash
# Auto-detect headless if no TTY available
if [ "$HEADLESS" != true ] && ! [ -t 0 ]; then
  log_message "No TTY detected, enabling headless mode automatically"
  HEADLESS=true
fi
```

This would make cron jobs "just work" without requiring `--headless`, but explicit is often more predictable.

### 4. Exit Code Propagation

The proposal correctly preserves exit codes with `EXIT_CODE=$?`. Consider adding this to other modes for consistency - currently the default mode doesn't explicitly preserve Claude's exit code.

### 5. Keep Setup Banner in Logs

For cron debugging, the "Container Setup Complete" banner is useful. Rather than removing it, route it through `log_message` so it appears in the log file but not cluttering stdout.
