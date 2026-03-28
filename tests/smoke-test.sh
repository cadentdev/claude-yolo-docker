#!/bin/bash
#
# claude-yo smoke tests
#
# Usage:
#   ./tests/smoke-test.sh           # Run all tests (skips auth tests if no .claude.json)
#   ./tests/smoke-test.sh --no-auth # Skip tests that require Claude Code authentication
#
# Test tiers:
#   1. Offline   — flag parsing, version, help (no Docker needed)
#   2. Container — build, user setup, mounts, security flags (Docker needed, no auth)
#   3. Auth      — headless prompt completion (Docker + auth needed)
#

set -o pipefail

# --- Configuration ---

SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
CLAUDE_YO="$SCRIPT_DIR/claude-yo"
SKIP_AUTH=false
TMPDIR_BASE=""

# Parse arguments
for arg in "$@"; do
  case $arg in
    --no-auth) SKIP_AUTH=true ;;
  esac
done

# --- Test Framework ---

PASS_COUNT=0
FAIL_COUNT=0
SKIP_COUNT=0

pass() {
  PASS_COUNT=$((PASS_COUNT + 1))
  printf "  \033[32m✓\033[0m %s\n" "$1"
}

fail() {
  FAIL_COUNT=$((FAIL_COUNT + 1))
  printf "  \033[31m✗\033[0m %s\n" "$1"
  if [ -n "$2" ]; then
    printf "    \033[31m→ %s\033[0m\n" "$2"
  fi
}

skip() {
  SKIP_COUNT=$((SKIP_COUNT + 1))
  printf "  \033[33m○\033[0m %s (skipped: %s)\n" "$1" "$2"
}

section() {
  echo ""
  printf "\033[1m── %s ──\033[0m\n" "$1"
}

# shellcheck disable=SC2317
cleanup() {
  if [ -n "$TMPDIR_BASE" ] && [ -d "$TMPDIR_BASE" ]; then
    rm -rf "$TMPDIR_BASE"
  fi
}
trap cleanup EXIT

TMPDIR_BASE=$(mktemp -d)

# --- Tier 1: Offline Tests (no Docker) ---

section "Offline Tests"

# Test: --version outputs current VERSION
EXPECTED_VERSION=$(grep '^VERSION=' "$CLAUDE_YO" | cut -d'"' -f2)
ACTUAL_VERSION=$("$CLAUDE_YO" --version 2>&1)
if [ "$ACTUAL_VERSION" = "claude-yo $EXPECTED_VERSION" ]; then
  pass "--version outputs $EXPECTED_VERSION"
else
  fail "--version output mismatch" "expected 'claude-yo $EXPECTED_VERSION', got '$ACTUAL_VERSION'"
fi

# Test: --help outputs usage text
HELP_OUTPUT=$("$CLAUDE_YO" --help 2>&1)
if echo "$HELP_OUTPUT" | grep -q "Usage: claude-yo"; then
  pass "--help outputs usage text"
else
  fail "--help missing usage text"
fi

# Test: --no-network prints removal warning
NO_NET_OUTPUT=$("$CLAUDE_YO" --no-network 2>&1)
NO_NET_EXIT=$?
if [ $NO_NET_EXIT -eq 1 ] && echo "$NO_NET_OUTPUT" | grep -q "has been removed"; then
  pass "--no-network prints removal warning and exits 1"
else
  fail "--no-network should warn and exit 1" "exit=$NO_NET_EXIT output='$NO_NET_OUTPUT'"
fi

# --- Tier 2: Container Tests (Docker required, no auth) ---

section "Container Tests"

if ! command -v docker &>/dev/null; then
  skip "Docker build" "docker not found"
  skip "Container user setup" "docker not found"
  skip "Mount points" "docker not found"
  skip "Security flags" "docker not found"
else
  # Ensure base image exists (build if needed, don't rebuild)
  if [[ "$(docker images -q claude-yolo:latest 2>/dev/null)" == "" ]]; then
    echo "  Building base image (first run)..."
    if docker build -t claude-yolo:latest "$SCRIPT_DIR" >/dev/null 2>&1; then
      pass "Docker image builds successfully"
    else
      fail "Docker image build failed"
      # Can't continue container tests without image
      skip "Container user setup" "image build failed"
      skip "Mount points" "image build failed"
      skip "Security flags" "image build failed"
      SKIP_AUTH=true
    fi
  else
    pass "Docker image exists"
  fi

  if docker images -q claude-yolo:latest 2>/dev/null | grep -q .; then

    # Test: container user setup succeeds (useradd + su)
    USERID=$(id -u)
    GROUPID=$(id -g)
    USERNAME=$(whoami)

    USER_SETUP_OUTPUT=$(docker run \
      --cap-drop=ALL \
      --cap-add=SETUID --cap-add=SETGID --cap-add=CHOWN \
      --cap-add=DAC_OVERRIDE --cap-add=FOWNER \
      --security-opt=no-new-privileges \
      --rm \
      claude-yolo:latest \
      /bin/bash -c "
        EXISTING_USER=\$(getent passwd $USERID | cut -d: -f1)
        if [ -n \"\$EXISTING_USER\" ]; then
          CONTAINER_USER=\$EXISTING_USER
        else
          CONTAINER_USER=$USERNAME
          groupadd -g $GROUPID \$CONTAINER_USER 2>/dev/null || true
          useradd -u $USERID -g $GROUPID -m -s /bin/bash \$CONTAINER_USER
        fi
        su - \$CONTAINER_USER -c 'echo USER_SETUP_OK'
      " 2>&1)

    if echo "$USER_SETUP_OUTPUT" | grep -q "USER_SETUP_OK"; then
      pass "Container user setup succeeds (useradd + su)"
    else
      fail "Container user setup failed" "$USER_SETUP_OUTPUT"
    fi

    # Test: cap-drop + cap-adds + no-new-privileges applied
    # Verify by checking that operations requiring OTHER caps fail
    CAP_TEST_OUTPUT=$(docker run \
      --cap-drop=ALL \
      --cap-add=SETUID --cap-add=SETGID --cap-add=CHOWN \
      --cap-add=DAC_OVERRIDE --cap-add=FOWNER \
      --security-opt=no-new-privileges \
      --rm \
      claude-yolo:latest \
      /bin/bash -c "
        # NET_RAW should be dropped — ping should fail
        if ping -c 1 -W 1 127.0.0.1 >/dev/null 2>&1; then
          echo 'CAP_CHECK_FAIL: ping succeeded (NET_RAW not dropped)'
        else
          echo 'CAP_CHECK_OK'
        fi
      " 2>&1)

    if echo "$CAP_TEST_OUTPUT" | grep -q "CAP_CHECK_OK"; then
      pass "Security flags applied (non-required caps are dropped)"
    else
      fail "Security flags not working" "$CAP_TEST_OUTPUT"
    fi

    # Test: mount points accessible inside container
    # Create a temp .claude.json for mount testing
    echo '{"test": true}' > "$TMPDIR_BASE/.claude.json"
    mkdir -p "$TMPDIR_BASE/.claude"
    echo '{"test": true}' > "$TMPDIR_BASE/.claude/test-marker"

    MOUNT_OUTPUT=$(docker run \
      --cap-drop=ALL \
      --cap-add=SETUID --cap-add=SETGID --cap-add=CHOWN \
      --cap-add=DAC_OVERRIDE --cap-add=FOWNER \
      --security-opt=no-new-privileges \
      -v "$TMPDIR_BASE/.claude:/host-claude:ro" \
      -v "$TMPDIR_BASE/.claude.json:/host-claude-json:ro" \
      --rm \
      claude-yolo:latest \
      /bin/bash -c "
        CHECKS=0
        if [ -f /host-claude-json ]; then
          CHECKS=\$((CHECKS + 1))
        fi
        if [ -d /host-claude ]; then
          CHECKS=\$((CHECKS + 1))
        fi
        if [ -f /host-claude/test-marker ]; then
          CHECKS=\$((CHECKS + 1))
        fi
        echo \"MOUNT_CHECKS=\$CHECKS\"
      " 2>&1)

    MOUNT_CHECKS=$(echo "$MOUNT_OUTPUT" | grep "MOUNT_CHECKS=" | cut -d= -f2)
    if [ "$MOUNT_CHECKS" = "3" ]; then
      pass "Mount points accessible (.claude.json + .claude/ + contents)"
    else
      fail "Mount point check failed" "expected 3 checks, got: $MOUNT_OUTPUT"
    fi
  fi
fi

# --- Tier 3: Auth Tests (Docker + auth required) ---

section "Auth Tests"

if [ "$SKIP_AUTH" = true ]; then
  skip "Headless prompt completion" "--no-auth flag set"
elif [ ! -f "$HOME/.claude.json" ]; then
  skip "Headless prompt completion" "$HOME/.claude.json not found"
elif ! command -v docker &>/dev/null; then
  skip "Headless prompt completion" "docker not found"
else
  # Test: headless mode completes a trivial prompt
  # Use /version which is fast and doesn't consume API tokens
  AUTH_OUTPUT=$("$CLAUDE_YO" --headless -p "Reply with exactly: SMOKE_TEST_OK" 2>&1)
  AUTH_EXIT=$?

  if echo "$AUTH_OUTPUT" | grep -q "SMOKE_TEST_OK"; then
    pass "Headless prompt completes successfully"
  elif [ $AUTH_EXIT -ne 0 ]; then
    fail "Headless prompt failed (exit $AUTH_EXIT)" "$(echo "$AUTH_OUTPUT" | tail -3)"
  else
    fail "Headless prompt completed but output unexpected" "$(echo "$AUTH_OUTPUT" | tail -3)"
  fi
fi

# --- Summary ---

echo ""
printf "\033[1m── Summary ──\033[0m\n"
TOTAL=$((PASS_COUNT + FAIL_COUNT + SKIP_COUNT))
printf "  Total: %d | \033[32mPass: %d\033[0m | \033[31mFail: %d\033[0m | \033[33mSkip: %d\033[0m\n" \
  "$TOTAL" "$PASS_COUNT" "$FAIL_COUNT" "$SKIP_COUNT"

if [ "$FAIL_COUNT" -gt 0 ]; then
  echo ""
  printf "  \033[31mSMOKE TESTS FAILED\033[0m\n"
  exit 1
else
  echo ""
  printf "  \033[32mALL SMOKE TESTS PASSED\033[0m\n"
  exit 0
fi
