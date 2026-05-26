# Skill Spec: /post-mortem

> **Category**: sprint
> **Priority**: low
> **Spec written**: 2026-05-26

## Skill Summary

`/post-mortem` runs a structured retrospective after a milestone or stage transition. It accepts an optional milestone argument (e.g., `pre-production`, `sprint-3`) or asks the user to select from a list. Evidence is gathered by reading stage, milestone definitions, sprint files, gate check reports, prior post-mortems, and session logs. A `producer` subagent is spawned to produce a concise (under 2 pages) post-mortem covering what was planned, what was delivered, scope creep, what went well, what went wrong, time estimate accuracy, technical decision verdicts, one concrete process change, and carry-forward items. The output is presented for review before being written to `production/postmortems/[milestone-slug]-[YYYY-MM-DD].md`.

---

## Static Assertions

- [ ] Frontmatter has all required fields (`name`, `description`, `argument-hint`, `user-invocable`, `allowed-tools`)
- [ ] 2+ phase headings found
- [ ] At least one verdict keyword present (`PASS`, `FAIL`, `CONCERNS`, `APPROVED`, `BLOCKED`, `COMPLETE`, `READY`)
- [ ] If `allowed-tools` includes Write/Edit: `"May I write"` language present
- [ ] Next-step handoff section present at end

---

## Director Gate Checks

- **N/A**: `/post-mortem` does not issue a director gate verdict. The `producer` subagent writes the retrospective content. The most important output is the "One Concrete Process Change" — the skill mandates it be specific and testable, but the gate enforcement is the skill author's instruction to the agent, not a formal director check.

---

## Test Cases

### Case 1: Happy Path — Alpha milestone with full evidence
**Fixture**:
- `/post-mortem alpha` invoked
- `production/stage.txt` contains "Alpha"
- `production/milestones/alpha.md` exists with defined goals
- `production/sprints/` contains 3 sprint files covering the alpha period
- `production/gate-checks/alpha-gate.md` exists
- `production/postmortems/pre-production-2026-02-10.md` exists (prior post-mortem)

**Expected behavior**:
1. Phase 1 parses "alpha" argument — stores as MILESTONE
2. Phase 1 reads all evidence files (stage, milestones, sprints, gate checks, prior post-mortems)
3. Phase 1 summarizes planned vs. delivered internally
4. Phase 2 spawns `producer` agent with all evidence substituted into prompt
5. Agent produces post-mortem with all 9 required sections, under 2 pages
6. Post-mortem presented to user for review
7. Phase 3 asks "May I write the post-mortem to `production/postmortems/alpha-[DATE].md`?"
8. File written after confirmation with correct filename format
9. Phase 4 outputs summary with `Verdict: COMPLETE` and repeats the process change

**Assertions**:
- [ ] Argument used without prompting
- [ ] Evidence read from all 5 source categories
- [ ] Agent output includes "One Concrete Process Change" section
- [ ] Process change is specific (not "communicate better") — flagged if vague
- [ ] Filename uses milestone-slug + YYYY-MM-DD format
- [ ] Summary repeats the process change

**Case Verdict**: PASS

---

### Case 2: Failure — No evidence files exist
**Fixture**:
- No argument passed
- `production/stage.txt` missing
- `production/milestones/` empty
- `production/sprints/` empty
- `production/gate-checks/` empty

**Expected behavior**:
1. Phase 1 finds no milestone argument — asks user to select milestone
2. All evidence reads return empty / not found
3. Skill does NOT stop — falls back to verbal description per Collaborative Protocol
4. User is asked to summarize what was planned and what was delivered
5. Agent spawned with user-provided summary as sole evidence

**Assertions**:
- [ ] Skill continues without stopping when evidence is absent
- [ ] User prompted to provide verbal summary
- [ ] Agent spawned with user-provided context

**Case Verdict**: PASS

---

### Case 3: Mode Variant — Sprint-specific retrospective
**Fixture**:
- No argument passed
- User selects "Sprint [N]" and types "sprint-4"
- `production/sprints/sprint-4.md` exists
- `production/gate-checks/` has no sprint-4 entry

**Expected behavior**:
1. Phase 1 AskUserQuestion shown with milestone options
2. User selects "Sprint [N]" and types "sprint-4"
3. MILESTONE set to "sprint-4"
4. `production/sprints/sprint-4.md` read; gate check returns empty
5. Agent spawned with available evidence (sprint file only)
6. Output filename: `sprint-4-[YYYY-MM-DD].md`

**Assertions**:
- [ ] Free-text entry accepted for sprint number
- [ ] Filename slug derived correctly: "sprint-4"
- [ ] Missing gate check does not stop the skill

**Case Verdict**: PASS

---

### Case 4: Edge Case — Vague process change triggers retry
**Fixture**:
- Full evidence state; agent spawned
- Agent first draft contains: "8. One Concrete Process Change: Communicate better with stakeholders"

**Expected behavior**:
1. Skill (or orchestrating agent) detects the process change is vague / unmeasurable
2. Producer is asked to revise with a specific, testable change
3. Revised draft presented before write gate
4. Final document contains concrete, testable process change

**Assertions**:
- [ ] Vague process change detected and flagged
- [ ] Producer prompted to revise
- [ ] Final document process change is specific and testable

**Case Verdict**: PASS

---

### Case 5: Protocol — Write approval gate
**Fixture**:
- Full happy-path state; agent output received and reviewed

**Expected behavior**:
1. Post-mortem content presented to user before write is requested
2. Phase 3 asks "May I write the post-mortem to `production/postmortems/[filename]`?"
3. No file written until user confirms

**Assertions**:
- [ ] Uses "May I write" before file writes
- [ ] Presents content before approval
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

- The "2 pages max" enforcement is a runtime instruction to the agent — static analysis can confirm the instruction is present in the prompt but cannot verify the agent honors it.
- Vague process change detection (Case 4) relies on the parent skill or the agent itself recognizing "communicate better" as non-testable — this is a judgment call that varies by LLM output.
- Session log reading is listed in Phase 1 but session logs are gitignored; in CI/test environments this directory may always be empty.
- Prior post-mortem comparison is evidence-driven — the skill reads them but does not prescribe how trend analysis is surfaced; this is agent-discretion behavior.
