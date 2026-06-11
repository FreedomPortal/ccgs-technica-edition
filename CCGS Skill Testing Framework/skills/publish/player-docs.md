# Skill Spec: /player-docs
> **Category**: publish
> **Priority**: low
> **Spec written**: 2026-06-11

## Skill Summary

`/player-docs` generates player-facing documentation from existing GDDs, UX specs, and balance docs in one of three modes: `manual` (authoritative reference for confused new players), `guide` (strategy tips for engaged players who want to advance), or `help-text` (in-game contextual strings catalogue, max 80 characters per string). The skill reads canonical project sources before generating any output, routes to `writer` and optionally `game-designer` subagents depending on mode, detects pre-existing output files and offers Update vs. Recreate, gates all writes behind explicit user approval on a per-section basis, and closes with a post-write summary including mode-specific next-step handoffs.

---

## Static Assertions
- [x] Frontmatter has all required fields — `name`, `description`, `model`, `argument-hint`, `user-invocable`, `allowed-tools` all present
- [x] 2+ phase headings — Phase 1 (Parse Mode), Phase 2 (Load Source Material), Phase 3 (Post-Write Summary), plus three named Mode sections
- [x] Verdict keyword present — "Verdict: COMPLETE — player documentation written." in Phase 3
- [x] If Write/Edit in allowed-tools: "May I write" language present — help-text mode has explicit "Ask: 'May I write the help text catalogue to...'" instruction; manual and guide modes gate writes per-section via "present to user for approval before writing to file"
- [x] Next-step handoff present — Phase 3 summary block lists distinct next steps for each mode

---

## Director Gate Checks

N/A — the skill does not explicitly invoke any director review agent or gate-check skill. The `game-designer` subagent in `guide` mode functions as an accuracy consultant, not a formal gate. The ux-designer note after `help-text` is an informational routing note, not a blocking gate.

---

## Test Cases

### Case 1: Happy Path — `manual` mode, GDDs present, no existing output file

**Fixture**
- `design/gdd/` contains at least two populated GDD files
- `docs/CONTEXT.md` exists with canonical terms
- `design/ux/` contains a UX spec
- `production/publishing/game-manual.md` does not exist

**Expected behavior**
1. Skill reads all GDDs, CONTEXT.md, and UX/HUD/control docs
2. No source gaps reported (all sections populated)
3. Pre-existing file check passes silently (no AskUserQuestion for existing file)
4. `writer` subagent spawned with GDD list and CONTEXT.md terms in brief
5. `game-designer` subagent consulted for accuracy check (per agent routing rule)
6. Sections presented to user one at a time, each requiring approval before proceeding
7. On final approval, `production/publishing/game-manual.md` written using template at `.claude/docs/templates/game-manual.md`
8. Phase 3 summary printed with mode = `manual`, next steps pointing to `/refine-copy` and non-designer reader check

**Assertions**
- PB1: GDDs and CONTEXT.md read before any output produced
- PB2: Write gated per-section behind user approval
- PB5: Output written to `production/publishing/game-manual.md` matching manual destination

**Verdict**: PASS

---

### Case 2: Failure/Blocked — `guide` mode invoked before final balance lock

**Fixture**
- Skill invoked with `guide` argument
- `design/gdd/` contains GDD stubs (minimal/empty system descriptions)
- No balance sim reports in `production/balance/`
- Stage is pre-Release (balance not finalized)

**Expected behavior**
1. Phase 2 loads GDDs and identifies stubs as source gaps
2. Skill lists gaps as "Source gaps — these sections will be incomplete." and does NOT stop
3. `game-designer` subagent spawned; produces advanced mechanics list from available (incomplete) material
4. `writer` subagent proceeds with caveat-flagged content
5. Phase 3 summary notes source gaps count > 0 and explicitly states: "Re-run after final balance lock; values may change"

**Assertions**
- Source gap detection is non-blocking — skill continues with available material
- Gap count surfaced in Phase 3 summary
- Phase 3 next-step for guide mode flags balance-lock dependency

**Verdict**: BLOCKED (incomplete output expected; not a crash — graceful degradation with gap reporting)

---

### Case 3: Mode Variant — `help-text` mode, output file already exists

**Fixture**
- `production/publishing/help-text.md` already exists
- `design/tutorial/tutorial-design.md` present with trigger contexts
- UX spec present in `design/ux/`

**Expected behavior**
1. Phase 2 detects existing `help-text.md` at target path
2. `AskUserQuestion` triggered: "A help-text file already exists at production/publishing/help-text.md. How would you like to proceed?" with options `Update` and `Recreate`
3. User selects `Update`
4. `writer` subagent spawned, generates table of help strings grouped by Workshop / Arena / Menus / Inventory / Other
5. Each string ≤ 80 characters; format is `| Trigger Context | Help String | Char Count | Max (80) |`
6. Skill asks: "May I write the help text catalogue to `production/publishing/help-text.md`?" before writing
7. After confirmed write, ux-designer routing note printed
8. Phase 3 summary with next steps: ux-designer placement review + `/localization-export`

**Assertions**
- PB4: Existing file detected, Update vs. Recreate offered — not silently overwritten
- PB2: Explicit "May I write" confirmation before write (directly stated in help-text mode)
- PB5: Output format is a structured table matching in-game string catalogue destination

**Verdict**: PASS

---

### Case 4: Edge Case — no mode argument provided

**Fixture**
- Skill invoked as `/player-docs` with no argument
- `$ARGUMENTS[0]` is empty/missing

**Expected behavior**
1. Phase 1 detects missing argument
2. `AskUserQuestion` fires with prompt: "Which player document do you want to generate?"
3. Three options presented: `[A] manual`, `[B] guide`, `[C] help-text` with descriptions
4. User selects an option; skill continues from Phase 2 with that mode

**Assertions**
- Skill does not default silently to any mode
- AskUserQuestion is the only permissible path when argument is absent
- All three options are listed with their descriptions as specified

**Verdict**: PASS (mode resolution works as fallback; no silent behavior)

---

### Case 5: Mode Variant — `guide` mode, `game-designer` subagent sequencing

**Fixture**
- Skill invoked with `guide` argument
- Populated GDDs including combat and balance sections
- Balance sim reports present in `production/balance/`

**Expected behavior**
1. Phase 2 reads GDDs, CONTEXT.md, and balance data/sim reports
2. `game-designer` subagent spawned FIRST (before `writer`) with brief requesting: advanced mechanics, dominant build archetypes, common beginner mistakes; output format `Mechanic | Why non-obvious | Strategic implication`
3. `writer` subagent spawned SECOND, receives game-designer output as input
4. Writer brief explicitly targets engaged players (2+ hours played), conversational tone
5. Six sections produced (Getting Started Tips through Advanced Techniques); each presented for approval before proceeding
6. Write to `production/publishing/strategy-guide.md` using template at `.claude/docs/templates/strategy-guide.md`

**Assertions**
- Agent sequencing enforced: game-designer output feeds writer input (not parallel)
- Each of the 6 sections gated behind per-section approval
- PB1: Balance data and sim reports read before content produced
- PB2: Write gated behind approval
- PB5: Output written to strategy-guide.md matching guide destination

**Verdict**: PASS

---

## Protocol Compliance
- [x] "May I write" before file writes — explicitly stated in help-text mode; manual and guide use per-section "present to user for approval before writing to file" phrasing
- [x] Presents findings before approval — source gaps listed before proceeding; each section presented before write; game-designer output surfaced before writer runs in guide mode
- [x] Ends with next step — Phase 3 summary block has mode-specific next steps for all three modes
- [x] No auto-create without approval — all three modes gate the final write; pre-existing file check triggers AskUserQuestion before any overwrite

---

## Coverage Notes

- **PB1** (reads from project sources): Covered by Phase 2 — GDDs, CONTEXT.md, and mode-specific docs (UX spec, balance data, tutorial design) all read before any subagent is spawned. Tested in Cases 1, 2, and 5.
- **PB2** (artifacts gated behind "May I write"): Covered. Help-text uses exact "May I write" phrasing (Case 3). Manual and guide use per-section approval before writing to file (Cases 1, 5). Not tested for a scenario where approval is denied — this is a gap; skill does not specify what happens if user rejects a section.
- **PB3** (no push to external platforms without confirmation): No external platform publishing in this skill. Output is written to local `production/publishing/` paths. N/A.
- **PB4** (detects existing file, offers Update vs. Recreate): Explicitly specified in Phase 2 for all three output paths. Tested in Case 3.
- **PB5** (output format matches destination): Manual → `game-manual.md` using `.claude/docs/templates/game-manual.md`; guide → `strategy-guide.md` using `.claude/docs/templates/strategy-guide.md`; help-text → structured table in `help-text.md`. Tested across Cases 1, 3, 5.

**Gap**: The skill specifies templates for manual and guide modes (`.claude/docs/templates/game-manual.md` and `.claude/docs/templates/strategy-guide.md`) but does not specify what the skill should do if those template files do not exist. No test case covers missing templates — this is an untested failure path.