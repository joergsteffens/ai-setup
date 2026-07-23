## Commit workflow

**Default: always add new commits. Never rewrite, rebase, or amend unless explicitly asked.**
- Never push or create a PR unless told to.

## Destructive Operations and Data Safety

Never perform a destructive operation without explicit user permission.

An operation is **destructive** if it permanently removes data or makes an existing state unrecoverable.

### Git

Changes to files and history tracked by Git are allowed, as long as the previous version remains available in Git history. You may freely modify, delete, commit, rebase, or amend Git-tracked data under this condition.

### Everything outside Git

Treat all data and state outside Git as persistent and valuable. Never delete, overwrite, reset, recreate, or otherwise destroy it without explicit user permission. This includes runtime state such as containers, volumes, databases, and untracked files.

Do not assume that data is disposable, temporary, unused, or reproducible.

If you are unsure whether an operation is destructive or whether the previous state remains recoverable, **stop and ask the user before proceeding**.

**When in doubt, ask.**

## Identifying yourself in git commits

Every commit must end with `Co-authored-by:` using the **exact full model ID** from your system prompt's `Powered by:` / `The exact model ID is` line. Never copy an identifier from elsewhere. When squashing another AI's work, keep their original `Co-authored-by:` and add your own.

## Communication

When uncertain, ask clarifying questions (1-2 sentences). Confirm before destructive operations (rebase, squash, amend, reset, force-push).
