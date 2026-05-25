# Skill Spec: /vertical-slice

> **Category**: pipeline
> **Priority**: high
> **Spec written**: 2026-05-26

## Skill Summary

`/vertical-slice` builds a near-production-quality end-to-end game loop to validate whether the full design is achievable before committing to Production. It reads GDDs, architecture docs, and UX specs; defines a falsifiable validation question; guides implementation in an isolated worktree; runs a structured playtest debrief; and produces a PROCEED/PIVOT/KILL verdict with a report written to `prototypes/[name]-vertical-slice/REPORT.md`. In full review mode, the creative director reviews the report via the CD-PLAYTEST gate. The verdict gates the Pre-Production → Production transition.

---

## Static Assertions

- [x] Frontmatter has all required fields (`name`, `description`, `argument-hint`, `user-invocable`, `allowed-tools`)
- [x] 2+ phase headings found (8 phases)
- [x] At least one verdict keyword present (PROCEED, PIVOT, KILL, COMPLETE, PASS)
- [x] `allowed-tools` includes Write/Edit: `"May I"` language present (Phase 4, 6, 8)
- [x] Next-step handoff section present at end (Phase 8 lists `/create-epics`, `/gate-check`, `/sprint-plan`, `/design-system`)

---

## Director Gate Checks

- **Full mode**: CD-PLAYTEST (creative-director, Phase 7) — evaluates slice result against game pillars. Verdict is final; overrides report if it differs.
- **Lean mode**: CD-PLAYTEST skipped. Note logged: "CD-PLAYTEST skipped — Lean mode."
- **Solo mode**: CD-PLAYTEST skipped. Note logged: "CD-PLAYTEST skipped — Solo mode."

---

## Test Cases

### Case 1: Happy Path — PROCEED verdict

**Fixture**:
- `design/gdd/game-concept.md` exists with core fantasy defined
- `docs/architecture/architecture.md` and `control-manifest.md` exist
- `design/gdd/systems-index.md` lists MVP systems
- Review mode: lean (default)

**Expected behavior**:
1. Phase 1 reads all context files
2. Phase 2 presents validation question and scope; user confirms
3. Phase 3 defines plan and scope; user confirms; checkpoint written to active.md
4. Phase 4 asks "May I create `prototypes/[name]-vertical-slice/`?"; creates it on approval
5. Phase 5 runs playtest debrief — asks 6 questions one at a time; user reports full loop completion, core fantasy felt, PROCEED verdict
6. Phase 6 generates REPORT.md; asks "May I write this report to `prototypes/[name]-vertical-slice/REPORT.md`?"
7. Phase 7 skips CD-PLAYTEST (lean mode)
8. Phase 8 outputs summary with PROCEED and recommended next steps

**Assertions**:
- [ ] Scope confirmed before building starts
- [ ] Validation question is falsifiable (player experience AND build feasibility)
- [ ] Implementation files include `// VERTICAL SLICE - NOT FOR PRODUCTION` header
- [ ] Playtest debrief asks 6 questions one at a time, not as a list
- [ ] REPORT.md includes velocity log section
- [ ] Phase 8 recommends `/create-epics`, `/sprint-plan`, `/gate-check`
- [ ] "May I write" asked before REPORT.md is written

**Case Verdict**: PASS

---

### Case 2: Failure — KILL verdict

**Fixture**:
- Slice built and playtested; 2+ KILL checklist boxes apply:
  - Full loop takes >5 minutes
  - No emotional high point in any session
- Review mode: lean

**Expected behavior**:
1. Phase 5 debrief returns KILL verdict
2. Phase 6 generates REPORT.md with KILL verdict
3. Phase 8: KILL branch — presents kill checklist, asks "May I append to `prototypes/GRAVEYARD.md`?"
4. On approval, appends kill entry with reason, what worked, what failed, next-time note
5. Recommends `/brainstorm` or `/prototype` for new direction

**Assertions**:
- [ ] Kill checklist evaluated before confirming verdict
- [ ] "May I append this to `prototypes/GRAVEYARD.md`?" asked before writing
- [ ] GRAVEYARD.md entry includes: kill reason, what worked, what failed, next-time note
- [ ] Skill recommends `/brainstorm` or `/prototype`, not `/gate-check`

**Case Verdict**: PASS

---

### Case 3: Mode Variant — Full mode triggers CD-PLAYTEST

**Fixture**:
- Slice built, PROCEED verdict from playtest debrief
- Review mode: full (`--review full` or `production/review-mode.txt` = `full`)

**Expected behavior**:
1. Phases 1–6 proceed as in Case 1
2. Phase 7: spawns `creative-director` via Task using CD-PLAYTEST gate
3. Passes full REPORT.md content + validation question + game pillars
4. Creative director's verdict is final; REPORT.md updated if it differs from slice verdict

**Assertions**:
- [ ] CD-PLAYTEST gate spawned in full mode
- [ ] Passes REPORT.md, validation question, and game pillars to creative-director
- [ ] If CD verdict differs from slice verdict, REPORT.md is updated
- [ ] CD-PLAYTEST note logged in lean and solo mode ("skipped")

**Case Verdict**: PASS

---

### Case 4: Edge Case — PIVOT verdict

**Fixture**:
- Slice built; core loop incomplete or architecture issue identified
- PIVOT verdict given in debrief

**Expected behavior**:
1. Phase 6 generates REPORT.md with PIVOT verdict
2. Phase 8 PIVOT branch: asks two carry-forward questions one at a time (what worked, what specifically failed)
3. Asks "May I write this to `prototypes/[name]-vertical-slice/PIVOT-NOTE.md`?"
4. On approval, writes PIVOT-NOTE.md
5. Routes to `/design-system`, `/architecture-decision`, then re-run `/vertical-slice`
6. Next vertical slice run checks for existing PIVOT-NOTE.md and uses it to frame new validation question

**Assertions**:
- [ ] Two carry-forward questions asked one at a time before writing PIVOT-NOTE.md
- [ ] "May I write" asked before PIVOT-NOTE.md creation
- [ ] PIVOT-NOTE.md contains: what worked, what failed, what next slice must prove
- [ ] Re-run of skill picks up PIVOT-NOTE.md from `prototypes/` directory

**Case Verdict**: PASS

---

### Case 5: Edge Case — Scope creep warning and sunk cost checkpoint

**Fixture**:
- Day 3 of planned timeline; full game loop not yet demonstrable
- Scope was correctly defined in Phase 3

**Expected behavior**:
1. Phase 4 sunk cost checkpoint fires: surfaces blocker explicitly
2. Does NOT continue iterating silently
3. Asks user to reassess scope or surface architectural issue

**Assertions**:
- [ ] Day 3 checkpoint triggers if full loop not demonstrable by then
- [ ] Blocker surfaced explicitly rather than continuing silently
- [ ] Scope creep warning appears if new systems are proposed mid-build

**Case Verdict**: PASS

---

## Protocol Compliance

- [x] Uses `"May I"` before creating prototype directory (Phase 4), writing REPORT.md (Phase 6), writing PIVOT-NOTE.md / GRAVEYARD.md (Phase 8)
- [x] Presents scope, plan, and debrief findings before requesting approval
- [x] Ends with recommended next steps for each verdict (PROCEED/PIVOT/KILL)
- [x] Does not auto-create files without user approval

---

## Coverage Notes

- Velocity log correctness (actual day-by-day vs estimates) cannot be verified without a live run
- CD-PLAYTEST "verdict override" behavior is described but difficult to spec-verify statically
- Worktree isolation (`isolation: worktree` in frontmatter) is engine-level behavior not testable here
- The `prototypes/index.md` update (Phase 6) is an easy-to-miss step — worth testing in a live run
