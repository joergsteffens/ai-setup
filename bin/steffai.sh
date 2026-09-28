#!/bin/bash

# Lightweight variant of steffai-x.sh, when OpenCode is only used as a
# web server: no X11/Wayland setup, no xauth, no instance tracking.
#
# Usage:
#   steffai.sh                 -> login shell as the isolated user
#   steffai.sh opencode [args] -> run "opencode serve" with DEBUG logs
#   steffai.sh <cmd> [args]    -> run arbitrary command as the isolated user

set -u
set -e

TARGET_USER="${TARGET_USER:-steffai}"
TARGET_LANG="C.UTF-8"
OPENCODE_SERVE_LOG_FLAGS=(--print-logs --log-level DEBUG)

# ---- ssh agent ----

# The agent socket itself lives under /tmp/ssh-* owned by the target user
# (created by ssh-agent); only the calling user touches AGENT_ENV.
SSH_AUTH_SOCK=""
SSH_AGENT_PID=""
AGENT_ENV="${XDG_RUNTIME_DIR}/steffai-${TARGET_USER}.ssh-agent.env"

# Returns success if the recorded agent socket is still alive.
agent_alive()
{
  sudo -u "$TARGET_USER" \
    SSH_AUTH_SOCK="${SSH_AUTH_SOCK:-}" \
    SSH_AGENT_PID="${SSH_AGENT_PID:-}" \
    sh -c 'test -n "$SSH_AUTH_SOCK" && test -S "$SSH_AUTH_SOCK" && test -n "$SSH_AGENT_PID" && kill -0 "$SSH_AGENT_PID" 2>/dev/null'
}

load_ssh_agent()
{
  if [ -f "$AGENT_ENV" ]; then
    source "$AGENT_ENV"
  fi
  if ! agent_alive; then
    sudo -u "$TARGET_USER" ssh-agent -s >"$AGENT_ENV"
    source "$AGENT_ENV"
  fi
}

# ---- ssh agent keys ----

# ssh-add -l exit codes: 0 = key(s) loaded, 1 = agent empty, 2 = not reachable.
# The check must run as the target user (the agent socket is owned by it).
check_agent_keys()
{
  local status=0 out
  out=$(sudo -u "$TARGET_USER" \
    SSH_AUTH_SOCK="${SSH_AUTH_SOCK}" \
    SSH_AGENT_PID="${SSH_AGENT_PID}" \
    ssh-add -l 2>&1) || status=$?
  case $status in
    0)
      echo "SSH agent: loaded keys:"
      echo "$out"
      ;;
    1)
      echo "Warning: SSH agent has no keys loaded; git/GitHub access will fail."
      echo "         Run 'ssh-add' inside a steffai shell."
      ;;
    *)
      echo "Warning: cannot contact SSH agent (stale socket?)."
      echo "         Re-run this script to pick up a fresh agent."
      ;;
  esac
}

# ---- environment ----

GIT_NAME="$(git config user.name)"
GIT_EMAIL="$(git config user.email)"

TARGET_ENV=()
collect_env()
{
  TARGET_ENV+=("GIT_NAME=${GIT_NAME}" "GIT_EMAIL=${GIT_EMAIL}")
}

# ---- arguments ----

args=("$@")
resolve_args()
{
  if [ ${#args[@]} -eq 0 ]; then
    args=("bash" "--login")
  elif [ "${args[0]}" = "opencode" ]; then
    local home
    home=$(eval echo "~${TARGET_USER}")
    args[0]="${home}/.opencode/bin/opencode"
    # "steffai.sh opencode" starts the web server; extra args go to opencode.
    if [ ${#args[@]} -eq 1 ] || [ "${args[1]}" != "serve" ]; then
      args=("${args[0]}" "${OPENCODE_SERVE_LOG_FLAGS[@]}" serve "${args[@]:1}")
    else
      args=("${args[0]}" "${OPENCODE_SERVE_LOG_FLAGS[@]}" "${args[@]:1}")
    fi
  fi
}

# ---- launch ----

launch()
{
  echo "Launching environment for OpenCode as user '$TARGET_USER'."
  echo "For the full TUI/GUI environment use 'steffai-x.sh' instead."
  echo "Hint: 'steffai.sh opencode' starts the opencode server (DEBUG logs)."
  echo "Start it manually by:"
  echo "opencode ${OPENCODE_SERVE_LOG_FLAGS[*]} serve"
  sudo -u "$TARGET_USER" \
    "${TARGET_ENV[@]}" \
    SSH_AUTH_SOCK="${SSH_AUTH_SOCK}" \
    SSH_AGENT_PID="${SSH_AGENT_PID}" \
    LANG="${TARGET_LANG}" \
    "${args[@]}"
}

# ---- main ----

load_ssh_agent
check_agent_keys
collect_env
resolve_args
launch
