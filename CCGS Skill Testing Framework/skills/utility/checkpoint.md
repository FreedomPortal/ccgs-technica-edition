# Skill Spec: /checkpoint

> **Category**: utility
> **Priority**: medium
> **Spec written**: 2026-05-26

## Skill Summary

`/checkpoint` flushes session discoveries to the appropriate agent memory files and appends a checkpoint entry to `production/session-state/active.md`. It scans the current conversation for cross-session-relevant facts (comparables, design decisions, technical constraints, production facts, user preferences), routes each discovery to the correct memory file, asks once for approval covering all writes, then writes immediately. Verdict: COMPLETE.

---

## Static Assertions

- [x] Frontmatter has all required fields (`name`, `description`, `argument-hint`, `user-invocable`, `allowed-tools`)
- [x] 2+ phase headings found (5 phases)
- [x] At least one verdict keyword present (COMPLETE)
- [x] `allowed-tools` includes Write/Edit: `"May I write"` language present (Phase 3: "May I write these [N] discoveries to agent memory?")
- [x] Next-step handoff present ("Recommended next: `/continue` to review pending tasks, or `/clear` + `/compact`")

---

## Director Gate Checks

- **N/A**: Memory management utility. No director gates.

---

## Test Cases

### Case 1: Happy Path — Discoveries found, routed and written

**Fixture**:
- Session discussed: a new comparable game identified (creative), an ADR decision confirmed (technical), a scope change (production)
- All 3 target memory files exist
- `production/session-state/active.md` exists

**Expected behavior**:
1. Phase 1 scans session; finds 3 discoveries across 3 categories
2. Phase 2 routes: comparable → `creative-director/MEMORY.md`, ADR → `technical-director/MEMORY.md`, scope change → `producer/MEMORY.md`
3. Phase 3 lists all discoveries and routing; asks "May I write these 3 discoveries to agent memory?" — one question covers all
4. On approval: reads each file, adds discovery to appropriate section, writes immediately (does not batch)
5. Phase 4 appends checkpoint entry to active.md with timestamp and discovery summaries
6. Phase 5 confirms: "3 discoveries written to agent memory. These facts will survive a crash or compaction."

**Assertions**:
- [ ] Single approval covers all writes (not one AskUserQuestion per file)
- [ ] Each discovery written to correct memory file per routing table
- [ ] Writes happen immediately after approval, not batched at end
- [ ] Checkpoint entry appended to active.md with timestamp
- [ ] Verdict: COMPLETE reported

**Case Verdict**: PASS

---

### Case 2: No discoveries found

**Fixture**:
- Session covered only implementation work with no new design decisions, comparables, constraints, or preferences

**Expected behavior**:
1. Phase 1 scans session; finds nothing cross-session-relevant
2. Reports: "No new discoveries — memory is current."
3. Skill does not ask for approval; no writes performed
4. Phase 5 still confirms completion

**Assertions**:
- [ ] "No new discoveries — memory is current." reported
- [ ] No AskUserQuestion triggered
- [ ] No files written
- [ ] Skill still reaches Phase 5 cleanly

**Case Verdict**: PASS

---

### Case 3: Routing correctness — correct file per category

**Fixture**:
- Session discovered: user prefers terse output (workflow preference) and a forbidden GDScript pattern (code standard)

**Expected behavior**:
1. Phase 2 routes workflow preference → user memory at `~/.claude/projects/[slug]/memory/`
2. Routes GDScript pattern → `lead-programmer/MEMORY.md`
3. Phase 3 confirms routing in the discovery list before asking approval

**Assertions**:
- [ ] Workflow preference routed to user memory (not agent memory)
- [ ] Code standard routed to `lead-programmer/MEMORY.md`
- [ ] Routing table applied correctly for all 5 discovery categories
- [ ] Discovery list shown to user before approval

**Case Verdict**: PASS

---

### Case 4: Edge Case — Target memory file does not exist

**Fixture**:
- Design decision found that routes to `creative-director/MEMORY.md`
- `creative-director/MEMORY.md` does not exist

**Expected behavior**:
1. Phase 3 still asks for approval
2. Phase 4: skill creates the file (or parent directory) and writes the discovery
3. Does not skip the discovery because the file is missing

**Assertions**:
- [ ] Missing memory file created rather than skipping the discovery
- [ ] Written file contains the discovery in appropriate section format
- [ ] No error thrown for missing file

**Case Verdict**: PASS

---

### Case 5: Edge Case — active.md does not exist for Phase 4

**Fixture**:
- Discoveries found and approved for writing
- `production/session-state/active.md` does not exist (fresh project)

**Expected behavior**:
1. Phases 3 and 4 write to agent memory files normally
2. Phase 4 attempts to append checkpoint to active.md
3. Creates active.md (and `production/session-state/` directory if needed) with the checkpoint entry

**Assertions**:
- [ ] active.md created if missing (not skipped)
- [ ] Checkpoint entry written to new file
- [ ] Memory file writes not blocked by missing active.md

**Case Verdict**: PASS

---

## Protocol Compliance

- [x] Single `"May I write"` covers all file writes (one approval gate, not per-file)
- [x] Discovery list presented to user before approval
- [x] Ends with recommended next step (`/continue` or `/clear` + `/compact`)
- [x] Does not write to any file without user approval

---

## Coverage Notes

- Phase 1 discovery scan is Claude-evaluated (conversational context) — cannot be statically verified
- "Write immediately — do not batch" is a behavioral instruction; compliance depends on live execution
- User memory path derivation follows same slug logic as `/continue` — Windows path handling applies
