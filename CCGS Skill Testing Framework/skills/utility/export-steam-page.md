# Skill Spec: /export-steam-page

> **Category**: utility
> **Priority**: low
> **Spec written**: 2026-05-26

## Skill Summary

`/export-steam-page` compiles project materials into a dated Steam store page document. It reads `design/gdd/game-concept.md` (required), `design/gdd/systems-index.md`, and any art/aesthetic design docs, then asks the user two scoping questions (page stage and price point). It writes a structured Markdown file with game title, tagline, short description (max 160 chars), long description in Steam BB-code format, 15 prioritized tags, content flags, and a visual asset checklist with `[NEEDS]` flags. After writing, it automatically runs `/refine-copy` on the file in-place before presenting a COMPLETE verdict with next-step recommendations.

---

## Static Assertions

- [ ] Frontmatter has all required fields (`name`, `description`, `argument-hint`, `user-invocable`, `allowed-tools`)
- [ ] 2+ phase headings found
- [ ] At least one verdict keyword present (`PASS`, `FAIL`, `CONCERNS`, `APPROVED`, `BLOCKED`, `COMPLETE`, `READY`)
- [ ] If `allowed-tools` includes Write/Edit: `"May I write"` language present
- [ ] Next-step handoff section present at end

---

## Director Gate Checks

- **N/A**: No director or gate-check agent is invoked. The skill has one internal approval gate (Phase 3 write approval) handled via `"May I write"` prompt, but no external director verdict is required.

---

## Test Cases

### Case 1: Happy Path — Full Launch Page
**Fixture**:
- `design/gdd/game-concept.md` exists with title, fantasy, and comparables
- `design/gdd/systems-index.md` exists with feature set
- `production/publishing/writing-lessons.md` exists with tone rules
- User selects "Full launch (V1.0)" and "$10–$20"

**Expected behavior**:
1. Loads `writing-lessons.md` rules
2. Reads concept and systems docs
3. Asks page type and price via `AskUserQuestion`
4. Asks "May I write the Steam page document to `review/steam-page-[YYYY-MM-DD].md`?"
5. Writes file with all required sections including Steam BB-code formatting
6. Runs `/refine-copy` in-place automatically
7. Prints COMPLETE verdict with visual flag count and tag count

**Assertions**:
- [ ] Output file exists at `review/steam-page-[YYYY-MM-DD].md`
- [ ] Short description is max 160 characters
- [ ] Long description uses `[h2]`, `[list]`, `[*]` BB-code formatting
- [ ] Exactly 15 Steam tags generated
- [ ] Every visual asset is flagged `[NEEDS]`
- [ ] Verdict is `COMPLETE`
- [ ] Recommended next is `/press-outreach` or `/export-social`

**Case Verdict**: PASS

---

### Case 2: Failure — Missing Game Concept
**Fixture**:
- `design/gdd/game-concept.md` does not exist
- All other files may or may not exist

**Expected behavior**:
1. Attempts to read `game-concept.md`
2. Emits: "No game concept found. Run `/brainstorm` first."
3. Stops — no `AskUserQuestion` is triggered, no file is written

**Assertions**:
- [ ] Error message matches prescribed text exactly
- [ ] No `review/steam-page-*.md` file is created
- [ ] Skill halts before Phase 2

**Case Verdict**: PASS

---

### Case 3: Mode Variant — Coming Soon Page
**Fixture**:
- `design/gdd/game-concept.md` exists
- User selects "Coming Soon page (pre-launch awareness)" and "Not yet" for price
- No `writing-lessons.md` present

**Expected behavior**:
1. Skips writing-lessons load (file absent — no error)
2. Proceeds through questions, records "Coming Soon" type
3. Sets price field to "Not yet confirmed" or equivalent placeholder
4. Output includes reminder: "Steam requires a Coming Soon page to be live for at least 2 weeks before launch"
5. Verdict COMPLETE

**Assertions**:
- [ ] Output frontmatter says "Coming Soon" page type
- [ ] 2-week notice is present in confirmation output
- [ ] No crash when `writing-lessons.md` is absent

**Case Verdict**: PASS

---

### Case 4: Edge Case — systems-index.md Missing
**Fixture**:
- `design/gdd/game-concept.md` exists
- `design/gdd/systems-index.md` does not exist
- User proceeds through all prompts

**Expected behavior**:
1. Reads game-concept successfully
2. Attempts systems-index read — file absent, no hard stop (systems-index is not listed as required with a fail message)
3. Feature bullet section is written with available data or placeholder `[NEEDS]` entries
4. Skill completes with COMPLETE verdict

**Assertions**:
- [ ] Skill does not hard-stop on missing systems-index
- [ ] Feature bullets are present (even if sparse)
- [ ] `[NEEDS]` flags appear for missing visual assets

**Case Verdict**: PASS

---

### Case 5: Protocol — Write Approval Gate
**Fixture**:
- All required files exist
- User has answered both scoping questions
- Skill is at Phase 3 write step

**Expected behavior**:
1. Presents "May I write the Steam page document to `review/steam-page-[YYYY-MM-DD].md`?" before writing
2. If user declines, no file is written
3. `/refine-copy` is applied only after the file is written, without a second approval gate

**Assertions**:
- [ ] Uses "May I write" before file writes
- [ ] Presents content before approval
- [ ] No auto-write
- [ ] `/refine-copy` auto-runs without an additional approval prompt

**Case Verdict**: PASS

---

## Protocol Compliance

- [ ] Uses `"May I write"` before any file writes (or is read-only and skips this)
- [ ] Presents findings/draft to user before requesting approval
- [ ] Ends with a recommended next step or follow-up action
- [ ] Does not auto-create files without user approval

---

## Coverage Notes

- The `/refine-copy` sub-invocation is a runtime behavior — static analysis cannot verify the in-place edit was applied correctly, only that the SKILL.md specifies it.
- Tag quality (15 relevant tags vs. keyword-stuffed tags) is a runtime judgment call, not statically assertable.
- Price point placeholder text format is unspecified in the skill — test case 3 acceptance depends on runtime output inspection.
