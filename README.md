# ai-setup: Isolated OpenCode Setup

This repository contains a small helper script (`steffai.sh`) to run OpenCode in an isolated environment.

## Motivation

OpenCode can be connected to GitHub and may perform actions on behalf of the authenticated user. While this is convenient, it also grants the AI access to repositories and permissions associated with that account.

To reduce risk, OpenCode is executed under a dedicated Linux user and GitHub account.

## Security Model

Instead of using my primary user account:

* A dedicated GitHub account was created:

  * `steffai`
* A dedicated Linux user was created:

  * `steffai`
* All repositories used by OpenCode are owned by `steffai`.
* OpenCode runs as `steffai`.

This isolates:

* SSH keys
* Git configuration
* Repository access
* OpenCode configuration

from the main workstation user.

However, on my system, all users of the group `users` should be able to locally access the source code files, so they are able to also work on the code.

## Initial Setup

### Create a new GitHub account

In my case steffai.
Create an email address for that user (e.g. email alias to your main email address).

### Create Linux User

Create the Linux user you want to use.
I have choosen `steffai`, as you may have guessed. 

```bash
sudo adduser steffai
```

If you have choosen another username, you can set

```bash
export TARGET_USER=<your-account-name>
steffai.sh
```

### Generate SSH Key

As `steffai`.

```bash
ssh-keygen -t ed25519
```

### Configure GitHub Access

Add the public key to the GitHub account:

```bash
cat ~/.ssh/id_ed25519.pub
```

GitHub:

* Settings
* SSH and GPG Keys
* New SSH Key

Verify access:

```bash
ssh -T git@github.com
```

### Clone Repositories

All repositories should be cloned as user `steffai`.


### Install OpenCode

Install OpenCode while logged in as `steffai`.

Refer to the official documentation: https://opencode.ai

## Running OpenCode

Two helper scripts are available; internally both use `sudo` to switch
to the isolated account before starting OpenCode.

### `steffai.sh` - lightweight variant

For the common case where OpenCode mostly runs as a web server
(`opencode serve`). No X11/Wayland/xauth setup, no instance tracking.

* `steffai.sh` - login shell as the isolated user
* `steffai.sh opencode` - runs `opencode --print-logs --log-level DEBUG serve`
  (extra arguments are passed to `opencode`; explicit `serve` is not duplicated)
* `steffai.sh <cmd>` - run arbitrary command as the isolated user

### `steffai-x.sh` - full GUI variant

Switch to the user steffai by running the script.
Afterwards you can start opencode.

Additionally sets up X11 (`xauth`) and Wayland access (socket ACLs),
tracks running instances for cleanup, and is the right choice for
interactive TUI sessions, e.g. `steffai-x.sh opencode`.
Wayland programs need `wrun` (see `bin/wrun`) inside such a session.

## Connect Main User to OpenCode

### https://opencode.ai/console/

Potential options:

* GitHub authentication
* Google authentication

Google authentication no repository-related permissions, so I guess it can safely be used.

### https://opencode.ai/console/

https://console.opencode.ai additionally offers creating a user account with username and password.

# Setup working dirs

* full write access to all group members (group: users)


```
TARGET="/local/work/"
PERM="g::rwx,o::rx"
setfacl -R -m $PERM -d -m $PERM "${TARGET}"
chgrp -R users "${TARGET}"
find "${TARGET}" -type d -exec chmod g+s {} \;
```
