#!/bin/bash
# Claude Code SubagentStop hook: Log agent completion for audit trail
# Tracks when agents finish and their outcome
#
# Input schema (SubagentStop) — per Claude Code hooks reference:
# { "session_id": "...", "agent_id": "agent-abc123", "agent_type": "Explore",
#   "agent_transcript_path": "...", "last_assistant_message": "...", ... }
#
# The agent name is in `agent_type`, NOT `agent_name`. Reading `.agent_name`
# returns null on every invocation, so the fallback "unknown" is always used
# and the audit trail captures nothing useful.

INPUT=$(cat)

# Parse agent name -- use jq if available, fall back to grep
if command -v jq >/dev/null 2>&1; then
    AGENT_NAME=$(echo "$INPUT" | jq -r '.agent_type // "unknown"' 2>/dev/null)
else
    AGENT_NAME=$(echo "$INPUT" | grep -oE '"agent_type"[[:space:]]*:[[:space:]]*"[^"]*"' | sed 's/"agent_type"[[:space:]]*:[[:space:]]*"//;s/"$//')
    [ -z "$AGENT_NAME" ] && AGENT_NAME="unknown"
fi

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
SESSION_LOG_DIR="production/session-logs"

mkdir -p "$SESSION_LOG_DIR" 2>/dev/null

echo "$TIMESTAMP | Agent completed: $AGENT_NAME" >> "$SESSION_LOG_DIR/agent-audit.log" 2>/dev/null

# Write subagent's final output to drafts for crash recovery
# Protects implementation summaries if parent session dies after subagent completes
LAST_MSG=$(echo "$INPUT" | jq -r '.last_assistant_message // empty' 2>/dev/null)
if [ -n "$LAST_MSG" ]; then
    DRAFTS_DIR="production/session-state/drafts"
    mkdir -p "$DRAFTS_DIR" 2>/dev/null
    DRAFT_FILE="$DRAFTS_DIR/subagent-${AGENT_NAME}-${TIMESTAMP}.md"
    {
        echo "# Subagent Output: $AGENT_NAME — $TIMESTAMP"
        echo ""
        echo "$LAST_MSG"
    } > "$DRAFT_FILE" 2>/dev/null
fi

# Autosave: inject reminder into model context so active.md gets updated
echo "=== Autosave: $AGENT_NAME completed at $TIMESTAMP — write settled changes to production/session-state/active.md now ==="

exit 0
