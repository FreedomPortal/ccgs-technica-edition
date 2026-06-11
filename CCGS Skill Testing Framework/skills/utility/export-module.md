# Skill Spec: /export-module
> **Category**: utility
> **Priority**: low
> **Spec written**: 2026-06-11

## Skill Summary

/export-module packages a named game system for reuse across projects. It performs read-only analysis of `src/` to locate source files, ADRs, GDD sections, and test files, then classifies every external dependency into one of three portability classes (Logic, Engine API, Project coupling). It presents a structured coupling report and pauses for user review before generating an extraction plan. On explicit approval, it writes copies (never moves) to `exports/modules/[system-name]/`, producing adapted source files, relevant docs, test files, a README, and an ADAPTER.md listing required integration stubs. Writes are strictly confined to `exports/modules/`; originals in `src/` are never modified.

---

## Static Assertions

- [ ] Frontmatter has all required fields
- [ ] 2+ phase headings
- [ ] Verdict keyword present
- [ ] If Write/Edit in allowed-tools: "May I write" language present
- [ ] Next-step handoff present

**Notes:**
- Frontmatter fields present: `name`, `description`, `model`, `argument-hint`, `user-invocable`, `allowed-tools`. All required fields covered.
- Phase headings: 6 phases (Phase 1 through Phase 6). Passes.
- Verdict: "Verdict: COMPLETE — module exported to `exports/modules/[system-name]/`." Present in Phase 6.
- Write is in `allowed-tools`. "May I write" language: Phase 4 asks "May I write this extraction to `exports/modules/[system-name]/`? [Y/N]" — present.
- Next-step handoff: Phase 6 Summary block contains explicit next-step branches (HIGH/MEDIUM/LOW portability) and an optional ADR follow-up recommendation.

---

## Director Gate Checks

N/A — the skill does not invoke any director-level review (no `/design-review`, `/architecture-review`, `/gate-check`, or review-mode reads appear anywhere in the skill text).

---

## Test Cases

### Case 1: Happy Path — High-Portability System

**Fixture:**
- `$ARGUMENTS[0]` = `economy`
- `src/` contains multiple files matching `economy`
- At least one matching ADR in `docs/architecture/`
- At least one matching GDD file in `design/gdd/`
- At least one matching test file in `tests/`
- No project-coupling dependencies found in boundary analysis
- Cached code-recon file exists at `docs/export/code-recon-economy.md` and is within 30 days

**Expected behavior:**
1. Phase 1: Locates source, ADR, GDD, and test files without prompting (argument provided).
2. Phase 1: Uses cached code-recon rather than spawning a subagent.
3. Phase 2: All dependencies classified as Logic or Engine API; zero project couplings.
4. Phase 3: Coupling report shows `[HIGH]` portability assessment. Pauses with AskUserQuestion offering Y/N/Edit. User selects `[A] Yes — proceed`.
5. Phase 4: Extraction plan generated with no adaptation entries. Asks "May I write this extraction to `exports/modules/economy/`?" User approves.
6. Phase 5: Source files written verbatim; docs extracted and written; tests written verbatim; README.md and ADAPTER.md generated.
7. Phase 6: Summary printed with `Portability: HIGH`, ADR coverage confirmed, next-step guidance says "copy src/ into target project, run tests."

**Assertions:**
- `exports/modules/economy/src/` contains copies (not stubs) of all candidate source files.
- `exports/modules/economy/docs/` contains ADR files and extracted GDD sections.
- `exports/modules/economy/tests/` contains test files.
- `exports/modules/economy/README.md` and `ADAPTER.md` exist.
- No files under `src/` were modified.
- Summary output contains "Verdict: COMPLETE".

**Verdict:** COMPLETE

---

### Case 2: Failure / Blocked — System Name Not Found

**Fixture:**
- `$ARGUMENTS[0]` = `teleporter`
- Glob `src/**/*teleporter*` returns zero results.
- Grep for `teleporter` in `src/` returns zero results.

**Expected behavior:**
1. Phase 1: Glob and grep both return empty sets.
2. Phase 1: Skill stops immediately with message: "No source files found for 'teleporter'. Check the system name and try again."
3. No boundary analysis, no report, no writes.

**Assertions:**
- No files written to `exports/modules/`.
- Error message matches the exact wording from the skill spec.
- Skill halts at Phase 1; does not proceed to Phase 2.

**Verdict:** BLOCKED

---

### Case 3: Mode Variant — No Argument Provided (Interactive Prompt)

**Fixture:**
- Invoked as `/export-module` with no arguments.
- `production/backlog.yaml` exists and contains epic entries including `inventory` and `combat`.

**Expected behavior:**
1. Phase 1: Detects no argument. Issues AskUserQuestion: "Which system do you want to export as a reusable module?" with options listing epics from `backlog.yaml` plus `[E] Enter name manually`.
2. User selects `inventory`.
3. Skill proceeds from Phase 1 source-file location onward using `inventory` as the system name.

**Assertions:**
- AskUserQuestion is used (not a hard-coded prompt or assumption).
- Options include backlog epics and a manual-entry option.
- After selection, behavior is identical to Case 1 from the source-location step onward.

**Verdict:** COMPLETE (after user provides system name)

---

### Case 4: Edge Case — Low-Portability System with User Choosing to Fix Couplings

**Fixture:**
- `$ARGUMENTS[0]` = `ui-manager`
- Source files found. Four or more project-coupling dependencies identified (e.g., hardcoded autoload names, scene paths referencing other systems).
- No cached code-recon; subagent spawned via Task to run `/code-recon ui-manager`.

**Expected behavior:**
1. Phase 1: No cache found at `docs/export/code-recon-ui-manager.md`. Spawns `lead-programmer` subagent via Task to run `/code-recon ui-manager`.
2. Phase 2: Classifies 4+ dependencies as Project coupling.
3. Phase 3: Coupling report shows `[LOW]` portability. Pauses with AskUserQuestion. User selects `[C] I want to fix the couplings first — pause`.
4. Phase 3: Skill stops. Tells user which files to edit and which couplings to resolve. Instructs them to re-run `/export-module` after fixing.
5. No extraction plan generated; no files written.

**Assertions:**
- Portability assessment in report is `[LOW]` (4+ project couplings).
- `[C]` path correctly halts execution before Phase 4.
- User receives file-by-file coupling detail with suggested abstraction approaches.
- No writes to `exports/modules/`.
- Subagent was spawned (no stale cache available).

**Verdict:** BLOCKED (user-directed pause; re-run after fixing)

---

### Case 5: Edge Case — ADR-Less System

**Fixture:**
- `$ARGUMENTS[0]` = `audio-manager`
- Source files found in `src/`.
- Grep of `docs/architecture/ADR-*.md` returns zero matches for `audio-manager`.
- GDD section found. Test files found.
- 1–3 project couplings (MEDIUM portability). User approves extraction.

**Expected behavior:**
1. Phase 1: ADR grep returns zero matches. System noted as ADR-less.
2. Phase 3: Coupling report includes the warning block: "WARNING — No ADRs found. Exported module will have no documented contracts. Run /architecture-decision first for a complete export."
3. Phase 3: User approves (`[A] Yes — proceed`).
4. Phase 4: Extraction plan generated. User approves write.
5. Phase 5: Source files written (adaptation stubs inserted for project couplings). GDD sections, tests, README, and ADAPTER.md written. No ADRs copied (none exist).
6. Phase 6: Summary shows `ADR coverage: WARNING: no ADRs`. Next step includes: "Run /architecture-decision for audio-manager to add contract docs to future exports."

**Assertions:**
- No ADR files appear under `exports/modules/audio-manager/docs/`.
- README.md `## Architecture` section notes no governing ADRs or is absent.
- Phase 6 summary contains the ADR-less follow-up recommendation.
- Adapted source files contain `# ADAPTER:` stubs and `# TODO: inject` headers.
- ADAPTER.md lists all project-coupling integration points.

**Verdict:** COMPLETE (with advisory warning)

---

## Protocol Compliance

- [ ] "May I write" before file writes — Phase 4 explicitly asks "May I write this extraction to `exports/modules/[system-name]/`? [Y/N]" before any Write calls in Phase 5.
- [ ] Presents findings before approval — Phase 3 coupling report is presented in full before the Phase 3 approval gate; Phase 4 extraction plan is generated and displayed before the Phase 4 write approval.
- [ ] Ends with next step — Phase 6 provides portability-conditional next steps and an optional ADR follow-up.
- [ ] No auto-create without approval — Phase 4 is explicitly "do not write files yet"; all writes gated on user `[Y]`.

---

## Coverage Notes

**U1 — Static checks:** All 7 static assertions pass per the skill text. Frontmatter complete; 6 phase headings present; Verdict present in Phase 6; "May I write" language present in Phase 4; next-step handoff present in Phase 6.

**U2 — Director gate:** Not applicable. The skill contains no director gate trigger and no review-mode logic. Case 5 tests the most structurally distinctive variant (ADR-less path) rather than a director gate that does not exist.

**Gap note:** The skill spawns a `lead-programmer` subagent via Task when no cached code-recon exists. This subagent call is covered in Case 4 but cannot be fully exercised in a static fixture test — integration testing would need to mock the `/code-recon` output or verify the Task call is issued with the correct arguments.