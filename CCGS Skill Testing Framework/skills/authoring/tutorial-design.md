# Skill Spec: /tutorial-design
> **Category**: authoring
> **Priority**: low
> **Spec written**: 2026-06-11

## Skill Summary

`/tutorial-design` produces a structured tutorial design document (`design/tutorial/tutorial-design.md`) by orchestrating two subagents — `game-designer` for mechanic audit and classification, and `ux-designer` for teaching sequence, scaffolding strategy, skip/replay rules, and state machine sketch — across six sequential phases. Each phase presents its output to the user for confirmation before proceeding. The skill is full-authoring: it uses a multi-phase cycle, requires explicit write approval before touching disk, and outputs a self-contained design contract that downstream skills (`/dev-story`, `/player-docs`, `/ux-review`) depend on.

---

## Static Assertions
- [x] Frontmatter has all required fields (`name`, `description`, `model`, `argument-hint`, `user-invocable`, `allowed-tools`)
- [x] 2+ phase headings (6 phases: Phase 1 through Phase 6)
- [x] Verdict keyword present (`Verdict: COMPLETE — tutorial design written.`)
- [x] If Write/Edit in allowed-tools: "May I write" language present (Phase 6: `"May I write \`design/tutorial/tutorial-design.md\`? [Y/N]"`)
- [x] Next-step handoff present (Phase 6 completion block lists `/dev-story tutorial`, `/player-docs help-text`, `/ux-review`)

---

## Director Gate Checks

N/A — no director gate language, no `--review` mode handling, and no `creative-director` or `technical-director` invocation appears in the skill. The `argument-hint` lists `[--review full|lean|solo]` in frontmatter but the skill body contains zero handling for this flag. No director gate runs at any mode threshold.

---

## Test Cases

### Case 1: Happy Path
**Fixture:** GDDs exist in `design/gdd/` covering a small game with 4 mechanics (e.g., movement, jump, attack, dodge). No pre-existing `design/tutorial/tutorial-design.md`.

**Expected behavior:**
- Phase 1: `game-designer` subagent spawned, returns mechanic table (4 rows). Table presented to user.
- Phase 2: `ux-designer` spawned with table, returns ordered segment list. User asked `"Does this teaching order match your intent? [Y/E to edit/N to restart]"`. User replies Y.
- Phase 3: `ux-designer` spawned, returns scaffolding method per mechanic. Presented. User confirms.
- Phase 4: `ux-designer` spawned, returns skip/replay/accessibility rules. Presented. User confirms.
- Phase 5: `ux-designer` spawned, returns state machine sketch. Presented.
- Phase 6: Skill asks `"May I write \`design/tutorial/tutorial-design.md\`? [Y/N]"`. User answers Y. File written to `design/tutorial/tutorial-design.md` using template at `.claude/docs/templates/tutorial-design.md`. Completion block printed with mechanic count, segment count, estimated time, forced-tutorial-moment count.
- Verdict line: `Verdict: COMPLETE — tutorial design written.`

**Assertions:**
- `game-designer` Task spawned exactly once (Phase 1)
- `ux-designer` Task spawned exactly four times (Phases 2, 3, 4, 5)
- User presented output after each phase before skill proceeds
- Write gated on explicit user `[Y/N]` in Phase 6
- Output file path is `design/tutorial/tutorial-design.md`
- Completion block includes all four summary fields (mechanics count, segments count, estimated time, forced-tutorial-moment count)
- Forced-tutorial-moment flagged if count > 3
- Next-step block references all three downstream skills

**Verdict:** PASS

---

### Case 2: User Rejects Teaching Order (Phase 2 Edit Path)
**Fixture:** Same as Case 1. After Phase 2 output is presented, user responds `E` (edit).

**Expected behavior:**
- Skill prompts user to specify changes to the teaching order.
- User provides revised ordering (e.g., swap two segments).
- Skill revises the sequence per user input.
- Skill continues to Phase 3 with the revised sequence, not the original.

**Assertions:**
- Skill does not proceed to Phase 3 before incorporating user-requested edits
- Revised sequence (not original) is passed to Phase 3 `ux-designer` Task call
- No file write occurs during Phase 2

**Verdict:** PASS (if edit branch is followed) / BLOCKED (if skill skips edit handling and proceeds directly)

---

### Case 3: User Responds N to Teaching Order (Restart Path)
**Fixture:** Same as Case 1. User answers `N` to Phase 2 confirmation.

**Expected behavior:**
- Skill text states the instruction: `"If edit: user specifies changes; revise order."` The `N` branch has no explicit instruction in the skill body.

**Note:** The skill specifies only two branches for Phase 2: `Y` (proceed) and `E` (edit/revise). The `N` option appears in the prompt string but has no documented handler. The skill says `"[Y/E to edit/N to restart]"` but the restart path is not specified.

**Assertions:**
- This is an undocumented path — the spec cannot assert expected behavior from written instructions
- Flag as a coverage gap: restart (`N`) behavior in Phase 2 is not specified in the skill

**Verdict:** BLOCKED (spec gap — `N` path behavior not written)

---

### Case 4: User Declines Write in Phase 6
**Fixture:** All five phases complete successfully. User answers `N` to `"May I write \`design/tutorial/tutorial-design.md\`? [Y/N]"`.

**Expected behavior:**
- Skill does not write the file.
- No directory creation occurs.
- The skill has no documented behavior for a `N` response in Phase 6 (no fallback, no draft-save, no retry prompt is specified in the skill body).

**Assertions:**
- `design/tutorial/tutorial-design.md` must not exist after a `N` response
- `design/tutorial/` directory must not be created
- Skill must not print the completion/verdict block (which is scoped to "After write")
- Flag as a coverage gap: the skill documents no graceful exit message or draft-save on write refusal

**Verdict:** PASS for no-write guarantee; note spec gap for post-refusal messaging

---

### Case 5: GDD Directory Empty or Missing
**Fixture:** `design/gdd/` does not exist or contains no GDD files.

**Expected behavior:**
- Phase 1 spawns `game-designer` with the brief to read all GDDs in `design/gdd/`.
- `game-designer` returns an empty or error result — no mechanics to audit.
- The skill's Phase 1 instruction is: "Collect output. Present mechanic table to user before proceeding."
- The skill has no written handler for a zero-row mechanic table or a missing GDD directory.

**Assertions:**
- Phase 1 output (empty table or error) must still be presented to user per the "Present mechanic table to user before proceeding" instruction
- Skill must not silently skip Phase 1 and proceed
- Flag as coverage gap: no explicit BLOCKED condition, no guidance for zero-mechanic case in the skill body

**Verdict:** BLOCKED (spec gap — behavior on empty/missing GDD input is not defined)

---

## Protocol Compliance
- [x] "May I write" before file writes — explicit in Phase 6: `"May I write \`design/tutorial/tutorial-design.md\`? [Y/N]"`
- [x] Presents findings before approval — each phase presents subagent output to user before proceeding; Phase 6 presents state machine before write prompt
- [x] Ends with next step — completion block explicitly lists `/dev-story tutorial`, `/player-docs help-text`, `/ux-review design/tutorial/tutorial-design.md`
- [x] No auto-create without approval — write and directory creation scoped to `On approval` in Phase 6

---

## Coverage Notes

| Metric | Status | Notes |
|--------|--------|-------|
| A1 | PASS | Six-phase cycle with user confirmation after every phase — section-by-section authoring loop |
| A2 | PASS | Single `"May I write?"` gate in Phase 6; full skill asks once before the combined write (appropriate — all phases feed one output file) |
| A3 | FAIL (spec gap) | No written instruction to detect if `design/tutorial/tutorial-design.md` already exists and offer section-level update; skill proceeds to write unconditionally on approval |
| A4 | N/A | No director gate logic present in skill body despite `--review` appearing in frontmatter argument-hint; flag as frontmatter/body mismatch |
| A5 | FAIL (spec gap) | No skeleton-first instruction — Phase 6 writes the complete file in one operation using the template; no incremental section-by-section write protocol |

**Summary:** `/tutorial-design` is a full authoring skill by output scope and phase structure. It satisfies A1 and A2 but does not satisfy A3 (no existing-file detection) or A5 (no skeleton-first pattern). A4 is not applicable because the skill body contains no director gate handling. The `--review` flag in frontmatter is unimplemented — this is a frontmatter/body mismatch worth flagging to the skill author.