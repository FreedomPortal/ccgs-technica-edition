# Skill Spec: /memory-prune

> **Category**: utility
> **Priority**: medium
> **Spec written**: 2026-05-26

## Skill Summary

`/memory-prune` scans four agent memory files and `production/session-state/active.md` for stale forward-looking entries (resolved "Next:", "Pending:", "Open:" items; superseded session extracts; duplicate memory checkpoints). It classifies every entry as permanent/active (keep) or stale (remove), presents a full report before touching any files, asks approval once, then applies removals. Never deletes permanent architectural decisions. Verdict is COMPLETE.

---

## Static Assertions

- [x] Frontmatter has all required fields (`name`, `description`, `argument-hint`, `user-invocable`, `allowed-tools`)
- [x] 2+ phase headings found (5 phases)
- [x] At least one verdict keyword present (COMPLETE)
- [x] `allowed-tools` includes Write/Edit: `"May I apply these removals?"` language present (Phase 3)
- [x] Next-step handoff present ("Recommended next: `/gate-check` or `/architecture-review`")

---

## Director Gate Checks

- **N/A**: Read/write utility skill with no director gates. Runs before gate skills, not alongside them.

---

## Test Cases

### Case 1: Happy Path — Stale entries found and pruned

**Fixture**:
- `.claude/agent-memory/producer/MEMORY.md` contains resolved "Pending: S2-13" (S2-13 is complete)
- `.claude/agent-memory/technical-director/MEMORY.md` has superseded open question (OQ-01: answered)
- `production/session-state/active.md` has 5 memory checkpoints (only last 3 should survive) and two old "Next session" sections

**Expected behavior**:
1. Phase 1 reads all 5 files (skips missing ones silently)
2. Phase 2 classifies entries: identifies 2 stale in producer, 1 in TD, 2 old checkpoints, 1 old "Next session" in active.md
3. Phase 3 prints full KEEP/REMOVE report before touching any file; asks "May I apply these removals?"
4. Phase 4 reads each file, removes only identified stale entries, writes updated file
5. Phase 5 confirms: "Removed N entries from M files. active.md: NNN → NNN lines."

**Assertions**:
- [ ] All 5 files read in Phase 1 (missing files skipped silently)
- [ ] KEEP/REMOVE report shown before any file write
- [ ] Single approval gate covers all removals (not one per file)
- [ ] Permanent entries (ADRs, design pillars, art direction) never removed
- [ ] STATUS block and most recent "Next session" section always preserved in active.md
- [ ] Verdict: COMPLETE reported at end

**Case Verdict**: PASS

---

### Case 2: Nothing to prune

**Fixture**:
- All agent memory entries are permanent architectural decisions or genuinely active open questions
- `active.md` has only the current STATUS block, one "Next session" section, and ≤3 memory checkpoints

**Expected behavior**:
1. Phase 2 classifies all entries as KEEP
2. Phase 3 reports total 0 entries to remove across all files
3. No approval gate needed; no writes performed
4. Phase 5 confirms 0 removals

**Assertions**:
- [ ] Reports 0 removals cleanly without error
- [ ] No file writes made when nothing to remove
- [ ] Skill still reaches Phase 5 (does not abort early)

**Case Verdict**: PASS

---

### Case 3: Missing memory files — skip silently

**Fixture**:
- `.claude/agent-memory/lead-programmer/MEMORY.md` does not exist
- `creative-director/MEMORY.md` does not exist
- `producer/MEMORY.md` and `technical-director/MEMORY.md` exist with stale entries

**Expected behavior**:
1. Phase 1 reads files that exist; skips missing ones without error
2. Report shows only sections for files that were read
3. Removals applied only to existing files

**Assertions**:
- [ ] Missing files skipped silently (no error message)
- [ ] Report only shows sections for files that were read
- [ ] No attempt to write to missing/non-existent memory files

**Case Verdict**: PASS

---

### Case 4: Edge Case — active.md STATUS block and machine-readable markers preserved

**Fixture**:
- `active.md` has `<!-- STATUS -->` block, `<!-- QA RUN -->` marker, and `<!-- QA-PLAN -->` marker
- Active.md also has 8 memory checkpoints and 4 old "Next session" sections

**Expected behavior**:
1. Phase 4 removes all but the last 3 memory checkpoints
2. Removes all but the most recent "Next session" section
3. `<!-- STATUS -->`, `<!-- QA RUN -->`, `<!-- QA-PLAN -->` lines preserved verbatim
4. No orphaned headers remain after pruning

**Assertions**:
- [ ] STATUS block preserved in all cases
- [ ] `<!-- QA RUN -->` and `<!-- QA-PLAN -->` markers preserved
- [ ] Most recent "Next session — pick up here" section never removed
- [ ] No orphaned section headers left after pruning

**Case Verdict**: PASS

---

### Case 5: Edge Case — Doubt rule (keep when uncertain)

**Fixture**:
- Agent memory has an entry: "Consider refactoring RCR to support animation layers"
- Entry is not clearly resolved (no "done" marker), not clearly active (no sprint reference)

**Expected behavior**:
1. Phase 2 classifies as ambiguous (not clearly stale)
2. Rule: "If in doubt, keep"
3. Entry appears as KEEP in report, not REMOVE

**Assertions**:
- [ ] Ambiguous entries classified as KEEP, not REMOVE
- [ ] "If in doubt, keep" rule applied consistently
- [ ] Only clearly resolved or superseded entries classified as REMOVE

**Case Verdict**: PASS

---

## Protocol Compliance

- [x] Presents full KEEP/REMOVE report before asking approval (Phase 3)
- [x] Single approval gate covers all file writes ("May I apply these removals?")
- [x] Ends with recommended next step (`/gate-check` or `/architecture-review`)
- [x] Does not modify any file without user approval

---

## Coverage Notes

- Phase 2 classification is Claude-evaluated (semantic, not regex) — hard to verify statically
- "If in doubt, keep" rule cannot be mechanically spec-tested; requires live run with ambiguous entries
- `active.md` line count reduction estimate in Phase 3 is informational; actual reduction verified in Phase 5
