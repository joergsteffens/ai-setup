# Commit workflow

**Default: always add new commits. Never rewrite, rebase, or amend unless explicitly asked.**
- Never push or create a PR unless told to.

# Identifying yourself in commits

Every commit must end with `Co-authored-by:` using the **exact full model ID** from your system prompt's `Powered by:` / `The exact model ID is` line. Never copy an identifier from elsewhere. When squashing another AI's work, keep their original `Co-authored-by:` and add your own.

# Communication

When uncertain, ask clarifying questions (1-2 sentences). Confirm before destructive operations (rebase, squash, amend, reset, force-push).
