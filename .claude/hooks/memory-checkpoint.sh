#!/bin/bash
# PostToolUse hook: Memory checkpoint reminder after significant file writes
# Reminds Claude to flush conversational discoveries to agent memory immediately
# Exit 0 = allow (this hook never blocks)

INPUT=$(cat)

TOOL=$(echo "$INPUT" | jq -r '.tool_name // empty' 2>/dev/null)
if [ "$TOOL" != "Write" ] && [ "$TOOL" != "Edit" ]; then
    exit 0
fi

FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty' 2>/dev/null)
if [ -z "$FILE_PATH" ]; then
    exit 0
fi

# Skip if already writing to agent memory -- no need to remind
if echo "$FILE_PATH" | grep -qE '\.claude/agent-memory/'; then
    exit 0
fi

# Trigger on significant design/architecture writes
if echo "$FILE_PATH" | grep -qE '(design/gdd/|docs/architecture/|design/ux/|design/narrative/)'; then
    echo ""
    echo "=== MEMORY CHECKPOINT ==="
    echo "Design/architecture file written: $FILE_PATH"
    echo "That file IS the record of the decision — do not duplicate it in agent memory."
    echo "Only write to agent memory if this session also surfaced knowledge NOT in that file:"
    echo "  - Comparable titles, references, or inspirations"
    echo "  - Constraints, lessons, or preferences not captured in the doc"
    echo "  - Settled questions that exist only in conversation"
    echo "If none of the above — no agent memory write needed. The doc is enough."
    echo "========================="
fi

exit 0
