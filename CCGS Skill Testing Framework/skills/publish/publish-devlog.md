# Skill Spec: /publish-devlog

> **Category**: utility
> **Priority**: low
> **Spec written**: 2026-05-26

## Skill Summary

`/publish-devlog` generates a developer blog post from recent sprint activity. It accepts an optional devlog number argument; if omitted, it globs existing devlogs and auto-increments the number. It reads `production/session-state/active.md`, milestone files, any completed GDDs, and the previous devlog for tone continuity, then asks the user for target platform and tone preference. The output is saved to `production/publishing/devlog-[N]-[YYYY-MM-DD].md` with a structured four-section format (What I Built, A Problem I Solved, A Decision I Made, What's Next), automatically refined in-place via `/refine-copy`. Visual asset gaps are flagged with `[NEEDS: screenshot / GIF / video]`. Ends with a COMPLETE verdict.

---

## Static Assertions

- [ ] Frontmatter has all required fields (`name`, `description`, `argument-hint`, `user-invocable`, `allowed-tools`)
- [ ] 2+ phase headings found
- [ ] At least one verdict keyword present (`PASS`, `FAIL`, `CONCERNS`, `APPROVED`, `BLOCKED`, `COMPLETE`, `READY`)
- [ ] If `allowed-tools` includes Write/Edit: `"May I write"` language present
- [ ] Next-step handoff section present at end

---

## Director Gate Checks

- **N/A**: No director or gate-check agent is invoked. The single write gate in Phase 4 is an inline `"May I write"` approval; no external verdict agent is required.

---

## Test Cases

### Case 1: Happy Path — Numbered Devlog With Active Sprint
**Fixture**:
- Invoked as `/publish-devlog 3`
- `production/session-state/active.md` exists with recent build activity
- `production/milestones/sprint-2.md` exists with sprint goal
- `production/publishing/devlog-2-2026-05-10.md` exists (previous devlog for tone)
- User selects "itch.io devlog" and "Honest and technical"

**Expected behavior**:
1. Parses argument — uses number 3, title becomes "Devlog #3"
2. Reads all context files including previous devlog
3. Asks platform and tone via `AskUserQuestion`
4. Asks "May I write the devlog to `production/publishing/devlog-3-[YYYY-MM-DD].md`?"
5. Writes file with four required sections
6. Auto-applies `/refine-copy`
7. Reports COMPLETE with visual flag count and estimated read time

**Assertions**:
- [ ] File saved at `production/publishing/devlog-3-[YYYY-MM-DD].md`
- [ ] All four sections present: What I Built, A Problem I Solved, A Decision I Made, What's Next
- [ ] At least one `[NEEDS: screenshot / GIF / video]` flag present
- [ ] Read time estimate reported
- [ ] Verdict is `COMPLETE`

**Case Verdict**: PASS

---

### Case 2: Failure — No Activity Context Available
**Fixture**:
- `production/session-state/active.md` does not exist
- No milestone files exist
- No GDDs exist
- No previous devlogs exist
- Invoked with no argument

**Expected behavior**:
1. Globs devlogs — none found, defaults to devlog #1
2. Reads context files — all absent
3. Skill continues (context files are not marked required with hard-stop messages)
4. Platform and tone questions still trigger
5. Output is sparse or placeholder-heavy but file is written after approval
6. Verdict is COMPLETE (skill has no hard fail for missing context beyond game-concept)

**Assertions**:
- [ ] Skill does not crash on all-missing context
- [ ] Approval gate still fires before write
- [ ] File is written with four sections (even if sparse)

**Case Verdict**: PASS

---

### Case 3: Mode Variant — Auto-Increment Number
**Fixture**:
- No argument provided
- `production/publishing/devlog-1-2026-04-01.md` and `devlog-2-2026-05-01.md` exist
- User selects "All of the above" platform and "Match my previous devlog" tone

**Expected behavior**:
1. Globs `production/publishing/devlog-*.md`
2. Finds highest number (2), increments to 3
3. Uses "Devlog #3" in title
4. Reads previous devlog for tone reference
5. Completes normally

**Assertions**:
- [ ] Output filename uses incremented number (3)
- [ ] Title in file reads "Devlog #3"
- [ ] Previous devlog was read (tone continuity)

**Case Verdict**: PASS

---

### Case 4: Edge Case — Writing-Lessons Rules Applied
**Fixture**:
- `production/publishing/writing-lessons.md` exists with an anti-pattern rule (e.g., "never use the word 'journey'")
- All other context files exist
- Devlog is generated normally

**Expected behavior**:
1. Loads `writing-lessons.md` in Phase 0 before any writing
2. The output avoids prohibited patterns from that file
3. Settled decisions in the knowledge base are not re-debated

**Assertions**:
- [ ] `writing-lessons.md` is read before any content is written
- [ ] Settled decisions in writing-lessons are treated as fixed

**Case Verdict**: PASS

---

### Case 5: Protocol — Write Approval Gate
**Fixture**:
- All context files exist
- User has answered platform and tone questions
- Skill is at Phase 4 write step

**Expected behavior**:
1. Shows "May I write the devlog to `production/publishing/devlog-[N]-[YYYY-MM-DD].md`?" before writing
2. User must confirm before file is created
3. `/refine-copy` runs automatically after write — no second approval needed

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

- Length enforcement (300–600 words) is a runtime judgment — static analysis cannot verify word count.
- "First person" voice and "specific over vague" rules are evaluated at runtime via `/refine-copy`.
- Tone matching to previous devlog ("Match my previous devlog" option) depends on runtime LLM judgment; static spec cannot assert stylistic fidelity.
