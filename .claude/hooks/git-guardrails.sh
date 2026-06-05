#!/bin/bash
# Claude Code PreToolUse hook: blocks destructive git operations with helpful messages
# Fires before Bash tool executes. Exit 0 = allow, Exit 2 = block.
#
# Covers: reset --hard, push --force/-f, clean -f, branch -D, checkout -- (bare)
# Does NOT block: git checkout <branch>, git push, git reset HEAD~1, git branch -d

INPUT=$(cat)

if command -v jq >/dev/null 2>&1; then
    COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')
else
    COMMAND=$(echo "$INPUT" | grep -oE '"command"[[:space:]]*:[[:space:]]*"[^"]*"' | \
              sed 's/"command"[[:space:]]*:[[:space:]]*"//;s/"$//')
fi

# Skip non-git commands fast
if ! echo "$COMMAND" | grep -qE '(^|;[[:space:]]*|&&[[:space:]]*|\|\|[[:space:]]*)git[[:space:]]'; then
    exit 0
fi

block() {
    local reason="$1"
    local alternative="$2"
    echo "" >&2
    echo "BLOCKED: $reason" >&2
    echo "" >&2
    echo "  $alternative" >&2
    echo "" >&2
    echo "To run anyway: ! $COMMAND" >&2
    exit 2
}

# git reset --hard
if echo "$COMMAND" | grep -qE 'git[[:space:]]+reset[[:space:]]+--hard'; then
    block \
        "git reset --hard discards ALL uncommitted changes permanently." \
        "Alternatives:  git stash  (save for later)  |  git reset HEAD~1  (soft — keeps changes staged)"
fi

# git push --force / git push -f
if echo "$COMMAND" | grep -qE 'git[[:space:]]+push[[:space:]]+(.*[[:space:]])?(--force|-f)([[:space:]]|$)'; then
    block \
        "Force push rewrites remote history. Unsafe on shared branches." \
        "Safer:  git push --force-with-lease  (aborts if remote has new commits)"
fi

# git clean -f / -fd / -fx / -dfx (any flag combo containing f)
if echo "$COMMAND" | grep -qE 'git[[:space:]]+clean[[:space:]]+-[a-zA-Z]*f'; then
    block \
        "git clean -f permanently deletes untracked files. No undo." \
        "Preview first:  git clean -n  (dry run — shows what would be removed)"
fi

# git branch -D (force-delete, ignores unmerged commits)
if echo "$COMMAND" | grep -qE 'git[[:space:]]+branch[[:space:]]+-D[[:space:]]'; then
    block \
        "git branch -D force-deletes even with unmerged commits." \
        "Safe:  git branch -d  (refuses if branch has unmerged work)"
fi

# git checkout -- (discard working directory changes)
# Bare "checkout -- ." or "checkout --" with nothing after = discard all → block
# "checkout -- <specific-file>" = single-file revert → warn only
if echo "$COMMAND" | grep -qE 'git[[:space:]]+checkout[[:space:]]+--([[:space:]]|$)'; then
    if echo "$COMMAND" | grep -qE 'git[[:space:]]+checkout[[:space:]]+--[[:space:]]*\.?[[:space:]]*$'; then
        block \
            "git checkout -- . discards ALL working directory changes permanently." \
            "Save first:  git stash  |  or commit what you want to keep"
    else
        # Single-file revert — allow with warning
        echo "Warning: git checkout -- <file> permanently discards uncommitted changes to that file. No undo." >&2
    fi
fi

exit 0
