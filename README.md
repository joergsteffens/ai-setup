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

Refer to the official documentation:

https://opencode.ai

## Running OpenCode

Switch to the user steffai by running the script.
Afterwards you can start opencode.

Internally it uses `sudo` to switch to the isolated account before starting OpenCode.

## Optional: OpenRouter

OpenRouter provides access to many LLMs through a single API.

Website:

https://openrouter.ai/

Advantages:

* Access to multiple model providers
* Free models available

Some free models are bundled through:

```text
openrouter/free
```

## Connect Main User to OpenCode

Potential options:

* GitHub authentication
* Google authentication

Google authentication no repository-related permissions, so I guess it can safely be used.


# Setup working dirs

* full write access to all group members (group: users)


```
TARGET="/local/work/"
PERM="g::rwx,o::rx"
setfacl -R -m $PERM -d -m $PERM "${TARGET}"
chgrp -R users "${TARGET}"
find "${TARGET}" -type d -exec chmod g+s {} \;
```
