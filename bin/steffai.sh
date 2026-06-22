#!/bin/bash

set -u
set -e

# 1. Configuration
TARGET_USER="${TARGET_USER:-steffai}"

# Check environment variables
KEEP_VARS="DISPLAY XDG_RUNTIME_DIR WAYLAND_DISPLAY XAUTHORITY"
TARGET_ENV=()
for i in ${KEEP_VARS}; do
    if [ ! -v "${i}" ]; then
        echo "Error: variable ${i} is not set."
        exit 1
    fi
    TARGET_ENV+=("$i=${!i}")
done

SOCKET_PATH="$XDG_RUNTIME_DIR/$WAYLAND_DISPLAY"

# Define cleanup function to revoke permissions on exit
cleanup() {
    echo "Cleaning up Wayland ACL permissions..."
    setfacl -m u:"$TARGET_USER" "$XAUTHORITY" 2>/dev/null || true
    setfacl -x u:"$TARGET_USER" "$SOCKET_PATH" 2>/dev/null || true
    setfacl -x u:"$TARGET_USER" "$XDG_RUNTIME_DIR" 2>/dev/null || true
}
trap cleanup EXIT

# Grant explicit access ONLY to the target user using ACLs
setfacl -m u:"$TARGET_USER":x  "$XDG_RUNTIME_DIR"
setfacl -m u:"$TARGET_USER":rw "$SOCKET_PATH"
setfacl -m u:"$TARGET_USER":r  "$XAUTHORITY"

# Execute OpenCode
echo "Launching environment for OpenCode as user '$TARGET_USER'"
sudo -u "$TARGET_USER" \
    "${TARGET_ENV[@]}" \
    LANG="en_150.UTF-8" \
    GIT_AUTHOR_NAME="$(git config user.name)" \
    GIT_AUTHOR_EMAIL="$(git config user.email)" \
    -i \
    ssh-agent /bin/bash \
    "$@"

