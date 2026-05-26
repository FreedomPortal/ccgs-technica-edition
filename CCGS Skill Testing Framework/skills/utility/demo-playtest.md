# Skill Spec: /demo-playtest

> **Category**: utility
> **Priority**: low
> **Spec written**: 2026-05-26

## Skill Summary

`/demo-playtest` is a structured demo-specific playtest protocol. It operates in two modes: `new` (generate a blank demo playtest report template) and `analyze [path]` (read raw notes and fill in the template with structured findings). The template focuses on the metrics that matter for demos: first-2-minutes hook, onboarding clarity, playthrough completion, and conversion intent (wishlist/buy). Findings are categorized into conversion blockers, onboarding failures, completion failures, design feedback, bugs, and polish items. In full review mode a `creative-director` reviews the report against game pillars. The report is written to `production/qa/playtests/demo-playtest-[date]-[tester].md` after approval. An optional conversion tracking table is maintained in `demo-conversion-summary.md`.

---

## Static Assertions

- [ ] Frontmatter has all required fields (`name`, `description`, `argument-hint`, `user-invocable`, `allowed-tools`)
- [ ] 2+ phase headings found
- [ ] At least one verdict keyword present (`COMPLETE`, `APPROVE`, `CONCERNS`, `REJECT`)
- [ ] If `allowed-tools` includes Write/Edit: `"May I write"` language present
- [ ] Next-step handoff section present at end

---

## Director Gate Checks

- **N/A**: `/demo-playtest` uses a creative director review in full mode only (CD-DEMO-PLAYTEST). This is an advisory review with verdict APPROVE / CONCERNS / REJECT, not a blocking phase gate. In solo and lean modes (the default) it is skipped entirely. No gate IDs are used.

---

## Test Cases

### Case 1: Happy Path — New template mode with demo-scope.md present
**Fixture**:
- `design/demo/demo-scope.md` exists with included content, playthrough flow, and target duration
- `design/gdd/game-concept.md` exists with pillars
- Skill invoked as `/demo-playtest new` (or no argument)

**Expected behavior**:
1. Phase 0 resolves review mode (default: lean)
2. Phase 1 parses argument as `new`
3. Phase 1b reads demo-scope.md and game-concept.md
4. Phase 2A generates the full demo playtest template
5. Template shown to user with all sections: Session Info, Playthrough Metrics, First 2 Minutes, Onboarding Assessment (with rows from demo-scope.md included content), Gameplay Flow, Demo End State, Conversion Intent, Hook Strength, Bugs, Overall Assessment, Top 3 Findings
6. No findings categorization yet (this is template generation only)
7. Skill suggests running `/demo-playtest analyze [path]` after completing the session

**Assertions**:
- [ ] Template includes Conversion Intent section with the 4 key questions
- [ ] Onboarding Assessment table includes row placeholders derived from demo-scope.md included content
- [ ] First 2 Minutes section is present and explicitly framed as the critical window
- [ ] Template shown before any approval gate
**Case Verdict**: PASS

---

### Case 2: Failure — No demo-scope.md found
**Fixture**:
- `design/demo/demo-scope.md` does not exist
- Skill invoked as `/demo-playtest`

**Expected behavior**:
1. Phase 1b reads demo-scope.md — not found
2. Skill outputs: "No demo scope found. Run `/demo-scope` first to define the demo before running a playtest."
3. Skill stops; no template generated

**Assertions**:
- [ ] Error message references `/demo-scope`
- [ ] No template generated
- [ ] No file write attempted
**Case Verdict**: PASS

---

### Case 3: Mode Variant — Analyze mode processes raw notes
**Fixture**:
- `design/demo/demo-scope.md` exists
- `design/gdd/game-concept.md` exists
- Raw playtest notes file exists at `production/qa/playtests/raw-notes-2026-05-20.md`
- Skill invoked as `/demo-playtest analyze production/qa/playtests/raw-notes-2026-05-20.md`

**Expected behavior**:
1. Phase 1 parses argument as `analyze` with the provided path
2. Phase 1b reads demo-scope.md and game-concept.md
3. Phase 2B reads raw notes at the given path
4. Template filled in with structured findings from the raw notes
5. Any observations conflicting with intended demo experience (from scope doc) are flagged
6. Phase 3 categorizes findings: conversion blockers, onboarding failures, completion failures, design feedback, bugs, polish items
7. Each category routes to appropriate follow-up skill
8. Phase 5 asks "May I write this demo playtest report to `production/qa/playtests/demo-playtest-[date]-[tester].md`?"

**Assertions**:
- [ ] Raw notes file is read from the provided path
- [ ] All 6 finding categories present in output
- [ ] Routing suggestions given per category (e.g., `/bug-report` for bugs, `/ux-review` for onboarding)
- [ ] Conflicts with demo-scope.md flagged explicitly
- [ ] "May I write" asked before file write
**Case Verdict**: PASS

---

### Case 4: Edge Case — Full review mode triggers creative director review
**Fixture**:
- `design/demo/demo-scope.md` and `design/gdd/game-concept.md` exist
- Raw notes provided via analyze mode
- Skill invoked with `--review full`

**Expected behavior**:
1. Phase 0 resolves review mode as `full`
2. Phases 1–3 complete normally
3. Phase 4: `creative-director` spawned via Task with structured report + pillars + demo scope
4. Creative director assesses: identity communication in first 2 minutes, conversion intent data, pillar conflicts, single most important change
5. Verdict: APPROVE / CONCERNS / REJECT
6. If CONCERNS or REJECT: `## Creative Director Assessment` section added to report
7. Phase 5 write gate follows

**Assertions**:
- [ ] Creative director Task spawned in full mode (not skipped)
- [ ] Creative director verdict (APPROVE / CONCERNS / REJECT) appears in output
- [ ] If CONCERNS/REJECT: CD Assessment section appears in report
- [ ] Creative director is skipped in lean/solo mode
**Case Verdict**: PASS

---

### Case 5: Protocol — Conversion tracking table approval
**Fixture**:
- Playtest session completed and report produced
- Multiple previous sessions exist (this is session 3)

**Expected behavior**:
1. Phase 5 asks "May I write this demo playtest report to `production/qa/playtests/demo-playtest-[date]-[tester].md`?"
2. User approves; file written
3. Phase 6 asks: "Would you like to track this session's conversion data in a summary table?"
4. User says yes
5. Skill creates or appends to `production/qa/playtests/demo-conversion-summary.md` — separate approval or as part of Phase 6 offer
6. Summary row appended with date, tester, completion, conversion intent, top blocker

**Assertions**:
- [ ] Uses "May I write" before writing report file
- [ ] Phase 6 is optional and user-prompted (not auto-written)
- [ ] Conversion summary row appended (not full file rewrite) if file already exists
- [ ] No auto-write occurs
**Case Verdict**: PASS

---

## Protocol Compliance

- [ ] Uses `"May I write"` before any file writes (or is read-only and skips this)
- [ ] Presents findings/draft to user before requesting approval
- [ ] Ends with a recommended next step or follow-up action
- [ ] Does not auto-create files without user approval

---

## Coverage Notes

- Conversion intent is the primary metric; its prominence in the output is runtime-dependent on the structuring step.
- The distinction between observed and unobserved sessions affects data weighting; this is a note in the template header and is runtime behavior.
- Prior-knowledge weighting (blind testers vs. informed testers) is advisory guidance in the Collaborative Protocol, not a mechanical enforcement; cannot be statically tested.
- The Phase 6 conversion summary append behavior (vs. create) depends on whether `demo-conversion-summary.md` exists — runtime only.
