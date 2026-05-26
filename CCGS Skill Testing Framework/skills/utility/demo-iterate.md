# Skill Spec: /demo-iterate

> **Category**: utility
> **Priority**: low
> **Spec written**: 2026-05-26

## Skill Summary

`/demo-iterate` is a thin orchestrator for targeted demo iteration. It pulls a specific blocker or all P1 blockers from the most recent `/demo-feedback` output, classifies each finding by resolution path (bug → `/bug-report`+`/dev-story`; onboarding failure → `/ux-review`+`/dev-story`; design-level → redirect to `/propagate-design-change`; polish → redirect to `/demo-polish`; implementation conversion blocker → `/dev-story` directly), scopes the minimum fix via a `lead-programmer` subagent, implements via `dev-story` or `bug-report`, and chains to `/demo-build` + `/demo-playtest` for verification. Each iteration is logged to `production/qa/demo-iterations.md` after approval. The skill accepts `--blocker N`, `--all-blockers`, or no argument (interactive selection from the priority list).

---

## Static Assertions

- [ ] Frontmatter has all required fields (`name`, `description`, `argument-hint`, `user-invocable`, `allowed-tools`)
- [ ] 2+ phase headings found
- [ ] At least one verdict keyword present (`COMPLETE`, `BLOCKED`, `PASS`)
- [ ] If `allowed-tools` includes Write/Edit: `"May I write"` language present
- [ ] Next-step handoff section present at end

---

## Director Gate Checks

- **N/A**: `/demo-iterate` does not invoke any director phase gate. It delegates implementation to `/dev-story` and `/bug-report` which may have their own gates. The `lead-programmer` scoping call is a functional subagent, not a gate. No gate IDs are defined.

---

## Test Cases

### Case 1: Happy Path — Single implementation conversion blocker resolved
**Fixture**:
- `production/qa/playtests/demo-feedback-2026-05-15.md` exists with 1 P1 blocker: "Demo title screen has no call to action — players don't know how to start"
- Blocker category: Conversion Blocker (implementation)
- `design/demo/demo-scope.md` and `design/gdd/game-concept.md` exist
- Skill invoked as `/demo-iterate --blocker 1`

**Expected behavior**:
1. Phase 0 resolves review mode (default: lean)
2. Phase 1 reads demo-scope.md, game-concept.md; globs feedback files; reads most recent
3. Phase 2 finds blocker 1; presents it; user confirms it is the correct target
4. Phase 3 classifies as "Conversion Blocker (implementation)" → resolution path: `/dev-story` directly
5. Phase 4 spawns `lead-programmer` via Task to scope minimum fix; lead-programmer returns root cause, minimum change, files touched, verification step, effort estimate
6. Scoped fix presented; user confirms
7. Phase 5 spawns `dev-story` via Task with scoped fix
8. Phase 6 asks: "How would you like to verify?" with rebuild+playtest / smoke check / manual / skip options
9. Phase 7 asks "May I log this iteration to `production/qa/demo-iterations.md`?"

**Assertions**:
- [ ] Blocker identified and presented before any action
- [ ] Classification and resolution path shown to user before spawning lead-programmer
- [ ] Lead-programmer scoped fix confirmed before spawning dev-story
- [ ] Verification options presented after implementation
- [ ] "May I log" asked before writing to demo-iterations.md
- [ ] Iteration log row includes: date, item, category, scoped fix, status, verification
**Case Verdict**: PASS

---

### Case 2: Failure — No feedback or playtest reports found
**Fixture**:
- `production/qa/playtests/` directory is empty or does not exist
- No `demo-feedback-*.md` or `demo-playtest-*.md` files exist

**Expected behavior**:
1. Phase 1 globs for demo-feedback files — none found
2. Phase 1 globs for demo-playtest files — none found
3. Skill outputs: "No demo feedback or playtest reports found. Run `/demo-playtest` to generate data before iterating — iterate targets known problems, not assumed ones."
4. Skill stops

**Assertions**:
- [ ] Error message references `/demo-playtest`
- [ ] No `AskUserQuestion` for blocker selection
- [ ] No lead-programmer Task spawned
- [ ] No file written
**Case Verdict**: PASS

---

### Case 3: Mode Variant — `--all-blockers` with mixed blocker types
**Fixture**:
- Feedback file has 3 P1 items:
  - Item 1: Bug (reproducible defect)
  - Item 2: Onboarding failure
  - Item 3: Design-level conversion blocker
- Skill invoked as `/demo-iterate --all-blockers`

**Expected behavior**:
1. Phase 2 extracts all 3 P1 items; presents list and asks "Address all 3 P1 blockers in this session?" with Yes/No options
2. User selects Yes
3. Phase 3 classifies each:
   - Item 1 (Bug): `/bug-report` → `/dev-story`
   - Item 2 (Onboarding failure): `/ux-review` recommended; user chooses to implement directly
   - Item 3 (Design-level): redirect message shown; item DEFERRED
4. Items 1 and 2 scoped and implemented; Item 3 logged as DEFERRED (design-level)
5. Phase 8 summary lists: 2 Implemented, 1 Deferred (design-level); warns to run `/propagate-design-change`

**Assertions**:
- [ ] All 3 P1 items presented before any action
- [ ] Design-level item produces redirect message, not implementation attempt
- [ ] DEFERRED items logged with reason
- [ ] Summary warns about `/propagate-design-change` for design-level deferrals
- [ ] Summary warns about `/ux-review` for any UX-level deferrals
**Case Verdict**: PASS

---

### Case 4: Edge Case — Lead-programmer flags [DESIGN CHANGE NEEDED]
**Fixture**:
- Feedback has 1 P1 item: "Combat feels unresponsive — players quit during first fight"
- Item classified as Conversion Blocker (implementation) initially
- Lead-programmer analysis reveals root cause is design-level (attack timing mechanic is wrong)

**Expected behavior**:
1. Phase 4 lead-programmer returns: [DESIGN CHANGE NEEDED] — attack timing is a design decision, not a code fix
2. Skill surfaces the flag; skips implementation for this item
3. Item logged as DEFERRED with reason: DESIGN-LEVEL (redirected to propagate-design-change)
4. Phase 8 summary includes `/propagate-design-change` warning

**Assertions**:
- [ ] [DESIGN CHANGE NEEDED] flag surfaced to user explicitly
- [ ] No dev-story spawned for the flagged item
- [ ] Item logged as DEFERRED (not IMPLEMENTED)
- [ ] `/propagate-design-change` recommended in summary
**Case Verdict**: PASS

---

### Case 5: Protocol — Iteration log approval gate
**Fixture**:
- 1 blocker implemented and verified via smoke check
- Review mode: lean

**Expected behavior**:
1. Phase 7 asks: "May I log this iteration to `production/qa/demo-iterations.md`?"
2. No auto-write; user must approve
3. If file exists: row appended (not full rewrite)
4. If demo-builds.md exists and a rebuild was triggered: reference noted in build log

**Assertions**:
- [ ] Uses "May I log" (equivalent to "May I write") before writing
- [ ] No auto-write without approval
- [ ] Row-append behavior (not full file rewrite) for existing log
- [ ] Iteration is a thin orchestrator — does not implement code directly itself
**Case Verdict**: PASS

---

## Protocol Compliance

- [ ] Uses `"May I write"` (or "May I log") before any file writes (or is read-only and skips this)
- [ ] Presents findings/draft to user before requesting approval
- [ ] Ends with a recommended next step or follow-up action
- [ ] Does not auto-create files without user approval

---

## Coverage Notes

- The UX path decision (run `/ux-review` first vs. implement directly) is user-driven and runtime-only.
- The "polish item" redirect to `/demo-polish` is a skip-and-log behavior; verifying that polish items don't get accidentally implemented here requires runtime testing.
- The interaction between this skill's rebuild trigger and the existing `demo-builds.md` log (cross-log reference) is runtime-only.
- `SubagentStop` hooks for `dev-story` drafts are handled within `dev-story` itself and are out of scope here.
