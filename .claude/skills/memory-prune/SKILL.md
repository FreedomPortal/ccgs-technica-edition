---
name: memory-prune
description: "Prune stale forward-looking entries from agent memory files and session state. Removes resolved 'Next:', 'Pending:', 'Open:' items and old session extracts. Run at sprint boundaries, or before /gate-check and /architecture-review to prevent stale state from corrupting verdicts."
argument-hint: "(no argument needed)"
user-invocable: true
allowed-tools: Read, Write, Edit, Glob
model: haiku
---

# Memory Prune

Scan agent memory files and session state, remove stale forward-looking entries.
Read-heavy, low-risk. Never deletes permanent architectural decisions or patterns.

> **Run before**: `/gate-check`, `/architecture-review`, or at sprint boundary.
> Stale "Pending" entries can cause those skills to report false blockers or miss
> resolved issues — pruning first ensures they read current state.

---

## Phase 1: Read All Files

Read each of these files (skip if missing):

**Sprint status (read first):**
- `production/sprint-status.yaml` — extract the set of story IDs where `status: done`
  (e.g. `S3-01`, `S3-09`). Used in Phase 2 to validate "Next session" items.

**Agent memory:**

For each of these agents: `producer`, `technical-director`, `creative-director`, `lead-programmer`

Check if the agent uses sharded memory:
```bash
[ -f ".claude/agent-memory/[agent]/MEMORY.md" ] && \
  grep -q "Shard loading protocol" ".claude/agent-memory/[agent]/MEMORY.md" \
  && echo "SHARDED" || echo "FLAT"
```

- **FLAT**: read `.claude/agent-memory/[agent]/MEMORY.md` as before
- **SHARDED**: read `.claude/agent-memory/[agent]/MEMORY.md` (index only — skip it, no prunable content)
  then read each shard: `.claude/agent-memory/[agent]/shards/*.md` (skip `_legacy-flat.md`)

**Session state:**
- `production/session-state/active.md`

---

## Phase 2: Classify Every Entry

### Agent memory files

| Class | Keep? | Examples |
|-------|-------|---------|
| **Permanent** | Always keep | ADRs, architectural constraints, forbidden patterns, confirmed design decisions, art direction pillars |
| **Stale — resolved** | Remove | "Next: do X" where X is now done; "Pending: S3-01" where S3-01 is complete; "Open question:" that was answered |
| **Stale — superseded** | Remove | Old sprint status overwritten by newer checkpoint; "blocked on S2-04" where S2-04 is done |
| **Still active** | Keep | Genuine open questions; current blockers; pending tasks not yet started |

### session-state/active.md

`active.md` is an append-only log that accumulates session extracts and memory checkpoints. Keep the tail; prune the body.

| Class | Keep? | Examples |
|-------|-------|---------|
| **Current STATUS block** | Always keep | `<!-- STATUS -->` block at top of file |
| **Most recent "Next session — pick up here"** | Keep, then validate (see below) | The last planned agenda |
| **Recent session extracts** | Keep last 2–3 sprints | Useful context window for `/continue` |
| **Old session extracts** | Remove | Sprint 1/2 extracts when Sprint 3+ is active; individual story extracts for stories closed 2+ sprints ago |
| **Memory checkpoints** | Remove all but last 3 | Checkpoint text is already flushed to agent memory — duplicate in active.md is pure bulk |
| **"Next session" sections** | Remove all but most recent | Superseded agendas from prior sessions |
| **"Prior Sessions" marker** | Keep | Signals where detail was truncated |

**Hard rule for active.md**: Never remove the most recent `### Next session — pick up here` section or the STATUS block. Everything else is a judgment call — prefer keeping when uncertain.

**Additional step — validate kept "Next session" items against sprint-status.yaml:**
After identifying the most recent `### Next session — pick up here` section to keep,
scan each numbered item in that section for story ID references (e.g. `S3-09`, `S3-01`).
If the story ID appears in the done-story set from Phase 1, mark that **individual line**
for removal (not the whole section). Record each pruned line in the Phase 3 report as:

```
REMOVE line N: "[text]" — story ID [ID] is done per sprint-status.yaml
```

This is the only valid reason to modify a line inside the kept "Next session" section.

**Rule (both file types):** If in doubt, keep. Only remove when the entry clearly describes a past state or a resolved action item.

---

## Phase 3: Report Findings

Before making any changes, print a summary (omit sections for files that were skipped in Phase 1):

```
## Memory Prune — [Date]

### producer/MEMORY.md  [or shards/[file].md for sharded agents]
KEEP   [entry summary]
REMOVE [entry summary] — reason: resolved / superseded / completed
...

### technical-director/MEMORY.md
...

### creative-director/MEMORY.md
...

### lead-programmer/shards/[file].md  [one section per shard if sharded]
...

### session-state/active.md
KEEP   STATUS block + most recent "Next session" section
KEEP   Session extracts: [list which sprints kept]
REMOVE Session extracts: [list which removed] — sprint N, all stories closed
REMOVE Memory checkpoints: keeping last 3, removing [N] older ones
REMOVE Superseded "Next session" sections: [count]

Total: N entries/sections to remove across M files.
Estimated active.md reduction: ~NNN lines.
```

If total removals = 0: print "Nothing to prune — all entries are current." and skip to Phase 5.

Otherwise, ask: "May I write these removals to the files listed above?"

---

## Phase 4: Apply Removals

For each file with removals:
1. Read the file
2. Remove only the stale entries identified in Phase 3
3. Do not reformat, reorder, or rewrite any kept entries
4. Write the updated file

For `active.md` specifically: preserve the `<!-- STATUS -->` block, `<!-- QA RUN -->` and `<!-- QA-PLAN -->` comment lines (these are machine-readable markers), and the most recent `### Next session — pick up here` section. Everything pruned should be removed cleanly with no orphaned headers.

---

## Phase 5: Confirm

```
Memory prune complete.
Removed N entries from M files.
active.md: NNN → NNN lines.
Permanent decisions and active items preserved.
```

Verdict: COMPLETE

Recommended next: `/gate-check` or `/architecture-review` — memory is now current.
