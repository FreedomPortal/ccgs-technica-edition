# Skill Spec: /demo-feedback

> **Category**: utility
> **Priority**: low
> **Spec written**: 2026-05-26

## Skill Summary

`/demo-feedback` aggregates multiple demo playtest sessions into cross-session patterns, conversion trends, and a prioritized action list with a go/no-go release recommendation. It requires a minimum of 2 completed `demo-playtest` reports (configurable via `--min-sessions N`). A `game-designer` subagent synthesizes the reports into 8 cross-session sections: session overview, completion rate, conversion trend, recurring issues, single-session issues, onboarding pattern, first-2-minutes aggregate, and a priority matrix with top 5 actions. A `producer` subagent then issues a GO / NO-GO / CONDITIONAL GO verdict based on conversion rate threshold (default 60%), P1 blocker count, completion rate (>50%), and bug severity. In full mode a `creative-director` also assesses pillar alignment. The feedback synthesis is written to `production/qa/playtests/demo-feedback-[date].md` after approval.

---

## Static Assertions

- [ ] Frontmatter has all required fields (`name`, `description`, `argument-hint`, `user-invocable`, `allowed-tools`)
- [ ] 2+ phase headings found
- [ ] At least one verdict keyword present (`GO`, `NO-GO`, `CONDITIONAL GO`, `COMPLETE`)
- [ ] If `allowed-tools` includes Write/Edit: `"May I write"` language present
- [ ] Next-step handoff section present at end

---

## Director Gate Checks

- **N/A**: `/demo-feedback` does not use a named director phase gate. The producer GO/NO-GO assessment and optional creative director pillar review are functional subagent calls, not gated phase transitions with skip messages. In solo and lean modes the creative director step is skipped; the producer assessment always runs.

---

## Test Cases

### Case 1: Happy Path — GO verdict from 3 sessions
**Fixture**:
- `design/demo/demo-scope.md` exists with acceptance criteria and 60% conversion threshold
- `design/gdd/game-concept.md` exists
- 3 playtest reports at `production/qa/playtests/demo-playtest-*.md`
- Reports show: 3/3 completed, conversion intent 2× Definitely + 1× Probably, no P1 blockers, no S1/S2 bugs
- `production/qa/playtests/demo-conversion-summary.md` exists

**Expected behavior**:
1. Phase 1 reads demo-scope.md, game-concept.md, conversion-summary.md
2. Phase 2 globs playtest reports; finds 3 (≥ minimum 2); reads all
3. Phase 3 spawns `game-designer` via Task; synthesis covers all 8 sections
4. Synthesis presented to user
5. Phase 4 spawns `producer` via Task; producer assesses: 100% conversion (≥60%), 0 P1 blockers, 100% completion, no S1/S2 bugs → GO
6. Review mode lean → creative director skipped
7. Phase 5 asks "May I write the demo feedback synthesis to `production/qa/playtests/demo-feedback-[date].md`?"
8. File written; summary shows GO verdict

**Assertions**:
- [ ] All 8 synthesis sections present in output
- [ ] Positive conversion rate calculated and shown
- [ ] Producer verdict is GO
- [ ] Top 5 actions listed in the output
- [ ] "May I write" asked before file write
- [ ] Next steps for GO: `/demo-polish`, `/demo-build`
**Case Verdict**: PASS

---

### Case 2: Failure — Insufficient sessions; user declines to proceed
**Fixture**:
- Only 1 playtest report exists
- `--min-sessions` not passed (default minimum: 2)

**Expected behavior**:
1. Phase 2 globs reports; finds 1 (< minimum 2)
2. Skill outputs: "Found 1 demo playtest report(s) — minimum is 2 for reliable pattern detection."
3. Options: "Yes — treat findings as preliminary" / "No — I'll run more playtests first"
4. User selects No
5. Skill stops; no synthesis, no file written

**Assertions**:
- [ ] Insufficient session count message shown with the actual count and minimum
- [ ] `AskUserQuestion` presented with both options
- [ ] If No: skill halts cleanly
- [ ] No `game-designer` Task spawned
**Case Verdict**: PASS

---

### Case 3: Mode Variant — NO-GO verdict with P1 blockers; full review adds CD assessment
**Fixture**:
- 3 playtest reports; conversion intent: 1× Probably + 2× Probably not (33% positive, below 60%)
- 2 P1 conversion blockers found across sessions
- Skill invoked with `--review full`

**Expected behavior**:
1. Phase 2: 3 reports found; all read
2. Phase 3 synthesis shows 33% positive conversion rate and 2 P1 blockers
3. Phase 4 producer: conversion below threshold + P1 blockers → NO-GO; specific blockers listed
4. Phase 4 also spawns `creative-director` (full mode); returns MISALIGNED
5. `## Creative Director Assessment` section added to output document before write
6. Phase 5 asks approval to write
7. Summary shows NO-GO; next steps include `/demo-iterate`

**Assertions**:
- [ ] NO-GO verdict clearly stated with reasoning
- [ ] P1 blockers listed specifically in the verdict
- [ ] Creative director spawned in full mode
- [ ] If MISALIGNED: CD Assessment section present in document
- [ ] Next steps for NO-GO include `/demo-iterate` and re-running `/demo-playtest`
**Case Verdict**: PASS

---

### Case 4: Edge Case — `--min-sessions 1` flag to proceed with single session
**Fixture**:
- Only 1 playtest report exists
- Skill invoked as `/demo-feedback --min-sessions 1`

**Expected behavior**:
1. Phase 2 globs 1 report; minimum is now 1 (from flag); no threshold warning
2. Skill proceeds directly to Phase 3 synthesis
3. Synthesis notes session count prominently ("1 session — preliminary only")
4. Producer verdict issued but noted as preliminary

**Assertions**:
- [ ] `--min-sessions 1` overrides the default minimum of 2
- [ ] No threshold warning shown (count meets the custom minimum)
- [ ] Session count noted in synthesis output
**Case Verdict**: PASS

---

### Case 5: Protocol — File write gate and content requirements
**Fixture**:
- 2+ sessions; synthesis and GO/NO-GO verdict produced
- User reviewing output before approval

**Expected behavior**:
1. Phase 3 synthesis output presented to user before Phase 5
2. Phase 4 verdict presented
3. Phase 5 asks: "May I write the demo feedback synthesis to `production/qa/playtests/demo-feedback-[date].md`?"
4. File content includes: Phase 3 synthesis + Phase 4 verdict + top 5 actions
5. If CD assessment exists (full mode): also included in file
6. No auto-write

**Assertions**:
- [ ] Uses "May I write" before file write
- [ ] Full synthesis and verdict presented before approval prompt
- [ ] Top 5 priority actions clearly marked in the file
- [ ] No auto-write
**Case Verdict**: PASS

---

## Protocol Compliance

- [ ] Uses `"May I write"` before any file writes (or is read-only and skips this)
- [ ] Presents findings/draft to user before requesting approval
- [ ] Ends with a recommended next step or follow-up action
- [ ] Does not auto-create files without user approval

---

## Coverage Notes

- The 60% conversion threshold is a default that can be overridden by `demo-scope.md`; testing the override is runtime-only.
- Session count prominance ("small N is preliminary") is advisory output from the subagent; not mechanically enforceable.
- The `demo-conversion-summary.md` is optional; if absent the synthesis proceeds on report files alone — this path is runtime-only.
- Creative director ALIGNED / MINOR CONCERNS / MISALIGNED verdict affects whether the CD Assessment section appears; full verification requires runtime testing.
