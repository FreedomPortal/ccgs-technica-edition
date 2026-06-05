# Skill Spec: /demo-gate

> **Category**: utility
> **Priority**: low
> **Spec written**: 2026-06-05

## Skill Summary

Validates readiness to advance a demo campaign from one sub-stage to the next. Takes a demo-id and optional target sub-stage, checks required artifacts and quality criteria for that gate, produces a PASS/CONCERNS/FAIL verdict, writes a draft immediately, and on PASS offers to update state.txt after user confirmation.

---

## Static Assertions

- [x] Frontmatter has all required fields (`name`, `description`, `argument-hint`, `user-invocable`, `allowed-tools`)
- [x] 2+ phase headings found (sections 1–6)
- [x] At least one verdict keyword present (`PASS`, `CONCERNS`, `FAIL`)
- [x] `allowed-tools` includes Write — `"May I update"` language present (state.txt update)
- [x] Next-step handoff section present (Section 6: Next-Step Widget)

---

## Director Gate Checks

**N/A** — demo-gate mirrors the gate-check pattern for the demo track but does not spawn director agents. It is a self-contained artifact-verification skill. Director review happens in the main pipeline (`/gate-check`), not the demo track.

---

## Test Cases

### Case 1: Happy Path — Gate passes, state.txt updated

**Fixture**:
- `production/demo/alpha/state.txt` contains `Building`
- All Building → Playtesting artifacts present: internal build report exists, content gates implemented, smoke check passed

**Expected behavior**:
1. Skill reads demo-id `alpha`, detects current stage `Building`, confirms target gate is `Building → Playtesting`
2. Checks each required artifact and quality criterion
3. All checks pass — verdict PASS
4. Draft written to `production/session-state/drafts/demo-gate-alpha-playtesting-YYYYMMDD-HHMMSS.md` immediately
5. Asks "May I update `production/demo/alpha/state.txt` to 'Playtesting'?"
6. On confirmation: writes new state.txt
7. Offers next-step widget: `/demo-playtest` or stop

**Assertions**:
- [ ] Skill reads state.txt to determine current sub-stage without asking user
- [ ] Draft written to `drafts/` before asking write approval
- [ ] Verdict PASS displayed with artifact checklist showing all items checked
- [ ] state.txt write gated behind "May I update" confirmation
- [ ] Next-step widget offered after state.txt update

**Case Verdict**: PASS

---

### Case 2: Failure — Missing required artifact

**Fixture**:
- `production/demo/alpha/state.txt` contains `Playtesting`
- Gate target: `Playtesting → Evaluating`
- Only 1 playtest session documented (gate requires ≥3)
- No evidence of a new-player session

**Expected behavior**:
1. Skill counts playtest files — finds 1, needs 3
2. Also detects no new-player session evidence
3. Marks both items as failing
4. Verdict: FAIL
5. Draft written to `drafts/`
6. state.txt NOT updated — FAIL gate does not advance

**Assertions**:
- [ ] Skill counts playtest files via Glob, not just checks existence of directory
- [ ] Blockers section lists both specific gaps
- [ ] Verdict FAIL shown with blockers
- [ ] state.txt NOT written; no "May I update" prompt issued
- [ ] Draft still written even on FAIL

**Case Verdict**: PASS

---

### Case 3: Early Access Mode — Sub-stages 9 and 10 available

**Fixture**:
- `production/demo/ea-demo/state.txt` contains `Released`
- `production/demo/ea-demo/demo-plan.md` contains `Early Access: true`
- Target: `Released → Publishing`
- EA store page is live, EA pricing set, roadmap communicated

**Expected behavior**:
1. Skill detects EA mode from demo-plan.md
2. Makes sub-stages 9 (Publishing) and 10 (Live) available
3. Runs gate `Released → Publishing` with EA-specific artifact list
4. Checks `/demo-integrate` was run and `/publish-check` EA requirements met
5. Verdict PASS if EA artifacts present

**Assertions**:
- [ ] Skill reads demo-plan.md to detect `Early Access: true`
- [ ] EA sub-stages 9 and 10 are included in the gate list
- [ ] Gate `Released → Publishing` includes EA-specific checks (store page live, pricing, roadmap)
- [ ] Non-EA runs do not show sub-stages 9 and 10

**Case Verdict**: PASS

---

### Case 4: Edge Case — Unverifiable quality check

**Fixture**:
- `production/demo/alpha/state.txt` contains `Building`
- Target: `Building → Playtesting`
- Artifacts present, but "demo plays start-to-finish" cannot be verified from files

**Expected behavior**:
1. Skill verifies file-based artifacts via Glob/Read
2. For the "can be played start-to-finish" quality check: uses AskUserQuestion
   - Prompt: "I can't auto-verify the demo is playable end-to-end. Has it been played through internally?"
3. If user confirms: marks as PASS
4. If user cannot confirm: marks as MANUAL CHECK NEEDED → verdict becomes CONCERNS

**Assertions**:
- [ ] Skill does NOT auto-assume PASS for unverifiable quality checks
- [ ] AskUserQuestion used for subjective/behavioral checks
- [ ] MANUAL CHECK NEEDED state present in output when unconfirmed
- [ ] Verdict CONCERNS (not PASS) if any MANUAL CHECK items left unconfirmed

**Case Verdict**: PASS

---

### Case 5: No demo-id provided — auto-detect campaign

**Fixture**:
- Multiple demo campaigns: `production/demo/alpha/state.txt` (Building), `production/demo/beta/state.txt` (Released)
- User runs `/demo-gate` with no arguments

**Expected behavior**:
1. Skill globs `production/demo/*/state.txt`
2. Lists found campaigns and asks which to gate
3. User selects `alpha`
4. Skill proceeds with `alpha` campaign, confirms `Building → Playtesting` gate

**Assertions**:
- [ ] Missing demo-id triggers campaign list, not error
- [ ] AskUserQuestion lists all found campaigns
- [ ] After campaign selection, skill confirms the transition before running gate
- [ ] Gate runs correctly after resolution

**Case Verdict**: PASS

---

## Protocol Compliance

- [x] Uses `"May I update"` before writing state.txt
- [x] Draft written to `production/session-state/drafts/` immediately after verdict — before write approval
- [x] Ends with next-step widget (Section 6)
- [x] Does not auto-advance stage without user confirmation

---

## Coverage Notes

- Section 2 has 9 gate definitions; only 2 tested here (Building→Playtesting, Playtesting→Evaluating). The artifact lists for other gates follow the same check pattern and are not independently tested.
- hunk-level draft file naming uses timestamp — impossible to assert exact filename, only directory and prefix.
- EA mode gates (Publishing, Live) tested at Case 3 but only for artifact presence; the `/demo-integrate` and `/publish-check` cross-check assertions are inferred from reading skill text.
