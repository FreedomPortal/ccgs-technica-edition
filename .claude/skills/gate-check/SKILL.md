---
name: gate-check
description: "Validate readiness to advance between development phases. Produces a PASS/CONCERNS/FAIL verdict with specific blockers and required artifacts. Use when user says 'are we ready to move to X', 'can we advance to production', 'check if we can start the next phase', 'pass the gate'."
argument-hint: "[target-phase: prototype | systems-design | technical-setup | pre-production | vertical-slice | production | polish | release] [--review full|lean|solo] [--scope milestone-name]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Bash, Write, Task, AskUserQuestion
model: opus
---

# Phase Gate Validation

> **Tip:** Run `/memory-prune` before this skill. Stale "Pending" or "Next" entries
> in agent memory can cause false blockers or missed resolutions in the verdict.

This skill validates whether the project is ready to advance to the next development
phase. It checks for required artifacts, quality standards, and blockers.

**Distinct from `/project-stage-detect`**: That skill is diagnostic ("where are we?").
This skill is prescriptive ("are we ready to advance?" with a formal verdict).

## Production Stages (9)

The project progresses through these stages:

1. **Concept** — Brainstorming, game concept document
2. **Prototype** — Throwaway mechanic validation; PROCEED verdict required to advance
3. **Systems Design** — Mapping systems, writing GDDs
4. **Technical Setup** — Engine config, architecture decisions
5. **Pre-Production** — Design docs, art bible, architecture, UX specs, epics
6. **Vertical Slice** — Production-quality core loop build; personal playtest required to advance
7. **Production** — Feature development (Epic/Feature/Task tracking active)
8. **Polish** — Performance, playtesting, bug fixing
9. **Release** — Launch prep, certification

**When a gate passes**, write the new stage name to `production/stage.txt`
(single line, e.g. `Production`). This updates the status line immediately.

---

## 1. Parse Arguments

**Target phase:** `$ARGUMENTS[0]` (blank = auto-detect current stage, then validate next transition)

Also resolve the review mode (once, store for all gate spawns this run):
1. If `--review [full|lean|solo]` was passed → use that
2. Else read `production/review-mode.txt` → use that value
3. Else → default to `lean`

Note: in `solo` mode, director spawns (CD-PHASE-GATE, TD-PHASE-GATE, PR-PHASE-GATE, AD-PHASE-GATE) are skipped — gate-check becomes artifact-existence checks only. In `lean` mode, all four directors still run (phase gates are the purpose of lean mode).

**Active milestone scope** (scope-awareness, optional):
1. If `--scope [name]` was passed → use that milestone name
2. Else read `production/milestones/active.txt` → use that value
3. Else → no milestone scope context (deferred section omitted from output)

If a milestone name is resolved: read `production/milestones/definitions/[name].md` for its In Scope and Out of Scope sections. Store for use in Section 5 output.

- **With argument**: `/gate-check production` — validate readiness for that specific phase
- **No argument**: Auto-detect current stage using the same heuristics as
  `/project-stage-detect`, then **confirm with the user before running**:

  Use `AskUserQuestion`:
  - Prompt: "Detected stage: **[current stage]**. Running gate for [Current] → [Next] transition. Is this correct?"
  - Options:
    - `[A] Yes — run this gate`
    - `[B] No — pick a different gate` (if selected, show a second widget listing all gate options: Concept → Prototype, Prototype → Systems Design, Systems Design → Technical Setup, Technical Setup → Pre-Production, Pre-Production → Vertical Slice, Vertical Slice → Production, Production → Polish, Polish → Release)
  
  Do not skip this confirmation step when no argument is provided.

---

## 2. Phase Gate Definitions

### Gate: Concept → Prototype

**Required Artifacts:**
- [ ] `design/gdd/game-concept.md` exists with at least: game idea, target feeling, one core mechanic described
- [ ] A falsifiable hypothesis can be formed from the concept (e.g., "If the player does X, they will feel Y")

**Recommended (not blocking):**
- [ ] Game pillars defined — can be refined after prototype, but early clarity helps
- [ ] `/brainstorm` session completed and output saved to `design/gdd/game-concept.md`

**Quality Checks:**
- [ ] Concept is specific enough to prototype — not "make a fun game" but "test whether [mechanic] feels right"
- [ ] Riskiest assumption in the concept is identified

---

### Gate: Prototype → Systems Design

**Required Artifacts:**
- [ ] `design/gdd/game-concept.md` exists and has content
- [ ] Game pillars defined (in concept doc or `design/gdd/game-pillars.md`)
- [ ] Visual Identity Anchor section exists in `design/gdd/game-concept.md` (from brainstorm Phase 4 art-director output)
- [ ] Prototype REPORT.md exists in `prototypes/` with a PROCEED verdict (`/prototype` output)

**Recommended (not blocking):**
- [ ] Multiple prototype variants attempted if first returned PIVOT — natural selection between concepts produces better results than iterating one concept

**Publishing Readiness Checks:**
- [ ] Market research done (`production/publishing/market-research.md` exists) — run `/market-research`
- [ ] Initial positioning drafted (genre, hook, target platforms documented)
- [ ] Studio name + domains registered or planned
- [ ] `/marketing-plan` has been run (publishing roadmap exists at `production/publishing/publishing-roadmap.md`)

**Quality Checks:**
- [ ] Game concept has been reviewed (`/design-review` verdict not MAJOR REVISION NEEDED)
- [ ] Core loop is described and understood, informed by prototype learnings
- [ ] Target audience is identified
- [ ] Visual Identity Anchor contains a one-line visual rule and at least 2 supporting visual principles
- [ ] Prototype report findings are reflected in `design/gdd/game-concept.md` (tuning knobs, edge cases, or mechanic adjustments noted)

---

### Gate: Systems Design → Technical Setup

**Required Artifacts:**
- [ ] Systems index exists at `design/gdd/systems-index.md` with at least MVP systems enumerated
- [ ] All MVP-tier GDDs exist in `design/gdd/` and individually pass `/design-review`
- [ ] A cross-GDD review report exists in `design/gdd/` (from `/review-all-gdds`)

**Quality Checks:**
- [ ] All MVP GDDs pass individual design review (8 required sections, no MAJOR REVISION NEEDED verdict)
- [ ] `/review-all-gdds` verdict is not FAIL (cross-GDD consistency and design theory checks pass)
- [ ] All cross-GDD consistency issues flagged by `/review-all-gdds` are resolved or explicitly accepted
- [ ] System dependencies are mapped in the systems index and are bidirectionally consistent
- [ ] MVP priority tier is defined
- [ ] No stale GDD references flagged (older GDDs updated to reflect decisions made in later GDDs)

---

### Gate: Technical Setup → Pre-Production

**Required Artifacts:**
- [ ] Engine chosen (CLAUDE.md Technology Stack is not `[CHOOSE]`)
- [ ] Technical preferences configured (`.claude/docs/technical-preferences.md` populated)
- [ ] Art bible exists at `design/art/art-bible.md` with at least Sections 1–4 (Visual Identity Foundation)
- [ ] At least 3 Architecture Decision Records in `docs/architecture/` covering
      Foundation-layer systems (scene management, event architecture, save/load)
- [ ] Engine reference docs exist in `docs/engine-reference/[engine]/`
- [ ] Test framework initialized: `tests/unit/` and `tests/integration/` directories exist
- [ ] CI/CD test workflow exists at `.github/workflows/tests.yml` (or equivalent)
- [ ] At least one example test file exists to confirm the framework is functional
- [ ] Master architecture document exists at `docs/architecture/architecture.md`
- [ ] Architecture traceability index exists at `docs/architecture/requirements-traceability.md`
- [ ] `/architecture-review` has been run (a review report file exists in `docs/architecture/`)
- [ ] `design/accessibility-requirements.md` exists with accessibility tier committed
- [ ] `design/ux/interaction-patterns.md` exists (pattern library initialized, even if minimal)

**Quality Checks:**
- [ ] Architecture decisions cover core systems (rendering, input, state management)
- [ ] Technical preferences have naming conventions and performance budgets set
- [ ] Accessibility tier is defined and documented (even "Basic" is acceptable — undefined is not)
- [ ] At least one screen's UX spec started (often the main menu or core HUD is designed during Technical Setup)
- [ ] All ADRs have an **Engine Compatibility section** with engine version stamped
- [ ] All ADRs have a **GDD Requirements Addressed section** with explicit GDD linkage
- [ ] No ADR references APIs listed in `docs/engine-reference/[engine]/deprecated-apis.md`
- [ ] All HIGH RISK engine domains (per VERSION.md) have been explicitly addressed
      in the architecture document or flagged as open questions
- [ ] Architecture traceability matrix has **zero Foundation layer gaps**
      (all Foundation requirements must have ADR coverage before Pre-Production)

**ADR Circular Dependency Check**: For all ADRs in `docs/architecture/`, read each ADR's
"ADR Dependencies" / "Depends On" section. Build a dependency graph (ADR-A → ADR-B means
A depends on B). If any cycle is detected (e.g. A→B→A, or A→B→C→A):
- Flag as **FAIL**: "Circular ADR dependency: [ADR-X] → [ADR-Y] → [ADR-X].
  Neither can reach Accepted while the cycle exists. Remove one 'Depends On' edge to
  break the cycle."

**Engine Validation** (read `docs/engine-reference/[engine]/VERSION.md` first):
- [ ] ADRs that touch post-cutoff engine APIs are flagged with Knowledge Risk: HIGH/MEDIUM
- [ ] `/architecture-review` engine audit shows no deprecated API usage
- [ ] All ADRs agree on the same engine version (no stale version references)

---

### Gate: Pre-Production → Vertical Slice

**Required Artifacts:**
- [ ] Art bible is complete (all 9 sections) and AD-ART-BIBLE sign-off verdict is recorded in `design/art/art-bible.md`
- [ ] Entity inventory exists at `design/assets/entity-inventory.md` (recommended — run `/asset-spec` with no arguments to generate collaboratively from GDDs + art bible)
- [ ] Taste-gate templates locked for all asset types planned for batch AI image generation (`design/art/prompt-templates/[type]-template.md` with `Status: LOCKED`) — **recommended, not blocking**; if batch AI generation is planned but templates are absent, surface as CONCERNS
- [ ] All MVP-tier GDDs from systems index are complete
- [ ] Master architecture document exists at `docs/architecture/architecture.md`
- [ ] At least 3 ADRs covering Foundation-layer decisions exist in `docs/architecture/`
- [ ] All Foundation and Core layer ADRs have status `Accepted` (not `Proposed`) — stories cannot be unblocked until their governing ADR is accepted
- [ ] Control manifest exists at `docs/architecture/control-manifest.md`
      (generated by `/create-control-manifest` from Accepted ADRs)
- [ ] Epics defined in `production/epics/` with at least Foundation and Core
      layer epics present (use `/create-epics layer: foundation` and
      `/create-epics layer: core` to create them, then `/create-stories [epic-slug]`
      for each epic)
- [ ] UX specs exist for key screens: main menu, core gameplay HUD (at `design/ux/`), pause menu
- [ ] HUD design document exists at `design/ux/hud.md` (if game has in-game HUD)
- [ ] All key screen UX specs have passed `/ux-review` (verdict APPROVED or NEEDS REVISION accepted)

**Quality Checks:**
- [ ] UX specs cover all UI Requirements sections from MVP-tier GDDs
- [ ] Interaction pattern library documents patterns used in key screens
- [ ] Accessibility tier from `design/accessibility-requirements.md` is addressed in all key screen UX specs
- [ ] Architecture document has no unresolved open questions in Foundation or Core layers
- [ ] All ADRs have Engine Compatibility sections stamped with the engine version
- [ ] All ADRs have ADR Dependencies sections (even if all fields are "None")
- [ ] Manual validation confirms GDDs + architecture + epics are coherent
      (run `/review-all-gdds` and `/architecture-review` if not done recently)

---

### Gate: Vertical Slice → Production

**Required Artifacts:**
- [ ] Vertical slice REPORT.md exists in `prototypes/` with a PROCEED verdict (run `/vertical-slice`) — **BLOCKING**
- [ ] First sprint plan exists in `production/sprints/`
- [ ] Vertical Slice build is complete and playable — at least one complete [start → challenge → resolution] cycle works
- [ ] Vertical Slice has been playtested with at least 1 documented session
- [ ] Vertical Slice playtest report exists at `production/playtests/` or equivalent

**Quality Checks:**
- [ ] **Core loop fun is validated** — playtest data confirms the central mechanic is enjoyable, not just functional
- [ ] **Developer has personally played the Vertical Slice** — not just built it; artifact evidence alone is insufficient
- [ ] Sprint plan references real story file paths from `production/epics/`
      (not just GDDs — stories must embed GDD req ID + ADR reference)
- [ ] The game communicates what to do within the first 2 minutes of play
- [ ] No critical "fun blocker" bugs exist in the Vertical Slice build
- [ ] The core mechanic feels good to interact with (this is a subjective check — ask the user)
- [ ] **Core fantasy is delivered** — at least one playtester independently described an experience that matches the Player Fantasy section of the core system GDDs (without being prompted)

> **Verdict rules:**
> - **Any validation item is NO** → verdict is automatically FAIL. An unfun or incomplete Vertical Slice must not advance to Production.
> - **Developer has not personally played** → verdict is FAIL regardless of other checks. Artifact-only PASS is insufficient.
> - All checks YES → eligible for PASS.

---

### Gate: Production → Polish

**Required Artifacts:**
- [ ] `src/` has active code organized into subsystems
- [ ] All core mechanics from GDD are implemented (cross-reference `design/gdd/` with `src/`)
- [ ] Main gameplay path is playable end-to-end
- [ ] Test files exist in `tests/unit/` and `tests/integration/` covering Logic and Integration stories
- [ ] All Logic stories from this sprint have corresponding unit test files in `tests/unit/`
- [ ] Smoke check has been run with a PASS or PASS WITH WARNINGS verdict — report exists in `production/qa/`
- [ ] QA plan exists in `production/qa/` (generated by `/qa-plan`) covering this sprint or final production sprint
- [ ] At least one QA plan exists in `production/qa/` covering this production phase — run `/qa-plan` if missing (CONCERNS — advisory, not blocking)
- [ ] QA sign-off report exists in `production/qa/` (generated by `/team-qa`) with verdict APPROVED or APPROVED WITH CONDITIONS
- [ ] At least 3 distinct playtest sessions documented in `production/playtests/`
- [ ] Playtest reports cover: new player experience, mid-game systems, and difficulty curve
- [ ] Fun hypothesis from Game Concept has been explicitly validated or revised

**Quality Checks:**
- [ ] Tests are passing (run test suite via Bash)
- [ ] No critical/blocker bugs in any bug tracker or known issues
- [ ] Core loop plays as designed (compare to GDD acceptance criteria)
- [ ] Performance is within budget (check technical-preferences.md targets)
- [ ] Playtest findings have been reviewed and critical fun issues addressed (not just documented)
- [ ] No "confusion loops" identified — no point in the game where >50% of playtesters got stuck without knowing why
- [ ] Difficulty curve matches the Difficulty Curve design doc (if one exists at `design/difficulty-curve.md`)
- [ ] All implemented screens have corresponding UX specs (no "designed in-code" screens)
- [ ] Interaction pattern library is up-to-date with all patterns used in implementation
- [ ] Accessibility compliance verified against committed tier in `design/accessibility-requirements.md`

**Publishing Readiness Advisory** *(CONCERNS if any missing — these become FAIL at Polish → Release)*:
- [ ] `production/publishing/publishing-roadmap.md` exists (run `/marketing-plan`)
- [ ] Store page draft exists (Glob `production/publishing/store-page*`) — must be live to build wishlists during Polish
- [ ] Press kit exists (Glob `production/publishing/presskit*`) (run `/press-outreach`)
- [ ] `production/publishing/community-status.md` exists (run `/community-plan`)

If any are missing, surface:
> ⚠️ **Publishing work not started**: Polish is the final phase before release. These artifacts are **blocking** at Polish → Release — missing them now means a surprise FAIL at the exit gate. Store pages need time live on the store to build wishlists; starting in Polish is already late. Run the linked skills before beginning Polish sprint work.

---

### Gate: Polish → Release

**Required Artifacts:**
- [ ] All features from milestone plan are implemented
- [ ] Content is complete (all levels, assets, dialogue referenced in design docs exist)
- [ ] Localization strings are externalized (no hardcoded player-facing text in `src/`)
- [ ] QA test plan exists (`/qa-plan` output in `production/qa/`)
- [ ] QA sign-off report exists (`/team-qa` output — APPROVED or APPROVED WITH CONDITIONS)
- [ ] All Must Have story test evidence is present (Logic/Integration: test files pass; Visual/Feel/UI: sign-off docs in `production/qa/evidence/`)
- [ ] Smoke check passes cleanly (PASS verdict) on the release candidate build
- [ ] No test regressions from previous sprint (test suite passes fully)
- [ ] Balance data has been reviewed (`/balance-check` run)
- [ ] Release checklist completed (`/release-checklist` or `/launch-checklist` run)
- [ ] Store metadata prepared (if applicable)
- [ ] Changelog / patch notes drafted

**Publishing Readiness** *(blocking — all four must exist before gate can PASS)*:
- [ ] `production/publishing/publishing-roadmap.md` exists
- [ ] `production/publishing/community-status.md` exists
- [ ] Store page draft exists (Glob `production/publishing/store-page*`)
- [ ] Press kit exists (Glob `production/publishing/presskit*`)

If any publishing artifact is missing:
1. List exactly which are missing
2. Suggest the skill to create it:
   - `publishing-roadmap.md` → `/marketing-plan`
   - `community-status.md` → `/community-plan`
   - Store page → `/export-steam-page`
   - Press kit → `/press-outreach`
3. Mark verdict FAIL — do not advance until all four are present.

**Quality Checks:**
- [ ] Full QA pass signed off by `qa-lead`
- [ ] All tests passing
- [ ] Performance targets met across all target platforms
- [ ] No known critical, high, or medium-severity bugs
- [ ] Accessibility basics covered (remapping, text scaling if applicable)
- [ ] Localization verified for all target languages
- [ ] Legal requirements met (EULA, privacy policy, age ratings if applicable)
- [ ] Build compiles and packages cleanly

**Additional Director** *(this gate only)*: spawn `release-manager` via Task using
gate **RM-PHASE-GATE** (`.claude/docs/director-gates.md`) in parallel with the four
standard PHASE-GATEs.

---

## 3. Run the Gate Check

**Before running artifact checks**, read `docs/consistency-failures.md` if it exists.
Extract entries whose Domain matches the target phase (e.g., if checking
Systems Design → Technical Setup, pull entries in Economy, Combat, or any GDD domain;
if checking Technical Setup → Pre-Production, pull entries in Architecture, Engine).
Carry these as context — recurring conflict patterns in the target domain warrant
increased scrutiny on those specific checks.

For each item in the target gate:

### Artifact Checks
- Use `Glob` and `Read` to verify files exist and have meaningful content
- Don't just check existence — verify the file has real content (not just a template header)
- For code checks, verify directory structure and file counts

**Systems Design → Technical Setup gate — cross-GDD review check**:
Use `Glob('design/gdd/gdd-cross-review-*.md')` to find the `/review-all-gdds` report.
If no file matches, mark the "cross-GDD review report exists" artifact as **FAIL** and
surface it prominently: "No `/review-all-gdds` report found in `design/gdd/`. Run
`/review-all-gdds` before advancing to Technical Setup."
If a file is found, read it and check the verdict line: a FAIL verdict means the
cross-GDD consistency check failed and must be resolved before advancing.

### Quality Checks
- For test checks: Run the test suite via `Bash` if a test runner is configured
- For design review checks: `Read` the GDD and check for the 8 required sections
- For performance checks: `Read` technical-preferences.md and compare against any
  profiling data in `tests/performance/` or recent `/perf-profile` output
- For localization checks: `Grep` for hardcoded strings in `src/`

### Cross-Reference Checks
- Compare `design/gdd/` documents against `src/` implementations
- Check that every system referenced in architecture docs has corresponding code
- Verify sprint plans reference real work items

---

## 4. Collaborative Assessment

For items that can't be automatically verified, **ask the user**:

- "I can't automatically verify that the core loop plays well. Has it been playtested?"
- "No playtest report found. Has informal testing been done?"
- "Performance profiling data isn't available. Would you like to run `/perf-profile`?"

**Never assume PASS for unverifiable items.** Mark them as MANUAL CHECK NEEDED.

---

## 4b. Director Panel Assessment

**Apply review mode before spawning any director:**
- `solo` → skip all four directors. Note in output: "Director Panel skipped — Solo mode. Gate verdict based on artifact and quality checks only." Proceed to Phase 5.
- `lean` → spawn all four directors (phase gates always run in lean mode — this is their purpose).
- `full` → spawn all four directors as normal.

(Review mode was resolved in Phase 1. Use that stored value here.)

### Gather Producer Context (required before spawning PR-PHASE-GATE)

PR-PHASE-GATE runs a **Solo Dev Viability Check** that requires three inputs the artifact scan cannot supply. Collect them now, before spawning any director.

**Step 1 — Team size**: read `production/team.txt` if it exists. If not found, use `AskUserQuestion`:
- Prompt: "What is the current team size?"
- Options: `[A] Solo (1 person)` / `[B] 2–3 people` / `[C] 4+ people`

**Step 2 — Runway estimate**: check `production/milestones/` for any file containing a runway or budget field. If not found, use `AskUserQuestion`:
- Prompt: "What is the current runway estimate (time or budget remaining)?"
- Options: `[A] < 1 month` / `[B] 1–3 months` / `[C] 3–6 months` / `[D] 6+ months` / `[E] Unknown / not tracked`

**Step 3 — Blocked story count**: read `production/sprint-status.yaml`. Count entries with `status: blocked`. If the file doesn't exist, record count as `unknown`.

Store all three values. Pass them explicitly to PR-PHASE-GATE in the next step.

---

Before generating the final verdict, spawn all four directors as **parallel subagents** via Task using the parallel gate protocol from `.claude/docs/director-gates.md`. Issue all four Task calls simultaneously — do not wait for one before starting the next.

**Spawn in parallel:**

1. **`creative-director`** — gate **CD-PHASE-GATE** (`.claude/docs/director-gates.md`)
2. **`technical-director`** — gate **TD-PHASE-GATE** (`.claude/docs/director-gates.md`)
3. **`producer`** — gate **PR-PHASE-GATE** (`.claude/docs/director-gates.md`)
   Pass additionally: team size, runway estimate, blocked story count (gathered above)
4. **`art-director`** — gate **AD-PHASE-GATE** (`.claude/docs/director-gates.md`)

Pass to each: target phase name, list of artifacts present, and the context fields listed in that gate's definition.

**Collect all four responses, then present the Director Panel summary:**

```
## Director Panel Assessment

Creative Director:  [READY / CONCERNS / NOT READY]
  [feedback]

Technical Director: [READY / CONCERNS / NOT READY]
  [feedback]

Producer:           [READY / CONCERNS / NOT READY]
  [feedback]
  Solo Dev Viability Check:
    1. Scope achievable: YES/NO — [reason]
    2. Release date alignment: YES/NO/N/A — [reason]
    3. Scope creep risks: YES/NO — [reason]
  Flagged risks: [list or "none"]

Art Director:       [READY / CONCERNS / NOT READY]
  [feedback]
```

**After collecting all four verdicts** — before computing the final verdict — check the Producer's Solo Dev Viability Check output for any NO answers. If any exist, pause and use `AskUserQuestion`:
- Prompt: "Producer flagged solo dev viability risks. How do you want to proceed?"
- Options:
  - `[A] Acknowledge risk and proceed — I accept these risks`
  - `[B] Revise scope before advancing — pause gate`

Do not advance the gate until the user explicitly selects [A] or [B]. A READY producer verdict with unacknowledged NO answers must not auto-advance.

**Apply to the verdict:**
- Any director returns NOT READY → verdict is minimum FAIL (user may override with explicit acknowledgement)
- Any director returns CONCERNS → verdict is minimum CONCERNS
- All four READY → eligible for PASS (still subject to artifact and quality checks from Section 3)

---

## 5. Output the Verdict

```
## Gate Check: [Current Phase] → [Target Phase]

**Date**: [date]
**Checked by**: gate-check skill

### Required Artifacts: [X/Y present]
- [x] design/gdd/game-concept.md — exists, 2.4KB
- [ ] docs/architecture/ — MISSING (no ADRs found)
- [x] production/sprints/ — exists, 1 sprint plan

### Quality Checks: [X/Y passing]
- [x] GDD has 8/8 required sections
- [ ] Tests — FAILED (3 failures in tests/unit/)
- [?] Core loop playtested — MANUAL CHECK NEEDED

### Blockers
1. **No Architecture Decision Records** — Run `/architecture-decision` to create one
   covering core system architecture before entering production.
2. **3 test failures** — Fix failing tests in tests/unit/ before advancing.

### Recommendations
- [Priority actions to resolve blockers]
- [Optional improvements that aren't blocking]

### Deferred — Out of Active Milestone Scope
[If active milestone resolved: list systems/epics from the milestone definition's Out of Scope section, with deferral reasons]
[If no active milestone: "(No active milestone set — run `/milestone-define activate [name]` to enable scope context)"]

### Verdict: [PASS / CONCERNS / FAIL]
- **PASS**: All required artifacts present, all quality checks passing
- **CONCERNS**: Minor gaps exist but can be addressed during the next phase
- **FAIL**: Critical blockers must be resolved before advancing
```

**Immediately after generating the verdict above**, write the draft to disk:

```
production/session-state/drafts/gate-check-[phase]-YYYYMMDD-HHMMSS.md
```

Create `production/session-state/drafts/` if it does not exist.
This draft survives crashes before the Section 6 write approval.

---

## 5a. Chain-of-Verification

After drafting the verdict in Phase 5, challenge it before finalising.

**Step 1 — Generate 5 challenge questions** designed to disprove the verdict:

For a **PASS** draft:
- "Which quality checks did I verify by actually reading a file, vs. inferring they passed?"
- "Are there MANUAL CHECK NEEDED items I marked PASS without user confirmation?"
- "Did I confirm all listed artifacts have real content, not just empty headers?"
- "Could any blocker I dismissed as minor actually prevent the phase from succeeding?"
- "Which single check am I least confident in, and why?"

For a **CONCERNS** draft:
- "Could any listed CONCERN be elevated to a blocker given the project's current state?"
- "Is the concern resolvable within the next phase, or does it compound over time?"
- "Did I soften any FAIL condition into a CONCERN to avoid a harder verdict?"
- "Are there artifacts I didn't check that could reveal additional blockers?"
- "Do all the CONCERNS together create a blocking problem even if each is minor alone?"

For a **FAIL** draft:
- "Have I accurately separated hard blockers from strong recommendations?"
- "Are there any PASS items I was too lenient about?"
- "Am I missing any additional blockers the user should know about?"
- "Can I provide a minimal path to PASS — the specific 3 things that must change?"
- "Is the fail condition resolvable, or does it indicate a deeper design problem?"

**Step 2 — Answer each question** independently.
Do NOT reference the draft verdict text — re-check specific files or ask the user.

**Step 3 — Revise if needed:**
- If any answer reveals a missed blocker → upgrade verdict (PASS→CONCERNS or CONCERNS→FAIL)
- If any answer reveals an over-stated blocker → downgrade only if citing specific evidence
- If answers are consistent → confirm verdict unchanged

**Step 4 — Note the verification** in the final report output:
`Chain-of-Verification: [N] questions checked — verdict [unchanged | revised from X to Y]`

---

## 6. Update Stage on PASS

When the verdict is **PASS** and the user confirms they want to advance:

1. Write the new stage name to `production/stage.txt` (single line, no trailing newline)
2. This immediately updates the status line for all future sessions

Example: if passing the "Pre-Production → Production" gate:
```bash
echo -n "Production" > production/stage.txt
```

**Always ask before writing**: "Gate passed. May I update `production/stage.txt` to 'Production'?"

---

## 7. Closing Next-Step Widget

After the verdict is presented and any stage.txt update is complete, close with a structured next-step prompt using `AskUserQuestion`.

**Tailor the options to the gate that just ran:**

For **concept PASS** (Concept → Prototype):
```
Gate passed. What would you like to do next?
[A] Run /prototype [mechanic] — build a throwaway prototype to validate the core idea (recommended)
[B] Run /brainstorm — refine the concept further before prototyping
[C] Stop here for this session
```

For **prototype PASS** (Prototype → Systems Design):
```
Gate passed. What would you like to do next?
[A] Run /map-systems — decompose the concept into all game systems (recommended next step)
[B] Run /design-system [mechanic] — start writing individual GDDs informed by prototype learnings
[C] Stop here for this session
```

For **systems-design PASS**:
```
Gate passed. What would you like to do next?
[A] Run /create-architecture — produce your master architecture blueprint and ADR work plan (recommended next step)
[B] Design more GDDs first — return here when all MVP systems are complete
[C] Stop here for this session
```

> **Note for systems-design PASS**: `/create-architecture` is the required next step before writing any ADRs. It produces the master architecture document and a prioritized list of ADRs to write. Running `/architecture-decision` without this step means writing ADRs without a blueprint — skip it at your own risk.

For **technical-setup PASS**:
```
Gate passed. What would you like to do next?
[A] Run /create-control-manifest — generate the layer rules manifest from your Accepted ADRs (do this first)
[B] Run /vertical-slice — build the Vertical Slice (do this before writing epics — validate fun first)
[C] Write more ADRs first — run /architecture-decision [next-system]
[D] Stop here for this session
```

> **Note for technical-setup PASS**: The Pre-Production sequence is deliberately ordered
> to validate fun before committing to detailed planning:
>
> 1. `/create-control-manifest` — extract technical rules from Accepted ADRs (required before epics)
> 2. `/vertical-slice` — build the Vertical Slice **FIRST**, before writing epics or stories
> 3. Playtest → `/playtest-report` — at least 1 session required to pass the Pre-Production gate; 3+ recommended before committing the full team
> 4. `/ux-design [screen]` — UX specs for main menu, core HUD, pause menu (if not done)
> 5. `/create-epics layer:foundation` then `/create-epics layer:core` — plan after fun is validated
> 6. `/create-stories [epic-slug]` for each epic
> 7. `/sprint-plan new`
>
> **Why prototype before epics?** If the prototype reveals the core loop needs to change,
> epics written before that discovery will be partially wrong. Validate fun cheaply first,
> then plan in detail. This is the #1 lesson from GDC postmortem data.

For **vertical-slice PASS** (Vertical Slice → Production):
```
Gate passed. What would you like to do next?
[A] Run /sprint-plan new — plan the first full Production sprint (recommended)
[B] Run /sprint-status — check current sprint state before planning the next one
[C] Stop here for this session
```

For all other gates, offer the two most logical next steps for that phase plus "Stop here".

---

## 8. Follow-Up Actions

Based on the verdict, suggest specific next steps:

- **No art bible?** → `/art-bible` to create the visual identity specification
- **Art bible complete but no taste-gate templates?** → `/taste-gate [asset-type]` before batch AI image generation — prevents costly full-batch regeneration after style misalignment
- **Art bible exists but no asset specs?** → `/asset-spec system:[name]` to generate per-asset visual specs and generation prompts from approved GDDs
- **No game concept?** → `/brainstorm` to create one
- **No systems index?** → `/map-systems` to decompose the concept into systems
- **Missing design docs?** → `/reverse-document` or delegate to `game-designer`
- **Small design change needed?** → `/quick-design` for changes under ~4 hours (bypasses full GDD pipeline)
- **No UX specs?** → `/ux-design [screen name]` to author specs, or `/team-ui [feature]` for full pipeline
- **UX specs not reviewed?** → `/ux-review [file]` or `/ux-review all` to validate
- **No accessibility requirements doc?** → run `/ux-design` which creates both `design/accessibility-requirements.md` and `design/ux/interaction-patterns.md` in one step
- **No interaction pattern library?** → `/ux-design patterns` to initialize it
- **GDDs not cross-reviewed?** → `/review-all-gdds` (run after all MVP GDDs are individually approved)
- **Cross-GDD consistency issues?** → fix flagged GDDs, then re-run `/review-all-gdds`
- **No test framework?** → `/test-setup` to scaffold the framework for your engine
- **No QA plan for current sprint?** → `/qa-plan sprint` to generate one before implementation begins
- **Missing ADRs?** → `/architecture-decision` for individual decisions
- **No master architecture doc?** → `/create-architecture` for the full blueprint
- **ADRs missing engine compatibility sections?** → Re-run `/architecture-decision`
  or manually add Engine Compatibility sections to existing ADRs
- **Missing control manifest?** → `/create-control-manifest` (requires Accepted ADRs)
- **Missing epics?** → `/create-epics layer: foundation` then `/create-epics layer: core` (requires control manifest)
- **Missing stories for an epic?** → `/create-stories [epic-slug]` (run after each epic is created)
- **Stories not implementation-ready?** → `/story-readiness` to validate stories before developers pick them up
- **Tests failing?** → delegate to `lead-programmer` or `qa-tester`
- **No playtest data?** → `/playtest-report`
- **No playtest sessions beyond the minimum?** → Additional sessions give more reliable signal. 3+ total is recommended before committing the full team. Use `/playtest-report` to structure findings.
- **No Difficulty Curve doc?** → Create `design/difficulty-curve.md` from the template at `.claude/docs/templates/difficulty-curve.md` — or use `/quick-design "difficulty curve"` for a guided session.
- **No player journey map?** → Create `design/player-journey.md` from the template at `.claude/docs/templates/player-journey.md` — or author it collaboratively using `/ux-design` Phase 2b.
- **Need a quick sprint check?** → `/sprint-status` for current sprint progress snapshot
- **Performance unknown?** → `/perf-profile`
- **Not localized?** → `/l10n-prepare scan` to start (then `wrap` → `integrate export` → `qa`)
- **Ready for release?** → `/launch-checklist`

---

## Collaborative Protocol

This skill follows the collaborative design principle:

1. **Scan first**: Check all artifacts and quality gates
2. **Ask about unknowns**: Don't assume PASS for things you can't verify
3. **Present findings**: Show the full checklist with status
4. **User decides**: The verdict is a recommendation — the user makes the final call
5. **Get approval**: "May I write this gate check report to production/gate-checks/?"
6. **Never auto-fix**: If required artifacts are missing, report the FAIL verdict and
   name the skill to run (e.g. "run `/test-setup`"). Do NOT create missing files or
   re-run the gate automatically. Creating files to manufacture a PASS defeats the
   gate's purpose.

**Never** block a user from advancing — the verdict is advisory. Document the risks
and let the user decide whether to proceed despite concerns.
