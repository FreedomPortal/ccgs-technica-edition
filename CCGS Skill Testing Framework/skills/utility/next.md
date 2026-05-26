# Skill Spec: /next

> **Category**: utility
> **Priority**: low
> **Spec written**: 2026-05-26

## Skill Summary

`/next` is a read-only workflow navigator that determines where the user is in the game development pipeline and tells them what to do next. It reads `production/stage.txt` (or infers stage from artifact presence), the workflow catalog at `.claude/docs/workflow-catalog.yaml`, and `production/session-state/active.md` to produce a short, direct orientation report. It optionally accepts a freeform argument (e.g., "finished design-review", "stuck on ADRs") to personalize the output. The skill runs on the Haiku model and writes no files. Output includes: current phase, confirmed-complete steps, the single next required step with its slash command, optional steps available now, upcoming required steps, and an escalation footer if the user appears confused. Verdict is COMPLETE.

---

## Static Assertions

- [ ] Frontmatter has all required fields (`name`, `description`, `argument-hint`, `user-invocable`, `allowed-tools`)
- [ ] 2+ phase headings found
- [ ] At least one verdict keyword present (`COMPLETE`)
- [ ] `allowed-tools` does NOT include Write or Edit (skill is read-only)
- [ ] No `"May I write"` language present (read-only skill)
- [ ] Next-step handoff section present at end (escalation paths in Step 9)

---

## Director Gate Checks

- **N/A**: `/next` is a read-only orientation skill. It invokes no director agents and applies no gate logic. Its entire output is informational.

---

## Test Cases

### Case 1: Happy Path — Production stage with active sprint YAML
**Fixture**:
- `production/stage.txt` = `Production`
- `production/sprint-status.yaml` exists with one story `status: in-progress` and two `status: ready-for-dev`
- `production/session-state/active.md` contains a STATUS block with `Feature: Melee Combat`

**Expected behavior**:
1. Skill reads `workflow-catalog.yaml`, then `production/stage.txt` → maps to `production` phase
2. Reads `production/sprint-status.yaml` — surfaces in-progress story prominently
3. Reads `active.md` — shows "It looks like you were working on Melee Combat"
4. Presents output in the canonical format: Where You Are / Done / Next up / Also available / Coming up
5. Emits verdict: COMPLETE

**Assertions**:
- [ ] Phase shown as `Production`
- [ ] In-progress story is surfaced at top of output
- [ ] Single "Next up (REQUIRED)" step is shown
- [ ] No Write or Edit tool calls
- [ ] Verdict is COMPLETE

**Case Verdict**: PASS

---

### Case 2: Failure — No stage.txt, no artifacts
**Fixture**:
- `production/stage.txt` absent
- No `src/` files, no sprint files, no GDD files
- `active.md` absent

**Expected behavior**:
1. Skill cannot read stage.txt → falls back to artifact inference
2. No artifact matches any phase → defaults to `concept`
3. Output shows phase as Concept with the first required step (e.g., `/start` or `/brainstorm`)
4. No crash; verdict COMPLETE

**Assertions**:
- [ ] Skill does not crash or produce an error
- [ ] Phase defaults to `concept`
- [ ] At least one next-step recommendation is given
- [ ] Verdict is COMPLETE

**Case Verdict**: PASS

---

### Case 3: Mode Variant — User argument provided
**Fixture**:
- `production/stage.txt` = `Systems Design`
- Several GDD files exist; `design/gdd/systems-index.md` present
- Argument passed: `"finished design-review"`

**Expected behavior**:
1. Skill reads catalog and maps to `systems-design` phase
2. Uses argument to advance past the `design-review` step even if artifact check is ambiguous
3. Next required step reflects the step after design-review
4. Output acknowledges what the user just finished

**Assertions**:
- [ ] Argument is incorporated into step-position logic
- [ ] Completed step is listed under "Done" (not shown as Next)
- [ ] Next step is the one after design-review in the catalog sequence
- [ ] Verdict is COMPLETE

**Case Verdict**: PASS

---

### Case 4: Edge Case — All required steps complete, approaching gate
**Fixture**:
- `production/stage.txt` = `Pre-Production`
- All required pre-production artifacts present (epics, stories, architecture docs)
- No incomplete required steps remain in current phase

**Expected behavior**:
1. Skill detects no incomplete required steps
2. Gate warning is surfaced: "You're close to the Pre-Production → Production gate. Run `/gate-check` when ready."
3. Output still shows optional steps if any remain
4. Verdict is COMPLETE

**Assertions**:
- [ ] Gate warning referencing `/gate-check` is present in output
- [ ] No false "next required step" is fabricated
- [ ] Verdict is COMPLETE

**Case Verdict**: PASS

---

### Case 5: Protocol — Confused user triggers escalation footer
**Fixture**:
- `production/stage.txt` = `Technical Setup`
- User input includes "I'm totally lost"
- `active.md` absent

**Expected behavior**:
1. Skill detects confusion signal in user input
2. Standard orientation output is shown
3. Escalation footer is appended with `/project-stage-detect`, `/gate-check`, `/start`
4. No file writes occur

**Assertions**:
- [ ] Uses "May I write" language: N/A (read-only) — assertion passes trivially
- [ ] Escalation footer present in output
- [ ] Exactly one primary recommendation, not a list of six
- [ ] No auto-write
- [ ] Verdict is COMPLETE

**Case Verdict**: PASS

---

## Protocol Compliance

- [ ] Uses `"May I write"` before any file writes (or is read-only and skips this) — read-only, N/A
- [ ] Presents findings/draft to user before requesting approval — N/A (no approvals)
- [ ] Ends with a recommended next step or follow-up action
- [ ] Does not auto-create files without user approval

---

## Coverage Notes

- The uncataloged skill footer (Step 1b) is not covered by a dedicated case; it would only appear if installed skills exist that are absent from the catalog, which is fixture-intensive to simulate.
- MANUAL steps (artifact.note only, no glob) require human-in-the-loop to confirm completion; the skill is expected to ask the user rather than assume. This runtime behavior is not testable statically.
- The `sprint-status.yaml` fast-path (production phase) is tested in Case 1; the fallback glob-based story check for other phases is exercised in Cases 3 and 4.
- Tone matching (reassuring vs. brisk) based on user emotion is runtime-only behavior.
