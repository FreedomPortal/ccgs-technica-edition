# Skill Spec: /memory-shard

> **Category**: utility
> **Priority**: medium
> **Spec written**: 2026-06-05

## Skill Summary

Splits a flat agent MEMORY.md into topic shards stored in `shards/`, then rewrites MEMORY.md as a lightweight index with a shard-loading protocol. Handles three input states: flat MEMORY.md, already-sharded MEMORY.md (re-shard option), and multi-file loose .md directories (Phase 1b consolidation). Optionally promotes high-signal entries to project docs. All file writes gated behind Phase 3 approval.

---

## Static Assertions

- [x] Frontmatter has all required fields (`name`, `description`, `argument-hint`, `user-invocable`, `allowed-tools`)
- [x] 2+ phase headings found (Phases 1–5, plus Phase 1b)
- [x] Verdict keyword present: Phase 5 states `Verdict: **COMPLETE**`
- [x] `allowed-tools` includes Write — all writes gated behind Phase 3 "Proceed — write shards?" AskUserQuestion
- [x] Next-step handoff present: Phase 5 recommends `/memory-prune [agent]`

---

## Director Gate Checks

**N/A** — memory-shard operates on agent memory files, not game design or code. It does not trigger director agent panels.

---

## Test Cases

### Case 1: Happy Path — Flat MEMORY.md sharded into 3 topics

**Fixture**:
- Agent: `lead-programmer`
- `.claude/agent-memory/lead-programmer/MEMORY.md` exists (flat, 180 lines)
- 3 `##` header groups: `## Skill Conventions` (60 lines), `## Architecture Decisions` (80 lines), `## Coding Standards` (40 lines)
- No PROMOTE_CANDIDATES found
- User approves plan in Phase 3

**Expected behavior**:
1. Phase 1: detects flat MEMORY.md (no "Shard loading protocol"), routes to normal flow
2. Phase 2: reads MEMORY.md, parses 3 `##` groups, reports line counts
3. Phase 2: proposes shard names: `skills.md`, `architecture.md`, `coding-standards.md`
4. Phase 3: shows shard plan, no promotions — asks "Proceed?"
5. User approves
6. Phase 4: backs up original to `shards/_legacy-flat.md`
7. Phase 4: writes 3 shard files to `shards/`
8. Phase 4: rewrites MEMORY.md as index with shard table and loading protocol
9. Phase 5: verifies all shards ≤150 lines, reports token cost reduction
10. Verdict: **COMPLETE**

**Assertions**:
- [ ] Phase 1 correctly identifies flat (non-sharded) state
- [ ] All 3 `##` groups parsed with accurate line counts
- [ ] Proposed shard filenames are lowercase-hyphenated (no spaces)
- [ ] Phase 3 shows full plan before asking approval
- [ ] Backup written to `shards/_legacy-flat.md` before any other writes
- [ ] MEMORY.md contains "Shard loading protocol" header after rewrite
- [ ] Verdict COMPLETE shown

**Case Verdict**: PASS

---

### Case 2: Failure — No memory files found

**Fixture**:
- Agent: `game-designer`
- `.claude/agent-memory/game-designer/` directory does not exist or is empty

**Expected behavior**:
1. Phase 1: checks `AGENT_DIR` — no MEMORY.md, no loose files
2. Outputs ⛔ stop message: "No memory files found at [AGENT_DIR]. Create .claude/agent-memory/game-designer/MEMORY.md first."
3. Verdict: ABORTED

**Assertions**:
- [ ] Empty or missing agent directory handled without error
- [ ] ⛔ message shown with exact path and instruction to create MEMORY.md first
- [ ] Skill stops at Phase 1 — no further phases run
- [ ] No files written

**Case Verdict**: PASS

---

### Case 3: Already Sharded — Re-shard option offered

**Fixture**:
- Agent: `lead-programmer`
- `MEMORY.md` contains "Shard loading protocol" (already sharded)
- Existing shards: `shards/skills.md` (95 lines), `shards/architecture.md` (160 lines — oversized)

**Expected behavior**:
1. Phase 1: detects "Shard loading protocol" in MEMORY.md → already sharded
2. Displays info: "MEMORY.md is already in sharded index format."
3. AskUserQuestion: "Re-shard from scratch?"
4. User selects "yes — re-shard"
5. Phase 1 reads MEMORY.md index and all files in `shards/` (skipping `_legacy-flat.md`)
6. Phase 2: analyzes content — `architecture.md` at 160 lines prompts sub-split check
7. Proceeds with restructure

**Assertions**:
- [ ] Already-sharded state detected from "Shard loading protocol" string in MEMORY.md
- [ ] User offered choice to re-shard or abort — not auto-proceeding
- [ ] Re-shard reads all existing shard content before Phase 2
- [ ] `_legacy-flat.md` excluded from re-shard content read
- [ ] Oversized shard (architecture.md 160 lines) detected and sub-split attempted in Phase 2

**Case Verdict**: PASS

---

### Case 4: Multi-File Mode — Loose .md files consolidated

**Fixture**:
- Agent: `art-director`
- `MEMORY.md` does not exist
- Loose files: `style-refs.md` (45 lines), `asset-standards.md` (80 lines), `color-palette.md` (30 lines)
- State: loose files only (no MEMORY.md) → routes to Phase 1b

**Expected behavior**:
1. Phase 1: no MEMORY.md found, but 3 loose `.md` files exist → Phase 1b
2. Phase 1b: lists all files with line counts
3. AskUserQuestion: "Consolidate into sharded format?"
4. User approves
5. Phase 1b sets `SOURCE_FILES` = all 3 loose files
6. Phase 2: each file treated as a `##`-level group — all under 150 lines, promoted as-is
7. Phase 4: writes 3 shard files, creates MEMORY.md index
8. Phase 4: deletes original loose files from `AGENT_DIR` root after shards written
9. Phase 5: reports completion

**Assertions**:
- [ ] Phase 1b triggered when loose files exist without MEMORY.md
- [ ] File line counts displayed before asking for approval
- [ ] User confirmation required before consolidation
- [ ] Files under 150 lines promoted to shards as-is (no sub-splitting)
- [ ] Original loose files deleted from root after shard writes succeed
- [ ] All 3 original files present in consolidated `shards/_legacy-flat.md` backup

**Case Verdict**: PASS

---

### Case 5: Oversized Group — No sub-headers, flagged for manual split

**Fixture**:
- Agent: `narrative-director`
- MEMORY.md (flat): 2 `##` groups
  - `## Story Decisions` — 200 lines, no `###` sub-headers
  - `## World-Building Notes` — 60 lines

**Expected behavior**:
1. Phase 2: parses `## Story Decisions` at 200 lines
2. Checks for `###` sub-headers — none found
3. Phase 2 display: ⚠️ "Group 1 (Story Decisions) is 200 lines with no sub-headers — flag for manual split. Shard will be written as-is; prune stale entries first to reduce size."
4. Phase 3: shard plan shows `shards/story-decisions.md — 200 lines ⚠️ >150`
5. User approves plan
6. Phase 4: writes `story-decisions.md` at 200 lines (as-is — no split possible)
7. Phase 5: reports `story-decisions.md: 200 lines ⚠️ >150 — consider splitting`
8. Phase 5: recommends `/memory-shard narrative-director` again to restructure after manual prune

**Assertions**:
- [ ] Oversized group without `###` sub-headers flagged with ⚠️ in Phase 2 display
- [ ] Shard written as-is despite being oversized (no silent truncation)
- [ ] Phase 5 report flags the shard as >150 lines with recommendation
- [ ] Recommendation to run `/memory-shard` again shown after oversized shard written

**Case Verdict**: PASS

---

## Protocol Compliance

- [x] All writes gated behind Phase 3 "Proceed — write shards and apply promotions?" AskUserQuestion
- [x] Backup (`_legacy-flat.md`) written before any shard or index writes
- [x] Plan shown in full (shard list, sizes, promotions) before asking approval
- [x] Ends with `/memory-prune [agent]` recommendation
- [x] Multi-file consolidation (Phase 1b) also gated behind user confirmation

---

## Coverage Notes

- PROMOTE_CANDIDATES (entries suggested for promotion to `.claude/docs/`) not covered by any test case. The promotion flow (Phase 2 scanning, Phase 3 display, Phase 4 appending to doc file) is defined but untested here.
- The re-name shards prompt in Phase 3 (user can rename before write) is not tested.
- Phase 1b deletion of original loose files (`rm "$f"`) after writing shards is a destructive operation — backup to `_legacy-flat.md` should be verified to succeed before deletion. This ordering assumption is not validated by a test case.
- Promotion to docs targets (`technical-preferences.md`, `coding-standards.md`, ADRs) requires those files to exist — an empty project with no docs is an untested edge case.
