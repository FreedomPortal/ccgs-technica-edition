# Skill Spec: /demo-scope

> **Category**: utility
> **Priority**: low
> **Spec written**: 2026-05-26

## Skill Summary

`/demo-scope` defines the scope of a game demo: exactly which content is included, which is locked/excluded, the target playthrough duration, save data handling, and how the demo ends. It reads the game concept GDD and any existing demo documents, then gathers four user answers (demo purpose, content boundary, end state, save handling) via a single `AskUserQuestion` batch. A `game-designer` subagent drafts the scope document with 8 required sections. In full review mode a `producer` checks feasibility (REALISTIC / CONCERNS / UNREALISTIC). The scope is written to `design/demo/demo-scope.md` after explicit approval. Output path: `design/demo/demo-scope.md`.

---

## Static Assertions

- [ ] Frontmatter has all required fields (`name`, `description`, `argument-hint`, `user-invocable`, `allowed-tools`)
- [ ] 2+ phase headings found
- [ ] At least one verdict keyword present (`REALISTIC`, `CONCERNS`, `UNREALISTIC`, `COMPLETE`)
- [ ] If `allowed-tools` includes Write/Edit: `"May I write"` language present
- [ ] Next-step handoff section present at end

---

## Director Gate Checks

- **N/A**: `/demo-scope` uses a producer feasibility check (REALISTIC / CONCERNS / UNREALISTIC) rather than a named director phase gate. The feasibility check only runs in full review mode; it is skipped in solo and lean modes (the default). No gate IDs are defined.

---

## Test Cases

### Case 1: Happy Path — Scope document produced for Steam Next Fest
**Fixture**:
- `design/gdd/game-concept.md` exists with MVP content list and core loop
- `production/publishing/publishing-roadmap.md` exists
- No existing `design/demo/demo-scope.md`
- User answers: Steam Next Fest / First act only / Hard stop with store redirect / Isolated save

**Expected behavior**:
1. Phase 1 reads game-concept.md; demo-scope.md not found (new run)
2. Phase 2 asks 4 questions in a single `AskUserQuestion` batch
3. Phase 3 spawns `game-designer` via Task; draft returned with 8 required sections
4. Draft presented; user approves
5. Phase 4 skipped (lean mode default)
6. Phase 5 asks "May I write the demo scope to `design/demo/demo-scope.md`?"
7. File written; Phase 6 summary shown

**Assertions**:
- [ ] All 8 sections present: Overview, Included Content, Excluded/Locked Content, Playthrough Flow, Target Playthrough Duration, Demo End State, Save Data Handling, Content Lock Implementation Notes, Demo-Specific Acceptance Criteria
- [ ] Included Content bullet list references GDD content by name (not invented content)
- [ ] Excluded content notes locking mechanism for each item
- [ ] Target Playthrough Duration has min/expected/max fields
- [ ] "May I write" asked before file write
- [ ] Summary shows included count, playthrough duration range, end state, save handling
- [ ] Next steps include `/demo-build`, `/demo-playtest`, `/demo-feedback`, `/demo-polish`
**Case Verdict**: PASS

---

### Case 2: Failure — Missing game concept GDD
**Fixture**:
- `design/gdd/game-concept.md` does not exist

**Expected behavior**:
1. Phase 1 attempts to read game-concept.md — not found
2. Skill outputs: "No game concept GDD found. Run `/design-system` first to establish the game's scope before defining a demo."
3. Skill stops; no questions asked, no subagents spawned, no file written

**Assertions**:
- [ ] Error message references `/design-system` (not `/brainstorm`)
- [ ] No `AskUserQuestion` calls made
- [ ] No `game-designer` Task spawned
- [ ] No file written
**Case Verdict**: PASS

---

### Case 3: Mode Variant — Full review mode triggers producer feasibility check
**Fixture**:
- `design/gdd/game-concept.md` exists
- `production/stage.txt` contains "Pre-Alpha"
- Skill invoked as `/demo-scope --review full`
- Draft produced and user approves

**Expected behavior**:
1. Phase 0 resolves review mode as `full`
2. Phases 1–3 proceed; draft approved
3. Phase 4: `producer` spawned to assess feasibility of included content, content locks, demo duration, and end state CTA
4. Producer returns REALISTIC / CONCERNS / UNREALISTIC
5. If UNREALISTIC: scope is revised before write
6. If CONCERNS: surfaced; user decides whether to adjust

**Assertions**:
- [ ] Phase 4 producer check runs (not skipped) in full mode
- [ ] Verdict keyword appears in output
- [ ] If UNREALISTIC: write gate does not proceed without revision
- [ ] If CONCERNS: concerns explicitly listed for user review
**Case Verdict**: PASS

---

### Case 4: Edge Case — Update run when demo-scope.md already exists
**Fixture**:
- `design/demo/demo-scope.md` already exists
- User invokes `/demo-scope` to revise scope

**Expected behavior**:
1. Phase 1 reads existing demo-scope.md; notes this is an update run
2. Phase 2 questions asked as normal (user may change any answer)
3. Phase 3 game-designer draft incorporates existing scope as baseline
4. Phase 5 asks approval before overwriting existing file

**Assertions**:
- [ ] Existing demo-scope.md is read and noted as an update run
- [ ] Existing scope is passed to game-designer as context
- [ ] "May I write" asked before overwriting
**Case Verdict**: PASS

---

### Case 5: Protocol — [DECISION NEEDED] flags used for unresolved scope questions
**Fixture**:
- `design/gdd/game-concept.md` exists but content list is vague
- User answers "Custom — I'll describe it" for content boundary with minimal detail

**Expected behavior**:
1. Phase 3 game-designer draft includes `[DECISION NEEDED]` markers for items that cannot be resolved from the GDD and user input
2. Draft presented with flagged items clearly marked
3. Phase 5 approval gate shows draft before "May I write" prompt
4. No content is invented beyond what is in the GDD

**Assertions**:
- [ ] `[DECISION NEEDED]` appears in draft where scope is ambiguous
- [ ] No content outside game-concept.md is silently invented
- [ ] "May I write" is asked; draft presented before approval prompt
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

- The 8-section structure of the scope document is enforced via the game-designer subagent prompt; static verification can only check that the prompt requests all sections.
- `[DECISION NEEDED]` flag generation is runtime-only; cannot be statically asserted.
- Content lock implementation complexity warnings (engineering work flags) are subagent output and not statically testable.
