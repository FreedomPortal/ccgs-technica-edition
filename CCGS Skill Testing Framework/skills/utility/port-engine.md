# Skill Spec: /port-engine
> **Category**: utility
> **Priority**: low
> **Spec written**: 2026-06-11

## Skill Summary

`/port-engine` generates a static migration guide for moving a game project from one engine to another. It accepts source and target engine arguments (auto-detecting source from `technical-preferences.md` if omitted), scans `src/` for engine-specific API patterns using predefined grep heuristics, crosswalks all ADRs for engine compatibility notes, classifies every discovered API as Direct/Adaptation/Rethink, produces per-file and per-system effort estimates, and writes the final guide to `docs/porting/[source]-to-[target]-[YYYY-MM-DD].md` after explicit user approval. The skill is read-only with respect to `src/`; the porting guide is its only output.

---

## Static Assertions

- [x] Frontmatter has all required fields — `name`, `description`, `model`, `argument-hint`, `user-invocable`, `allowed-tools` all present
- [x] 2+ phase headings — Phases 1 through 6 present (six headings)
- [x] Verdict keyword present — "Verdict: COMPLETE" in Recommended Next Steps section
- [x] If Write/Edit in allowed-tools: "May I write" language present — Phase 6: `Ask: "May I write docs/porting/[source]-to-[target]-[date].md? [Y/N]"`
- [x] Next-step handoff present — Recommended Next Steps section lists `/refresh-docs` and `/architecture-decision` as follow-ons

---

## Director Gate Checks

N/A — The skill contains no director gate, no review-mode read, and spawns no reviewer agent. Case 5 will cover the most relevant non-gate variant instead.

---

## Test Cases

### Case 1: Happy Path — Supported pair, src/ present, ADRs present

**Fixture:**
- Arguments: `godot unity`
- `technical-preferences.md` exists with `Engine: Godot`
- `src/` contains GDScript files with `get_node(`, `signal`, `@export`, `Autoloads` references
- `docs/architecture/ADR-0001.md` exists with `## Engine Compatibility` section
- `docs/engine-reference/unity/` does not exist (no reference snapshot)
- User approves write in Phase 6

**Expected behavior:**
1. Phase 1: parses `godot` as source, `unity` as target; no prompts needed; notes missing Unity engine reference
2. Phase 2: scans `src/`; reports hit counts per category (e.g., Scene/node access: N occurrences across M files); zero-match categories omitted
3. Phase 3: reads ADR-0001.md; reports 1 ADR with Engine Compatibility field; 0 audit gaps
4. Phase 4: maps each found API to Unity equivalent with Direct/Adaptation/Rethink classification per the Godot→Unity table; `Autoloads` classified Rethink
5. Phase 5: computes per-file day estimates; sums to total range [low]d–[high]d; groups by system
6. Phase 6: prompts "May I write docs/porting/godot-to-unity-[date].md?"; on Y writes guide with all sections
7. Verdict: COMPLETE emitted; next steps listed

**Assertions:**
- Phase 1 emits the "No engine reference found" warning for unity
- Phase 2 output format matches `[Category]: N occurrences across M files / Files: [list]`
- Phase 3 reports 0 audit gaps (no "MEDIUM" confidence penalty)
- Rethink APIs (Autoloads, `@rpc`, GDScript) flagged in Known Risks
- Output file path matches `docs/porting/godot-to-unity-YYYY-MM-DD.md`
- Confidence rated MEDIUM (< 20% ADRs missing Engine Compatibility)

**Verdict:** PASS if guide is written with all required sections and effort estimate range is present.

---

### Case 2: Failure/Blocked — No `src/` directory

**Fixture:**
- Arguments: `godot unity`
- `src/` directory does not exist in project root

**Expected behavior:**
- Phase 2 encounters no source files
- Graceful Degradation table entry fires: skill stops and surfaces "No source files found. Check working directory."
- No further phases run; no write prompt issued

**Assertions:**
- Skill halts at Phase 2 with the exact message from the Graceful Degradation table
- No `docs/porting/` file is created
- No AskUserQuestion for write approval is shown

**Verdict:** PASS if skill stops with the documented error message and produces no output file.

---

### Case 3: Mode Variant — Missing target argument, source auto-detected, no ADRs

**Fixture:**
- Arguments: (none — invoked as `/port-engine` with no args)
- `technical-preferences.md` exists: `Engine: Godot`
- `src/` exists with GDScript files
- `docs/architecture/` directory exists but contains no `ADR-*.md` files
- User answers "Unity" to the target engine prompt
- User approves write

**Expected behavior:**
1. Phase 1: target missing → `AskUserQuestion` "Which engine are you porting to?" with options Godot/Unity/Unreal/Other
2. Phase 1: source auto-detected from `technical-preferences.md` as `godot`; no source prompt needed
3. Phase 3: no ADRs found → skips ADR crosswalk; notes "No ADRs — porting guide is code-only. Consider running /architecture-review first."
4. Phase 6: proceeds to write guide; ADR Porting Notes section absent or contains the no-ADRs note

**Assertions:**
- `AskUserQuestion` fired for target, not for source
- ADR crosswalk note matches the Graceful Degradation table wording exactly
- Guide header does not show an ADR audit-gap WARNING (since there are no ADRs, not missing fields)
- Confidence rated MEDIUM (0 ADRs means 0% missing, which is < 20% threshold)

**Verdict:** PASS if skill prompts for target only, skips ADR crosswalk with correct note, and writes complete guide.

---

### Case 4: Edge Case — Unsupported engine pair

**Fixture:**
- Arguments: `godot pygame`
- `src/` exists with GDScript files
- No ADRs

**Expected behavior:**
1. Phase 1: normalizes source as `godot`; target `pygame` is not in the supported pairs table
2. Skill notes "unsupported pair" in report header per the Supported Engine Pairs section ("Other pairs: proceed with best-effort API mapping; note unsupported pair in report header")
3. Phase 4: all API mappings produced but marked `[UNVERIFIED]` — no reference table for this pair
4. Phase 5: effort estimate still computed using the same formula
5. Phase 6: write prompt fires normally; guide header contains the unsupported-pair notice

**Assertions:**
- Report header explicitly notes the unsupported pair
- Every row in the API Crosswalk table carries `[UNVERIFIED]` in the Notes column
- No phase is skipped due to the unsupported pair
- Write prompt still fires; user can still approve

**Verdict:** PASS if guide is written, unsupported-pair is noted in header, and all API rows are marked [UNVERIFIED].

---

### Case 5: Most Relevant Variant — User denies write approval in Phase 6

**Fixture:**
- Arguments: `unity godot`
- `src/` contains C# Unity files
- 2 ADRs with Engine Compatibility sections
- User answers "N" to write prompt in Phase 6

**Expected behavior:**
- Phases 1–5 complete normally; full analysis is produced in conversation
- Phase 6 prompts "May I write docs/porting/unity-to-godot-[date].md? [Y/N]"
- User answers N
- Skill does not write the file; does not create `docs/porting/` directory
- Next steps / Verdict may still be surfaced to the user in conversation

**Assertions:**
- No file is written to `docs/porting/` after N response
- Skill does not retry or auto-create the file
- Skill respects the denial without error

**Verdict:** PASS if no file is created on denial and skill terminates cleanly.

---

## Protocol Compliance

- [x] "May I write" before file writes — Phase 6 explicitly asks before writing the porting guide
- [x] Presents findings before approval — Phases 1–5 complete all analysis before the Phase 6 write gate
- [x] Ends with next step — Recommended Next Steps section with `/refresh-docs` and `/architecture-decision` handoffs
- [x] No auto-create without approval — `docs/porting/` directory and guide file are only created after Y response

---

## Coverage Notes

**U1 — All 7 static checks:** All pass. Frontmatter complete; 6 phase headings; Verdict keyword present; "May I write" language present matching Write in allowed-tools; next-step handoff present.

**U2 — Director gate / review-mode:** N/A. The skill does not spawn any director gate or read review-mode. No U2 coverage required.

**Gap:** The skill reads `production/stage.txt` in Phase 1 as a fallback for source engine detection, but this file is not tested explicitly. If a tester wants deeper coverage, a Case 3 variant where `technical-preferences.md` has no Engine field and `stage.txt` provides the hint would exercise that secondary detection path.