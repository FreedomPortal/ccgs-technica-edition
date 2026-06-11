# Skill Spec: /publish-review

> **Category**: utility
> **Priority**: low
> **Spec written**: 2026-05-26

## Skill Summary

`/publish-review` compiles the current project state into a clean external review document for outside consultants, advisors, or collaborators. It requires both `design/gdd/game-concept.md` and `design/gdd/systems-index.md` (failing with prescribed messages if either is missing), then optionally reads `active.md` and milestone files. It presents a pre-write summary of what was found and asks the reviewer's focus area. The output is saved to `review/review-export-[YYYY-MM-DD].md` with five sections: Project Snapshot, Core Concept & Loop, Systems Status (table), Current Focus, and Open Questions (flagged with ❓). `/refine-copy` runs automatically in-place before a COMPLETE verdict. Notably, this skill does not include `AskUserQuestion` in its `allowed-tools` — Phase 2 interaction uses a different mechanism or is a static prompt.

---

## Static Assertions

- [ ] Frontmatter has all required fields (`name`, `description`, `argument-hint`, `user-invocable`, `allowed-tools`)
- [ ] 2+ phase headings found
- [ ] At least one verdict keyword present (`PASS`, `FAIL`, `CONCERNS`, `APPROVED`, `BLOCKED`, `COMPLETE`, `READY`)
- [ ] If `allowed-tools` includes Write/Edit: `"May I write"` language present
- [ ] Next-step handoff section present at end

---

## Director Gate Checks

- **N/A**: No director or gate-check agent is invoked. The single write gate is the inline `"May I write"` prompt in Phase 3. The Phase 2 scope confirmation is a pre-write check with options, but no external verdict agent is involved.

---

## Test Cases

### Case 1: Happy Path — Full Context Available
**Fixture**:
- `design/gdd/game-concept.md` exists with title, genre, platform
- `design/gdd/systems-index.md` exists with 6 systems (3 designed, 3 undesigned)
- `production/session-state/active.md` exists with current sprint context
- `production/milestones/sprint-2.md` exists
- Multiple system GDDs exist in `design/gdd/`
- `production/publishing/writing-lessons.md` exists
- User selects "No, compile everything"

**Expected behavior**:
1. Loads writing-lessons rules
2. Reads concept, systems, session state, milestones, globs GDDs
3. Presents pre-write summary: game title, systems count, latest sprint, open questions count
4. User confirms "No, compile everything"
5. Asks "May I write the review document to `review/review-export-[YYYY-MM-DD].md`?"
6. Writes five-section document with systems status table and ❓ flags
7. Auto-applies `/refine-copy`
8. Reports COMPLETE with open question count

**Assertions**:
- [ ] File saved at `review/review-export-[YYYY-MM-DD].md`
- [ ] All five sections present: Project Snapshot, Core Concept & Loop, Systems Status, Current Focus, Open Questions
- [ ] Systems Status section is a table with Status column
- [ ] Open questions flagged with ❓
- [ ] No agent names, tool names, or MDA terminology in output
- [ ] Verdict is `COMPLETE`

**Case Verdict**: PASS

---

### Case 2: Failure — Missing game-concept.md
**Fixture**:
- `design/gdd/game-concept.md` does not exist
- `design/gdd/systems-index.md` exists

**Expected behavior**:
1. Attempts to read `game-concept.md`
2. Emits: "No game concept found. Run `/brainstorm` first."
3. Stops — no file written

**Assertions**:
- [ ] Error message matches prescribed text
- [ ] No `review/review-export-*.md` created
- [ ] Skill halts before Phase 2

**Case Verdict**: PASS

---

### Case 3: Failure — Missing systems-index.md
**Fixture**:
- `design/gdd/game-concept.md` exists
- `design/gdd/systems-index.md` does not exist

**Expected behavior**:
1. Reads `game-concept.md` successfully
2. Attempts to read `systems-index.md`
3. Emits: "No systems index found. Run `/map-systems` first."
4. Stops — no file written

**Assertions**:
- [ ] Error message matches prescribed text exactly
- [ ] No `review/review-export-*.md` created
- [ ] Skill halts at Phase 1

**Case Verdict**: PASS

---

### Case 4: Edge Case — No Open Questions, No Optional Files
**Fixture**:
- Both required files exist with no open/unresolved questions marked
- `production/session-state/active.md` does not exist
- No milestone files exist
- No additional system GDDs exist beyond the systems-index

**Expected behavior**:
1. Optional files gracefully absent — no crash
2. Pre-write summary shows "Latest sprint: not found" and "Open questions: none"
3. Open Questions section in output reads: "No open questions at this time."
4. Verdict COMPLETE

**Assertions**:
- [ ] Skill does not crash on missing optional files
- [ ] Open Questions section contains prescribed "none" text when empty
- [ ] Systems Status shows "Undesigned" for systems without GDDs

**Case Verdict**: PASS

---

### Case 5: Protocol — Write Approval Gate
**Fixture**:
- Both required files exist
- Pre-write summary has been shown
- User has answered the focus question
- Skill is at Phase 3 write step

**Expected behavior**:
1. Presents "May I write the review document to `review/review-export-[YYYY-MM-DD].md`?" before writing
2. No file is written if user declines
3. `/refine-copy` runs in-place after write without a second approval gate

**Assertions**:
- [ ] Uses "May I write" before file writes
- [ ] Presents findings/draft to user before requesting approval
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

- `AskUserQuestion` is not in `allowed-tools` for this skill, yet Phase 2 describes presenting options ("No, compile everything", "Flag open design questions only", "Focus on core loop and systems status"). This is a potential static conformance issue — the skill may rely on inline question text rather than the `AskUserQuestion` tool. Runtime testing should verify how Phase 2 interaction actually fires.
- "No agent names, tool names, internal shorthand" constraint is runtime-only; static analysis cannot scan generated prose.
- The ❓ flag count in the completion summary depends on runtime detection of unresolved questions in GDDs.
