---
name: continue
description: "Recover session context and continue where you left off. Reads session
  state, user memory, and agent memory to present a concise brief of last session's
  progress and planned next steps."
argument-hint: "[no arguments]"
user-invocable: true
allowed-tools: Read, Glob, Grep, AskUserQuestion
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
  - The **"Next session — pick up here"** section — use the **last occurrence** in the
    file (or the one marked `CANONICAL` if present). Earlier occurrences are historical
    and must be ignored.

---

## Phase 1b: Filter Done Stories

If `production/sprint-status.yaml` exists, read it.

Extract every story ID where `status: done` (e.g. `S3-09`, `S3-01`).

When building "Planned Next Steps" for Phase 4, **drop any item whose text contains
a done story ID**. If one or more items are dropped, prepend this note to the
Planned Next Steps block:

> _(N step(s) omitted — already done per sprint-status.yaml)_

If `sprint-status.yaml` does not exist, skip this phase silently.

---

## Phase 1c: Validate CANONICAL Against Evidence

**Stale CANONICAL check** — `active.md` CANONICAL can lag if a session ends without
`/checkpoint`. Cross-check before presenting next steps:

1. Note `sprint: N` from `sprint-status.yaml` (skip if yaml missing).
2. Glob `production/retrospectives/retro-sprint-[N-1]-*.md`.
3. If a retro file **exists** AND the CANONICAL text contains `/retrospective` or
   `retrospective` referencing sprint N-1 → CANONICAL is stale.

When stale, prepend this warning to Planned Next Steps:

> ⚠️ **Stale session state** — `sprint-status.yaml` shows Sprint N active and a
> Sprint N-1 retro exists, but `active.md` CANONICAL references Sprint N-1
> close-out work. Showing active sprint stories instead.

Then replace Planned Next Steps with stories from `sprint-status.yaml` that are
**not** `done`, ordered: must-have → should-have → nice-to-have.

If no stale condition is detected, proceed with active.md CANONICAL as normal.

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

Verdict: COMPLETE — session brief delivered.

---

## Edge Cases

- **active.md empty or malformed**: "Session state couldn't be parsed. Read
  `production/session-state/active.md` directly."
- **Memory path not derivable**: Skip Phase 2, note "User memory not found — session
  state only."
- **No agent memory files**: Skip Phase 3 silently.
- **Everything empty**: "Nothing to continue — try `/start`."

---

This skill is read-only — no write approval required.
