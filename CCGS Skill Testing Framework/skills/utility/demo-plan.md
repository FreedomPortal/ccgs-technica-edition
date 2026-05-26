# Skill Spec: /demo-plan

> **Category**: utility
> **Priority**: low
> **Spec written**: 2026-05-26

## Skill Summary

`/demo-plan` plans the demo production effort for a game project. It reads the game concept GDD, publishing roadmap, and any existing demo documents, then gathers four user answers via `AskUserQuestion` (target event, hard deadline, team capacity, priority relationship). A `producer` subagent drafts a demo production plan covering overview, goals, target event, milestones, effort estimate, risk register, and demo-specific constraints. In full review mode a second producer pass validates feasibility (REALISTIC / CONCERNS / UNREALISTIC). The plan is written to `design/demo/demo-plan.md` after explicit approval. The skill accepts an optional `--review full|lean|solo` flag and defaults to lean. Output path: `design/demo/demo-plan.md`.

---

## Static Assertions

- [ ] Frontmatter has all required fields (`name`, `description`, `argument-hint`, `user-invocable`, `allowed-tools`)
- [ ] 2+ phase headings found
- [ ] At least one verdict keyword present (`REALISTIC`, `CONCERNS`, `UNREALISTIC`, `COMPLETE`)
- [ ] If `allowed-tools` includes Write/Edit: `"May I write"` language present
- [ ] Next-step handoff section present at end

---

## Director Gate Checks

- **N/A**: `/demo-plan` uses a producer feasibility check (REALISTIC / CONCERNS / UNREALISTIC) rather than a director phase gate. The check is skipped in solo and lean modes (the default). No named gate IDs are used.

---

## Test Cases

### Case 1: Happy Path — Full plan produced from game concept
**Fixture**:
- `design/gdd/game-concept.md` exists with core loop, MVP content, and scope
- `production/publishing/publishing-roadmap.md` exists with Steam Next Fest entry
- `production/stage.txt` exists (e.g., "Alpha")
- No existing `design/demo/demo-plan.md`
- User answers: Steam Next Fest / fixed date in 10 weeks / solo developer / demo is top priority

**Expected behavior**:
1. Phase 1 reads game-concept.md, publishing-roadmap.md, stage.txt without error
2. Phase 2 asks 4 questions via a single `AskUserQuestion` batch call
3. Phase 3 spawns `producer` via Task with full context; draft plan returned with all 6 required sections
4. Draft presented to user; user approves
5. Phase 4 skipped (lean mode default)
6. Phase 5 asks "May I write the demo production plan to `design/demo/demo-plan.md`?"
7. File written; Phase 6 summary shown

**Assertions**:
- [ ] All 6 plan sections present: Overview, Goals, Target Event/Window, Milestones, Effort Estimate, Risk Register
- [ ] Milestones reference the 9 recommended milestones (or a subset adjusted for solo/timeline)
- [ ] Risk Register contains 4–6 entries
- [ ] "May I write" is asked before writing
- [ ] Summary shows output path, target event, go-live date, total milestones, estimated effort, and top 2 risks
- [ ] Next steps include `/demo-scope`, `/demo-build`, `/demo-playtest`
**Case Verdict**: PASS

---

### Case 2: Failure — Missing game concept GDD
**Fixture**:
- `design/gdd/game-concept.md` does not exist
- All other files absent

**Expected behavior**:
1. Phase 1 attempts to read `design/gdd/game-concept.md` — file not found
2. Skill outputs: "No game concept GDD found. Run `/brainstorm` and `/design-system` first to establish the game before planning a demo."
3. Skill stops; no questions asked, no file written

**Assertions**:
- [ ] Specific error message referencing `/brainstorm` and `/design-system` shown
- [ ] No `AskUserQuestion` calls made
- [ ] No file written
- [ ] Skill halts after the error
**Case Verdict**: PASS

---

### Case 3: Mode Variant — Full review mode triggers producer feasibility gate
**Fixture**:
- `design/gdd/game-concept.md` exists
- `production/review-mode.txt` does not exist
- Skill invoked as `/demo-plan --review full`
- Draft plan produced; user approves

**Expected behavior**:
1. Phase 0 resolves review mode as `full` from CLI argument
2. Phases 1–3 proceed normally; draft produced and approved
3. Phase 4: second producer pass is spawned to assess achievability, effort order of magnitude, and risk register coverage
4. Producer returns REALISTIC / CONCERNS / UNREALISTIC verdict
5. If REALISTIC: proceed to Phase 5 write gate
6. If CONCERNS: concerns surfaced before writing

**Assertions**:
- [ ] Phase 4 producer pass is invoked (not skipped) when `--review full`
- [ ] Verdict keyword (REALISTIC / CONCERNS / UNREALISTIC) appears in output
- [ ] Concerns surfaced if verdict is CONCERNS
- [ ] File write does not proceed if verdict is UNREALISTIC without user decision
**Case Verdict**: PASS

---

### Case 4: Edge Case — Re-plan run when demo-plan.md already exists
**Fixture**:
- `design/demo/demo-plan.md` already exists with milestone status
- `design/demo/demo-scope.md` also exists
- User invokes `/demo-plan` (no argument)

**Expected behavior**:
1. Phase 1 reads existing demo-plan.md; notes this is an update run
2. Phase 1 reads demo-scope.md for scope context and includes it in the producer prompt
3. Phase 2 asks the 4 questions normally (user may update answers)
4. Phase 3 producer draft accounts for current milestone status and existing scope
5. Phase 5 asks approval before overwriting the existing file

**Assertions**:
- [ ] Existing `demo-plan.md` is read and acknowledged as an update run
- [ ] Existing `demo-scope.md` content is included in the producer prompt
- [ ] Current milestone status from the existing plan is passed to the producer
- [ ] "May I write" is asked before overwriting
**Case Verdict**: PASS

---

### Case 5: Protocol — Approval gate before file write
**Fixture**:
- `design/gdd/game-concept.md` exists
- Plan draft produced and user approves content
- Review mode: lean (default)

**Expected behavior**:
1. Phases 1–3 complete; plan draft finalized
2. Phase 4 skipped (lean)
3. Phase 5 asks: "May I write the demo production plan to `design/demo/demo-plan.md`?"
4. No file is written until user responds affirmatively
5. If user declines: no file created; session ends cleanly

**Assertions**:
- [ ] Uses "May I write" before any file write
- [ ] Presents full plan draft before requesting approval
- [ ] No auto-write occurs
- [ ] If declined, no file is created
**Case Verdict**: PASS

---

## Protocol Compliance

- [ ] Uses `"May I write"` before any file writes (or is read-only and skips this)
- [ ] Presents findings/draft to user before requesting approval
- [ ] Ends with a recommended next step or follow-up action
- [ ] Does not auto-create files without user approval

---

## Coverage Notes

- The `[DECISION NEEDED]` flag behavior (when user answers leave key questions open) is runtime-only and cannot be statically verified.
- Effort estimate accuracy is inherently runtime-dependent on the producer subagent's output.
- The `--review solo` mode (no gate, note emitted) is symmetric with lean and not separately tested since the behavior difference is identical to lean for this skill.
