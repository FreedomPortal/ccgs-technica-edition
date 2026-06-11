# Skill Spec: /publish-crowdfunding

> **Category**: utility
> **Priority**: low
> **Spec written**: 2026-05-26

## Skill Summary

`/publish-crowdfunding` compiles project materials into a crowdfunding campaign document for Kickstarter or Indiegogo. It accepts an optional `<platform>` argument (defaults to Kickstarter). It reads `design/gdd/game-concept.md` (required), `design/gdd/systems-index.md`, and milestone files. It warns — but does not hard-stop — when no prototype or vertical slice is detected, then asks whether a playable build exists and what the funding target is. The output is saved to `review/crowdfunding-[platform]-[YYYY-MM-DD].md` with twelve sections including a reward tier table and a required Risks & Challenges section. `/refine-copy` runs in-place automatically before a COMPLETE verdict. Stretch goals section is conditional on scope expandability.

---

## Static Assertions

- [ ] Frontmatter has all required fields (`name`, `description`, `argument-hint`, `user-invocable`, `allowed-tools`)
- [ ] 2+ phase headings found
- [ ] At least one verdict keyword present (`PASS`, `FAIL`, `CONCERNS`, `APPROVED`, `BLOCKED`, `COMPLETE`, `READY`)
- [ ] If `allowed-tools` includes Write/Edit: `"May I write"` language present
- [ ] Next-step handoff section present at end

---

## Director Gate Checks

- **N/A**: No director or gate-check agent is invoked. The write gate in Phase 4 is an inline `"May I write"` prompt. The no-prototype warning is advisory, not a blocking gate.

---

## Test Cases

### Case 1: Happy Path — Kickstarter With Vertical Slice
**Fixture**:
- Invoked as `/publish-crowdfunding kickstarter`
- `design/gdd/game-concept.md` exists with core fantasy and comparables
- `design/gdd/systems-index.md` exists with scope tiers
- `production/milestones/vertical-slice.md` exists (prototype detected)
- `production/publishing/writing-lessons.md` exists
- User selects "Yes, vertical slice is ready" and "$5,000–$20,000"

**Expected behavior**:
1. Loads writing-lessons rules
2. Parses argument — platform is Kickstarter
3. Reads game-concept — OK, no fail
4. Detects vertical slice milestone — no warning issued
5. Asks playable build status and funding target via `AskUserQuestion`
6. Reads systems-index and milestones for scope/unlock levels
7. Asks "May I write the campaign document to `review/crowdfunding-kickstarter-[YYYY-MM-DD].md`?"
8. Writes twelve-section document with reward tier table and Risks section
9. Auto-applies `/refine-copy`
10. Reports COMPLETE with reward tier count and visual flag count

**Assertions**:
- [ ] File saved at `review/crowdfunding-kickstarter-[YYYY-MM-DD].md`
- [ ] All major sections present: Campaign Headline, The Hook, What Is This Game, Why This Game Needs to Exist, What's Already Built, What Your Funding Enables, Reward Tiers, About the Developer, Risks & Challenges
- [ ] Reward tier table has at least five rows
- [ ] Risks & Challenges section is present and non-empty
- [ ] At least one `[NEEDS: asset description]` flag present
- [ ] Verdict is `COMPLETE`
- [ ] Follow-up note to validate reward tiers with `/scope-check` present

**Case Verdict**: PASS

---

### Case 2: Failure — Missing Game Concept
**Fixture**:
- `design/gdd/game-concept.md` does not exist
- Platform argument provided

**Expected behavior**:
1. Reads `game-concept.md` — absent
2. Emits: "No game concept found. Run `/brainstorm` first."
3. Stops — no file written

**Assertions**:
- [ ] Error message matches prescribed text
- [ ] No `review/crowdfunding-*.md` created
- [ ] Skill halts at Phase 1

**Case Verdict**: PASS

---

### Case 3: Mode Variant — No Prototype Warning + Indiegogo
**Fixture**:
- Invoked as `/publish-crowdfunding indiegogo`
- `design/gdd/game-concept.md` exists
- No prototype or vertical slice milestone detected
- User selects "No build yet — planning ahead" and "Under $5,000"
- `production/publishing/writing-lessons.md` does not exist

**Expected behavior**:
1. No writing-lessons — skipped without error
2. Platform set to Indiegogo
3. No prototype detected — emits advisory warning:
   "⚠️ No prototype milestone detected. Crowdfunding before a playable build significantly reduces backer confidence."
4. `AskUserQuestion` for build status fires, user selects "No build yet"
5. Funding target selected as "Under $5,000"
6. File written as `review/crowdfunding-indiegogo-[YYYY-MM-DD].md`
7. Verdict COMPLETE

**Assertions**:
- [ ] No-prototype warning is emitted (advisory, not blocking)
- [ ] Skill continues after warning
- [ ] Output file uses "indiegogo" in filename
- [ ] "What's Already Built" section reflects no current build honestly

**Case Verdict**: PASS

---

### Case 4: Edge Case — "Help Me Estimate" Funding Target
**Fixture**:
- All required files exist
- User selects "Not yet — help me estimate" for funding target

**Expected behavior**:
1. Skill detects "help me estimate" selection
2. Emits note: the skill cannot calculate funding reliably without cost data — recommends `/estimate` with producer agent
3. Skill may proceed with a placeholder funding target or ask for a manual input
4. Campaign document is written (skill does not hard-stop on this choice)

**Assertions**:
- [ ] `/estimate` recommendation is surfaced
- [ ] Skill does not hard-stop on "help me estimate"
- [ ] Campaign document is still produced

**Case Verdict**: PASS

---

### Case 5: Protocol — Write Approval Gate
**Fixture**:
- All context files exist
- Both `AskUserQuestion` prompts answered
- Skill is at Phase 4 write step

**Expected behavior**:
1. Presents "May I write the campaign document to `review/crowdfunding-[platform]-[YYYY-MM-DD].md`?" before writing
2. No file created if user declines
3. `/refine-copy` runs in-place after write — no second approval needed

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

- "Never promise what solo dev can't deliver" is a judgment rule enforced at runtime by the LLM and `/refine-copy`; static analysis cannot verify it.
- Stretch goals section is conditional ("if applicable") — runtime testing should verify it is omitted when scope is not expandable, not always included.
- Reward tier deliverability validation note (`/scope-check`) appears after the COMPLETE verdict — static test should confirm this note is present in the completion output.
- No-prototype detection mechanism is unspecified: the skill reads milestone files, but the exact detection logic (what counts as "prototype or vertical slice exists") is a runtime behavior.
