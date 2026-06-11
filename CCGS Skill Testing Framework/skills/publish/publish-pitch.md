# Skill Spec: /publish-pitch

> **Category**: utility
> **Priority**: low
> **Spec written**: 2026-05-26

## Skill Summary

`/publish-pitch` compiles project materials into a publisher-ready, investor-ready, grant, or general pitch document. It accepts an optional `<target>` argument (publisher, investor, grant, general); if absent, it asks via `AskUserQuestion`. Tone and emphasis shift based on target. It reads `design/gdd/game-concept.md` (required), `design/gdd/systems-index.md`, milestone files, and any completed GDDs, then presents a pre-write summary and asks if anything should be added. The output is saved to `review/pitch-[target]-[YYYY-MM-DD].md` with nine structured sections. `/refine-copy` runs automatically in-place before a COMPLETE verdict is issued with comparables and ask summary.

---

## Static Assertions

- [ ] Frontmatter has all required fields (`name`, `description`, `argument-hint`, `user-invocable`, `allowed-tools`)
- [ ] 2+ phase headings found
- [ ] At least one verdict keyword present (`PASS`, `FAIL`, `CONCERNS`, `APPROVED`, `BLOCKED`, `COMPLETE`, `READY`)
- [ ] If `allowed-tools` includes Write/Edit: `"May I write"` language present
- [ ] Next-step handoff section present at end

---

## Director Gate Checks

- **N/A**: No director or external gate agent is invoked. The skill has an inline pre-write confirmation step (Phase 3) and a write approval gate (Phase 4), both handled within the skill itself.

---

## Test Cases

### Case 1: Happy Path — Publisher Pitch With Full Context
**Fixture**:
- Invoked as `/publish-pitch publisher`
- `design/gdd/game-concept.md` exists with title, comparables, and elevator pitch
- `design/gdd/systems-index.md` exists with scope tier
- `production/milestones/sprint-3.md` exists with current stage
- `production/publishing/writing-lessons.md` exists
- User selects "No, compile now" at Phase 3

**Expected behavior**:
1. Loads writing-lessons rules
2. Parses argument — target is "publisher"
3. Reads concept, systems, and milestones
4. Presents pre-write summary with title, comparables, scope tier, stage
5. Asks Phase 3 confirmation — user selects "No, compile now"
6. Asks "May I write the pitch document to `review/pitch-publisher-[YYYY-MM-DD].md`?"
7. Writes file with nine required sections, publisher-focused tone
8. Auto-applies `/refine-copy`
9. Reports COMPLETE with comparables used and ask summary

**Assertions**:
- [ ] File saved at `review/pitch-publisher-[YYYY-MM-DD].md`
- [ ] All nine sections present: Elevator Pitch, Market Opportunity, Core Loop, Unique Selling Point, Target Audience, Monetization, Scope & Timeline, Team, The Ask
- [ ] No superlatives ("revolutionary", "unique", "unlike anything")
- [ ] Market claims reference comparable titles
- [ ] Verdict is `COMPLETE`
- [ ] Recommended next includes `/publish-review` or `/press-outreach`

**Case Verdict**: PASS

---

### Case 2: Failure — Missing Game Concept
**Fixture**:
- `design/gdd/game-concept.md` does not exist
- Target argument provided or selected as "investor"

**Expected behavior**:
1. Attempts to read `game-concept.md`
2. Emits: "No game concept found. Run `/brainstorm` first."
3. Stops — no pitch is compiled, no file is written

**Assertions**:
- [ ] Error message matches prescribed text exactly
- [ ] No `review/pitch-*.md` file is created
- [ ] Skill halts at Phase 2

**Case Verdict**: PASS

---

### Case 3: Mode Variant — Grant Pitch
**Fixture**:
- Invoked with no argument
- All required files exist
- User selects "Grant / Fund" at Phase 1 question
- User selects "I want to specify the ask first" at Phase 3

**Expected behavior**:
1. Phase 1 `AskUserQuestion` fires because no argument was provided
2. User selects Grant
3. Tone shifts to focus on cultural/creative value, feasibility, milestone plan
4. Phase 3 "I want to specify the ask first" option: skill waits for the ask input before writing
5. File written with grant-appropriate framing in The Ask section

**Assertions**:
- [ ] Phase 1 question fires when no argument given
- [ ] "The Ask" section reflects grant framing (cultural value, not ROI)
- [ ] No `AskUserQuestion` is skipped due to argument pre-fill

**Case Verdict**: PASS

---

### Case 4: Edge Case — No Comparable Titles in Concept Doc
**Fixture**:
- `design/gdd/game-concept.md` exists but has no comparable titles listed
- All other files exist normally
- Pre-write summary shows "Comparable titles found: none"

**Expected behavior**:
1. Pre-write summary correctly reports "none" for comparables
2. Market Opportunity section flags the gap (no comparables to reference)
3. Skill still writes the full document — no hard stop
4. Verdict is COMPLETE

**Assertions**:
- [ ] Pre-write summary accurately reflects missing comparables
- [ ] Market Opportunity section is present (not skipped)
- [ ] No fabricated comparable titles in output

**Case Verdict**: PASS

---

### Case 5: Protocol — Write Approval Gate
**Fixture**:
- All context files exist
- User has completed Phase 3 confirmation
- Skill is at Phase 4 write step

**Expected behavior**:
1. Skill presents "May I write the pitch document to `review/pitch-[target]-[YYYY-MM-DD].md`?" before writing
2. No file is created if user declines
3. `/refine-copy` runs in-place after approval — no second approval gate

**Assertions**:
- [ ] Uses "May I write" before file writes
- [ ] Presents content before approval
- [ ] No auto-write
- [ ] `/refine-copy` runs without requesting second approval

**Case Verdict**: PASS

---

## Protocol Compliance

- [ ] Uses `"May I write"` before any file writes (or is read-only and skips this)
- [ ] Presents findings/draft to user before requesting approval
- [ ] Ends with a recommended next step or follow-up action
- [ ] Does not auto-create files without user approval

---

## Coverage Notes

- Tone differentiation between publisher / investor / grant / general is a runtime LLM behavior — static spec can only assert the correct sections exist.
- "No superlatives" rule is enforced via `/refine-copy` at runtime; static analysis cannot scan the generated text.
- The "I want to add a team bio section" Phase 3 option behavior (what the skill does with that input) is underspecified in SKILL.md and is a runtime-only gap.
