#!/bin/bash

set -u
set -e

# Configuration
TARGET_USER="${TARGET_USER:-steffai}"

LOCK_DIR="${XDG_RUNTIME_DIR}/steffai-${TARGET_USER}.instances"
mkdir -p "$LOCK_DIR"

# Clean stale instance markers from crashed previous runs
for f in "${LOCK_DIR}"/inst.*; do
    [ -f "$f" ] || continue
    pid="${f##*.}"
    if ! kill -0 "$pid" 2>/dev/null; then
        rm -f "$f"
    fi
done

INSTANCE_FILE="${LOCK_DIR}/inst.$$"
: > "$INSTANCE_FILE"

TARGET_LANG="C.UTF-8"

GIT_NAME="$(git config user.name)"
GIT_EMAIL="$(git config user.email)"

XAUTHORITY_SOURCE="${XDG_RUNTIME_DIR}/steffai-${TARGET_USER}.xauth"
if [ ! -f "$XAUTHORITY_SOURCE" ]; then
    tmp_xauth=$(mktemp -p "${XDG_RUNTIME_DIR}" xauth-tmp.XXXXXXXXXX)
    xauth extract "$tmp_xauth" "$DISPLAY"
    if ! mv -n "$tmp_xauth" "$XAUTHORITY_SOURCE" 2>/dev/null; then
        rm -f "$tmp_xauth"
    fi
fi
setfacl -m u:"$TARGET_USER":r "${XAUTHORITY_SOURCE}" 2>/dev/null || true

# Check environment variables
KEEP_VARS="DISPLAY GIT_NAME GIT_EMAIL WAYLAND_DISPLAY"
# XDG_RUNTIME_DIR
#   set: wl-copy: works, podman: fails
#   unset: wl-copy: fails, podman: works
#   however, xclip is used instead.
TARGET_ENV=()
for i in ${KEEP_VARS}; do
    if [ ! -v "${i}" ]; then
        echo "Error: variable ${i} is not set."
        exit 1
    fi
    TARGET_ENV+=("$i=${!i}")
done

SOCKET_PATH="$XDG_RUNTIME_DIR/$WAYLAND_DISPLAY"

args=("$@")
if [ ${#args[@]} -eq 0 ]; then
    args=("bash" "--login")
elif [ "${args[0]}" = "opencode" ]; then
    HOME=$(eval echo "~${TARGET_USER}")
    args[0]="${HOME}/.opencode/bin/opencode"
fi

# Define cleanup function to revoke permissions on exit
cleanup() {
    rm -f "${INSTANCE_FILE}" 2>/dev/null || true
    rmdir "${LOCK_DIR}" 2>/dev/null && {
        echo "Cleaning up Wayland ACL permissions..."
        setfacl -x u:"$TARGET_USER" "$SOCKET_PATH" 2>/dev/null || true
        setfacl -x u:"$TARGET_USER" "$XDG_RUNTIME_DIR" 2>/dev/null || true
        rm -f "${XAUTHORITY_SOURCE}" 2>/dev/null || true
    }
}
trap cleanup EXIT

# Grant explicit access ONLY to the target user using ACLs
setfacl -m u:"$TARGET_USER":x  "${XDG_RUNTIME_DIR}"
setfacl -m u:"$TARGET_USER":rw "${SOCKET_PATH}"

echo "Launching environment for OpenCode as user '$TARGET_USER'"
sudo -u "$TARGET_USER" \
    "${TARGET_ENV[@]}" \
    SUDO_XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR}" \
    XAUTHORITY="${XAUTHORITY_SOURCE}" \
    LANG="${TARGET_LANG}" \
    ssh-agent \
    "${args[@]}"

# use following for wayland programs:
# export XDG_RUNTIME_DIR="${SUDO_XDG_RUNTIME_DIR}"
