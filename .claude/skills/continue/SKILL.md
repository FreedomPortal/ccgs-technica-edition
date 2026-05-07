---
name: continue
description: "Recover session context and continue where you left off. Reads session
  state, user memory, and agent memory to present a concise brief of last session's
  progress and planned next steps."
argument-hint: "[no arguments]"
user-invocable: true
allowed-tools: Read, Glob, AskUserQuestion
model: haiku
---

# Session Continue

Read-only skill. Reads session state and memory files to give you a concise brief
so you can pick up work immediately. Never writes files, never proposes changes.

---

## Phase 1: Read Session State

Read `production/session-state/active.md`.

- **File missing**: Report "No session state found. Try `/start` to get oriented."
  Then stop.
- **File found**: Extract:
  - Current development **stage**
  - What was **completed last session** (bulleted lists above the "Next session" section)
  - The **"Next session — pick up here"** section — the planned agenda

---

## Phase 2: Read User Memory

Derive the project slug from the current working directory:
- e.g. `C:\MyStudio\MyGame` → replace `:\` with `--`, remaining `\` with `-`
  → `C--MyStudio-MyGame`
- Read: `~/.claude/projects/[slug]/memory/MEMORY.md`

For each entry of type `project` or `reference`, read the linked file and extract
any **Remaining**, **Next**, or **Open** items. Skip `user` and `feedback` entries
(behavioral guidance, not session context).

---

## Phase 3: Scan Agent Memory (quick)

Read these files if they exist:
- `.claude/agent-memory/producer/MEMORY.md`
- `.claude/agent-memory/technical-director/MEMORY.md`
- `.claude/agent-memory/creative-director/MEMORY.md`

Extract only forward-looking markers: lines under "Next:", "Pending:", "Remaining:",
"Open question:". Skip resolved/historical entries.

---

## Phase 4: Present the Brief

Keep total output under 35 lines.

```markdown
## Session Continue — [Stage] — [Today's Date]

### Last Session
[2–4 bullets of what was completed — from active.md]

### Planned Next Steps
[Numbered list from the "Next session — pick up here" section]

### Open Items
[Unresolved items from project memory / agent memory. Cap at 5. Omit if empty.]
```

If `active.md` has no "Next session" section, note: "No planned steps recorded —
last session may not have ended with a checkpoint."

---

## Phase 5: Offer Next Action

`AskUserQuestion`:
- **Prompt**: "Which would you like to tackle first?"
- **Options**: up to 5 items from Planned Next Steps, plus "Something else — I'll describe it"

After selection, one line only:
- Known skill → "Type `[skill command]` to begin."
- Open-ended → "Tell me what you'd like to work on and I'll help."

---

## Edge Cases

- **active.md empty or malformed**: "Session state couldn't be parsed. Read
  `production/session-state/active.md` directly."
- **Memory path not derivable**: Skip Phase 2, note "User memory not found — session
  state only."
- **No agent memory files**: Skip Phase 3 silently.
- **Everything empty**: "Nothing to continue — try `/start`."
