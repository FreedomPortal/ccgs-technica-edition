---
name: checkpoint
description: "Flush session discoveries to agent memory and session state. Call anytime to prevent knowledge loss from session crashes — after design discussions, when a new comparable is identified, or any time you sense 'I should remember this'."
argument-hint: "(no argument needed)"
user-invocable: true
allowed-tools: Read, Write, Edit, Glob, AskUserQuestion
---

## Phase 1: Identify Discoveries

Scan the current session conversation for cross-session-relevant facts:

| Category | Examples |
|----------|---------|
| Comparable / reference | New game, film, or manga added as inspiration |
| Design decision | Pillar confirmed, anti-pillar added, settled question |
| Technical constraint | Engine limitation, architectural choice, forbidden pattern |
| Production fact | Scope change, platform decision, monetization update |
| User preference | Workflow feedback, collaboration style |

List each discovery found. If none, report: "No new discoveries — memory is current."

---

## Phase 2: Route to Memory Files

| Discovery type | Write to |
|---------------|---------|
| Creative / design / art direction | `.claude/agent-memory/creative-director/MEMORY.md` |
| Technical / engine / architecture | `.claude/agent-memory/technical-director/MEMORY.md` |
| Production / scope / schedule / publishing | `.claude/agent-memory/producer/MEMORY.md` |
| Code standards / skill conventions | `.claude/agent-memory/lead-programmer/MEMORY.md` |
| Workflow / collaboration preferences | User memory at `~/.claude/projects/[project]/memory/` |

---

## Phase 3: Write Discoveries

Ask: "May I write these [N] discoveries to agent memory?" — one confirmation
covers all writes in this checkpoint. Do not ask again per file.

For each discovery:
1. Read the target memory file
2. Add to the right section (or create a new section if needed)
3. Write immediately — do not batch

---

## Phase 4: Update Session State

Append a checkpoint entry to `production/session-state/active.md`:

```
### Memory Checkpoint — [YYYY-MM-DD HH:MM]
- [Discovery summary] → [agent file]
```

---

## Phase 5: Confirm

> **Checkpoint complete.**
> [N] discoveries written to agent memory.
> These facts will survive a crash or compaction.

Verdict: COMPLETE

Recommended next: `/continue` to review pending tasks, or `/clear` + `/compact` to free context window.
