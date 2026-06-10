#!/bin/bash
# Claude Code SessionStart hook: Load project context at session start
# Outputs context information that Claude sees when a session begins
#
# Input schema (SessionStart): No stdin input

echo "=== Claude Code Game Studios — Session Context ==="

# Current branch
BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
if [ -n "$BRANCH" ]; then
    echo "Branch: $BRANCH"

    # Recent commits
    echo ""
    echo "Recent commits:"
    git log --oneline -5 2>/dev/null | while read -r line; do
        echo "  $line"
    done
fi

# Current sprint (find most recent sprint file)
LATEST_SPRINT=$(ls -t production/sprints/sprint-*.md 2>/dev/null | head -1)
if [ -n "$LATEST_SPRINT" ]; then
    echo ""
    echo "Active sprint: $(basename "$LATEST_SPRINT" .md)"
fi

# Current milestone
LATEST_MILESTONE=$(ls -t production/milestones/*.md 2>/dev/null | head -1)
if [ -n "$LATEST_MILESTONE" ]; then
    echo "Active milestone: $(basename "$LATEST_MILESTONE" .md)"
fi

# Open bug count
BUG_COUNT=0
for dir in tests/playtest production; do
    if [ -d "$dir" ]; then
        count=$(find "$dir" -name "BUG-*.md" 2>/dev/null | wc -l)
        BUG_COUNT=$((BUG_COUNT + count))
    fi
done
if [ "$BUG_COUNT" -gt 0 ]; then
    echo "Open bugs: $BUG_COUNT"
fi

# Code health quick check
if [ -d "src" ]; then
    TODO_COUNT=$(grep -r "TODO" src/ 2>/dev/null | wc -l)
    FIXME_COUNT=$(grep -r "FIXME" src/ 2>/dev/null | wc -l)
    if [ "$TODO_COUNT" -gt 0 ] || [ "$FIXME_COUNT" -gt 0 ]; then
        echo ""
        echo "Code health: ${TODO_COUNT} TODOs, ${FIXME_COUNT} FIXMEs in src/"
    fi
fi

# --- Active session state recovery ---
STATE_FILE="production/session-state/active.md"
if [ -f "$STATE_FILE" ]; then
    echo ""
    echo "=== ACTIVE SESSION STATE DETECTED ==="
    echo "A previous session left state at: $STATE_FILE"
    echo "Read this file to recover context and continue where you left off."
    echo ""
    echo "Quick summary (last 20 lines):"
    tail -20 "$STATE_FILE" 2>/dev/null
    TOTAL_LINES=$(wc -l < "$STATE_FILE" 2>/dev/null)
    if [ "$TOTAL_LINES" -gt 20 ]; then
        echo "  ... ($TOTAL_LINES total lines — read the full file to continue)"
    fi
    echo "=== END SESSION STATE PREVIEW ==="
fi

# --- Publishing pipeline check ---
ROADMAP_FILE="production/publishing/publishing-roadmap.md"
COMMUNITY_FILE="production/publishing/community-status.md"

echo ""
echo "=== PUBLISHING PIPELINE ==="

if [ ! -f "$ROADMAP_FILE" ]; then
    echo "⚠️  No publishing roadmap found."
    echo "   Publishing work should start in pre-production — not at launch."
    echo "   Run /marketing-plan to create your publishing roadmap now."
else
    echo "Publishing roadmap: found"

    # Count overdue items (lines with 🔴)
    OVERDUE_COUNT=$(grep -c "🔴" "$ROADMAP_FILE" 2>/dev/null || echo 0)
    # Count unlocked items (lines with 🟡)
    UNLOCKED_COUNT=$(grep -c "🟡" "$ROADMAP_FILE" 2>/dev/null || echo 0)

    if [ "$OVERDUE_COUNT" -gt 0 ]; then
        echo "🔴 Overdue publishing tasks: $OVERDUE_COUNT"
        grep "🔴" "$ROADMAP_FILE" 2>/dev/null | head -3 | while read -r line; do
            echo "   $line"
        done
        if [ "$OVERDUE_COUNT" -gt 3 ]; then
            echo "   ... ($OVERDUE_COUNT total — run /publish-check for full list)"
        fi
    fi

    if [ "$UNLOCKED_COUNT" -gt 0 ]; then
        echo "🟡 Publishing tasks unlocked by current dev stage: $UNLOCKED_COUNT"
        grep "🟡" "$ROADMAP_FILE" 2>/dev/null | head -3 | while read -r line; do
            echo "   $line"
        done
        if [ "$UNLOCKED_COUNT" -gt 3 ]; then
            echo "   ... ($UNLOCKED_COUNT total — run /publish-check for full list)"
        fi
    fi

    if [ "$OVERDUE_COUNT" -eq 0 ] && [ "$UNLOCKED_COUNT" -eq 0 ]; then
        echo "✅ No overdue or unlocked publishing tasks."
    fi
fi

# Community status summary
if [ -f "$COMMUNITY_FILE" ]; then
    # Find platforms with no recent post (lines containing "—" or "not set up")
    INACTIVE=$(grep -c "not set up\|—\|No posts" "$COMMUNITY_FILE" 2>/dev/null || echo 0)
    if [ "$INACTIVE" -gt 0 ]; then
        echo "💬 Community: $INACTIVE platform(s) inactive or not set up"
        echo "   Run /community-plan to review."
    else
        echo "💬 Community: active"
    fi
fi

echo "=== END PUBLISHING CHECK ==="

# --- Localization intent check ---
L10N_INTENT="production/localization/intent.md"

if [ -f "$L10N_INTENT" ]; then
    L10N_STATUS=$(grep "^\*\*Status\*\*:" "$L10N_INTENT" 2>/dev/null | head -1 | sed 's/\*\*Status\*\*: //')
    if [ "$L10N_STATUS" = "YES" ]; then
        echo ""
        echo "=== LOCALIZATION ==="
        L10N_LOCALES=$(grep "^\*\*Target locales\*\*:" "$L10N_INTENT" 2>/dev/null | sed 's/\*\*Target locales\*\*: //')
        STAGE=$(cat production/stage.txt 2>/dev/null || echo "unknown")
        echo "🌐 l10n intent: YES — locales: $L10N_LOCALES (stage: $STAGE)"

        # String table
        if [ ! -f "assets/data/strings/strings-en.json" ]; then
            echo "⚠️  String table missing — run /l10n-prepare scaffold"
        else
            KEY_COUNT=$(grep -c '"source":' assets/data/strings/strings-en.json 2>/dev/null || echo 0)
            echo "   String table: $KEY_COUNT keys"
        fi

        # Freeze status
        FREEZE_FILE="production/localization/freeze-status.md"
        if [ -f "$FREEZE_FILE" ]; then
            FREEZE=$(grep "^\*\*Status\*\*:" "$FREEZE_FILE" 2>/dev/null | head -1 | sed 's/\*\*Status\*\*: //')
            echo "   String freeze: $FREEZE"
        else
            echo "   String freeze: not called"
        fi

        # LQA passes
        LQA_COUNT=$(ls production/localization/lqa-*-*.md 2>/dev/null | wc -l)
        if [ "$LQA_COUNT" -gt 0 ]; then
            echo "   LQA reports: $LQA_COUNT — run /l10n-check for per-locale status"
        fi

        echo "   Run /l10n-check for full status and next steps."
        echo "=== END LOCALIZATION ==="
    elif [ "$L10N_STATUS" = "LATER" ]; then
        STAGE=$(cat production/stage.txt 2>/dev/null || echo "unknown")
        case "$STAGE" in
            Production|Polish|Release)
                echo ""
                echo "=== LOCALIZATION ==="
                echo "⚠️  l10n intent: LATER — now in $STAGE. Commit YES or NO in production/localization/intent.md."
                echo "=== END LOCALIZATION ==="
                ;;
        esac
    fi
fi

echo "==================================="
exit 0
