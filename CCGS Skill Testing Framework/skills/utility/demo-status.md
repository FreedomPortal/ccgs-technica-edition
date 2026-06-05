# Skill Spec: /demo-status

> **Category**: utility
> **Priority**: low
> **Spec written**: 2026-06-05

## Skill Summary

Read-only advisory scan of active demo campaigns. Reads state.txt to determine sub-stage, cross-checks expected artifacts for that stage, reports confidence (HIGH/MEDIUM/LOW), flags discrepancies, and ends with a recommendation to run `/demo-gate` to formally advance. Never writes state.txt or any file.

---

## Static Assertions

- [x] Frontmatter has all required fields (`name`, `description`, `argument-hint`, `user-invocable`, `allowed-tools`)
- [x] 2+ phase headings found (sections 1–4)
- [x] At least one verdict keyword present (`CONSISTENT`, `DISCREPANCY` used as status keywords; report implies PASS/FAIL implicitly)
- [x] `allowed-tools` is Read, Glob, Grep only — no Write or Edit; `"May I write"` check is N/A for read-only skill
- [x] Next-step handoff present: ends with `Run /demo-gate [demo-id] [next-sub-stage]`

---

## Director Gate Checks

**N/A** — demo-status is a read-only advisory skill. It never triggers director agent panels or gate prompts.

---

## Test Cases

### Case 1: Happy Path — Single campaign, artifacts consistent

**Fixture**:
- `production/demo/alpha/state.txt` contains `Building`
- `production/demo/alpha/demo-plan.md` exists
- `design/demo/demo-scope.md` exists
- Build report exists in `production/demo/alpha/`
- No EA flag in demo-plan.md

**Expected behavior**:
1. Skill reads `production/demo/alpha/state.txt` → sub-stage: Building
2. Detects no EA flag
3. Checks Building-stage artifacts: plan, scope, build report
4. All present → status CONSISTENT, confidence HIGH
5. Reports blockers for next advance: what's needed for Building → Playtesting gate
6. Ends with: `Run /demo-gate alpha playtesting to formally advance.`

**Assertions**:
- [ ] Sub-stage read from state.txt without asking user
- [ ] Confidence HIGH shown when state.txt exists and artifacts match
- [ ] Artifact checklist shows all expected items for the detected sub-stage
- [ ] Status CONSISTENT reported
- [ ] "Blockers for Next Advance" section lists what is needed for the next gate
- [ ] Final line recommends `/demo-gate alpha playtesting`

**Case Verdict**: PASS

---

### Case 2: Failure — No campaigns found

**Fixture**:
- `production/demo/` directory does not exist or contains no `state.txt` files

**Expected behavior**:
1. Skill globs `production/demo/*/state.txt`
2. Finds no files
3. Reports: "No active demo campaigns found. Run `/demo-plan` to start a new demo campaign."
4. Stops

**Assertions**:
- [ ] Skill handles missing `production/demo/` without error
- [ ] Correct guidance message shown (`/demo-plan` to create)
- [ ] No crash or empty output
- [ ] No files written (read-only)

**Case Verdict**: PASS

---

### Case 3: Discrepancy — state.txt ahead of artifacts

**Fixture**:
- `production/demo/alpha/state.txt` contains `Evaluating`
- No evaluation or feedback synthesis doc exists in `production/demo/alpha/`
- Playtest files exist (3 sessions)

**Expected behavior**:
1. Skill reads state.txt → Evaluating
2. Checks Evaluating-stage artifact: evaluation synthesis doc
3. Artifact missing → flags as discrepancy
4. Confidence lowered to LOW
5. Status: DISCREPANCY — state.txt says Evaluating but evaluation doc is missing
6. Blockers for advance listed

**Assertions**:
- [ ] Discrepancy detected when artifacts don't match sub-stage
- [ ] Confidence LOW reported on discrepancy
- [ ] Status shows `DISCREPANCY — state.txt says X but artifact Y is missing`
- [ ] Blockers section reflects the missing artifact

**Case Verdict**: PASS

---

### Case 4: All campaigns — multi-campaign summary

**Fixture**:
- `production/demo/alpha/state.txt` → Building
- `production/demo/beta/state.txt` → Released
- No argument provided

**Expected behavior**:
1. Skill globs all `production/demo/*/state.txt`
2. Shows summary table of all campaigns with sub-stage
3. Shows detailed report for each campaign in turn
4. Each report ends with appropriate `/demo-gate` recommendation

**Assertions**:
- [ ] Summary table shown before per-campaign details
- [ ] Both campaigns appear in output
- [ ] Each campaign gets its own artifact cross-check
- [ ] `beta` (Released) shows next step as `/demo-gate beta publishing` (or stop if not EA)

**Case Verdict**: PASS

---

### Case 5: Early Access Campaign — Sub-stages 9 and 10 shown

**Fixture**:
- `production/demo/ea-demo/state.txt` contains `Publishing`
- `production/demo/ea-demo/demo-plan.md` contains `Early Access: true`
- EA store page live confirmation exists in `production/demo/ea-demo/`
- EA roadmap doc exists

**Expected behavior**:
1. Skill reads demo-plan.md, detects EA mode
2. Sub-stages 9 (Publishing) and 10 (Live) included in stage table
3. Checks Publishing-stage artifacts: store page live, pricing, roadmap communicated
4. Artifacts present → CONSISTENT, confidence HIGH
5. Next step: `/demo-gate ea-demo live`

**Assertions**:
- [ ] EA mode detected from demo-plan.md header
- [ ] Sub-stages 9 and 10 visible in the stage table in output
- [ ] Publishing-stage artifact list includes EA-specific items
- [ ] Non-EA campaign does not show sub-stages 9 or 10

**Case Verdict**: PASS

---

## Protocol Compliance

- [x] Read-only skill — no Write or Edit in allowed-tools; no "May I write" needed
- [x] Presents findings as advisory scan, not authoritative gate decision
- [x] Always reports confidence level (HIGH / MEDIUM / LOW)
- [x] Ends with `/demo-gate` recommendation for formal advancement
- [x] Never writes state.txt — explicitly documented in skill header

---

## Coverage Notes

- The CONSISTENT/DISCREPANCY status outputs are keywords used in the skill's output format, not YAML verdict fields. `/skill-test static` Check 3 may not detect these — verify manually if static check fails on verdict keyword detection.
- Confidence MEDIUM case (state.txt missing, inferred from artifacts) is not covered in these test cases — it requires a fixture with no state.txt but artifacts present.
- The model assigned is `haiku` — this skill should run cheaply; no heavy synthesis needed.
