# Skill Spec: /log-lesson

> **Category**: utility
> **Priority**: low
> **Spec written**: 2026-05-26

## Skill Summary

`/log-lesson` encodes a lesson learned from external feedback into a persistent project knowledge base at `production/publishing/writing-lessons.md`. It is invoked after receiving critique from consultants, playtesters, press, or any external reviewer. The skill accepts an optional source argument (e.g., `press-kit-review`, `playtest-1`). It reads the existing knowledge base to prevent duplicates, gathers the lesson via conversation and `AskUserQuestion`, formats it into a structured markdown entry (Context / Problem / Rule / Example), shows the draft to the user, and appends it to the knowledge base only after explicit write approval. It then offers to log additional lessons from the same session. All export skills read `writing-lessons.md` before generating output. Verdict is COMPLETE.

---

## Static Assertions

- [ ] Frontmatter has all required fields (`name`, `description`, `argument-hint`, `user-invocable`, `allowed-tools`)
- [ ] 2+ phase headings found
- [ ] At least one verdict keyword present (`COMPLETE`)
- [ ] `allowed-tools` includes Write and Edit
- [ ] `"May I"` write-approval language present (Step 5: "May I append this lesson to...")
- [ ] Next-step handoff section present at end (Step 6: offer to log more)

---

## Director Gate Checks

- **N/A**: `/log-lesson` is a knowledge-encoding utility. It applies no director-level gates and spawns no director agents. The only gate is user write approval in Step 5.

---

## Test Cases

### Case 1: Happy Path — Lesson logged with existing knowledge base
**Fixture**:
- `production/publishing/writing-lessons.md` exists with at least one prior lesson
- User invokes `/log-lesson press-kit-review`
- User describes a Writing & Tone lesson during conversation

**Expected behavior**:
1. Skill parses argument → source label = `press-kit-review`
2. Reads existing `writing-lessons.md`; shows it is already initialized
3. Asks user to describe the feedback (open-ended in conversation)
4. Uses `AskUserQuestion` to confirm category → user selects "Writing & Tone"
5. Formats lesson entry with date, source, Context, Problem, Rule, and Example blocks
6. Shows formatted lesson and asks confirmation via `AskUserQuestion`
7. User selects "Yes, write it"
8. Asks: "May I append this lesson to `production/publishing/writing-lessons.md`?"
9. Appends to Writing & Tone section; confirms "Lesson encoded."
10. Asks if there are more lessons; user selects "No"
11. Verdict: COMPLETE

**Assertions**:
- [ ] Source label matches argument (`press-kit-review`)
- [ ] Formatted entry includes Context, Problem, Rule, and Example fields
- [ ] "May I append" language used before write
- [ ] Lesson appended to correct category section
- [ ] Verdict is COMPLETE

**Case Verdict**: PASS

---

### Case 2: Failure — No argument provided
**Fixture**:
- `production/publishing/writing-lessons.md` exists
- User invokes `/log-lesson` with no argument

**Expected behavior**:
1. Skill detects missing argument
2. Asks: "What is the source of this feedback?" with example options
3. User provides source label in response
4. Flow continues normally from Step 2 onward

**Assertions**:
- [ ] Source prompt is shown when argument is absent
- [ ] Skill does not crash or assume a default source
- [ ] Flow proceeds identically to Case 1 after source is provided
- [ ] Verdict is COMPLETE

**Case Verdict**: PASS

---

### Case 3: Mode Variant — Knowledge base does not exist (first lesson)
**Fixture**:
- `production/publishing/writing-lessons.md` does not exist
- User invokes `/log-lesson playtest-1`
- User describes a Game Design Decision lesson

**Expected behavior**:
1. Skill reads knowledge base → file absent; notes it will be created
2. Gathers lesson, user selects category "Game Design Decision"
3. Formats lesson entry
4. Asks "May I append this lesson to `production/publishing/writing-lessons.md`?"
5. Because file does not exist: creates file using full knowledge base template (all 4 section headers)
6. Appends lesson to Game Design Decisions section
7. Confirms: "Lesson encoded. All export skills will apply this rule going forward."
8. Verdict: COMPLETE

**Assertions**:
- [ ] Knowledge base template is used to create the file on first run
- [ ] All 4 section headers present in newly created file
- [ ] Lesson appears under correct section
- [ ] "May I" language used before file creation
- [ ] Verdict is COMPLETE

**Case Verdict**: PASS

---

### Case 4: Edge Case — User requests wording adjustment before write
**Fixture**:
- `production/publishing/writing-lessons.md` exists
- User invokes `/log-lesson publisher-meeting`
- After seeing the formatted lesson, user selects "Let me adjust the wording first"

**Expected behavior**:
1. Skill formats and presents lesson
2. `AskUserQuestion` is used for confirmation; user selects "Let me adjust the wording first"
3. Skill asks which part to adjust and applies the change
4. Re-presents the revised lesson
5. User then selects "Yes, write it"
6. Write proceeds normally

**Assertions**:
- [ ] Adjustment loop does not skip the write-approval gate
- [ ] Revised lesson (not original) is what gets written
- [ ] "May I append" language still used on the corrected version
- [ ] Verdict is COMPLETE

**Case Verdict**: PASS

---

### Case 5: Protocol — Write approval gate is enforced
**Fixture**:
- `production/publishing/writing-lessons.md` exists
- Full lesson gathered and formatted

**Expected behavior**:
1. Formatted lesson is shown to user before any write occurs
2. `AskUserQuestion` presents options including "Yes, write it"
3. "May I append this lesson to `production/publishing/writing-lessons.md`?" is asked
4. No write occurs unless user explicitly approves

**Assertions**:
- [ ] Uses "May I" before file writes
- [ ] Presents formatted lesson content before requesting approval
- [ ] No auto-write (file unchanged if user declines)
- [ ] Verdict is COMPLETE even if user declines (graceful exit)

**Case Verdict**: PASS

---

## Protocol Compliance

- [ ] Uses `"May I write"` / `"May I append"` before any file writes
- [ ] Presents formatted lesson draft to user before requesting approval
- [ ] Ends with a recommended next step or follow-up action (offer to log more)
- [ ] Does not auto-create files without user approval

---

## Coverage Notes

- The "Add another lesson from the same session" flow (loop back to Step 3) is not given a dedicated case; it is implied by Case 1's Step 6 and the presence of the `AskUserQuestion` option.
- Anti-Pattern category lessons are not covered by a dedicated case but follow the same flow as other categories.
- The skill reads the existing knowledge base to prevent duplicates, but no deduplication logic is specified; duplicate detection is runtime-only behavior not testable statically.
- The exact formatting of the knowledge base template (game title, studio name) depends on project metadata that may require reading other project files; this is not specified in the SKILL.md and is untestable statically.
