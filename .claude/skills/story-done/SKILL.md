---
name: story-done
description: "End-of-story completion review. Reads the story file, verifies each acceptance criterion against the implementation, checks for GDD/ADR deviations, prompts code review, updates story status to Complete, and surfaces the next ready story from the sprint."
argument-hint: "[story-ID or path] [--review full|lean|solo]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Bash, Write, Edit, AskUserQuestion, Task
model: sonnet
---

# Story Done

This skill closes the loop between design and implementation. Run it at the end
of implementing any story. It ensures every acceptance criterion is verified
before the story is marked done, GDD and ADR deviations are explicitly
documented rather than silently introduced, code review is prompted rather than
forgotten, and the story file reflects actual completion status.

**Output:** Updated story file (Status: Complete) + surfaced next story.

---

## Phase 0: Resolve Story Reference

If `$ARGUMENTS[0]` is blank or is `--review`, skip to Phase 1 — the no-argument path applies.

Strip any `--review [full|lean|solo]` flag from the arguments first. The remaining first token is the story reference.

Determine whether it is a story ID or a file path:
- **File path**: contains `/` or `\`, or ends with `.md` → use as-is
- **Story ID**: anything else (e.g., `S8-01`, `S3-05`, `art-pipeline-011`)

If it is a **story ID**:
1. Read `production/backlog.yaml`
2. Find the entry where `id:` matches the token (case-insensitive)
3. If found: use its `file:` field as the resolved path. Proceed to Phase 1 with this path.
4. If not found: report "Story ID '[token]' not found in production/backlog.yaml." Glob `production/epics/**/*.md`, list the 5 most recently modified story files as suggestions. Stop.

---

## Phase 1: Find the Story

Resolve the review mode (once, store for all gate spawns this run):
1. If `--review [full|lean|solo]` was passed → use that
2. Else read `production/review-mode.txt` → use that value
3. Else → default to `lean`

See `.claude/docs/director-gates.md` for the full check pattern.

**If a file path is provided** (or resolved from Phase 0, e.g., `/story-done S8-01` or `/story-done production/epics/core/story-damage-calculator.md`):
read that file directly.

**If no argument is provided:**

1. Check `production/session-state/active.md` for the currently active story.
2. If not found there, read the most recent file in `production/sprints/` and
   look for stories marked IN PROGRESS.
3. If multiple in-progress stories are found, use `AskUserQuestion`:
   - "Which story are we completing?"
   - Options: list the in-progress story file names.
4. If no story can be found, ask the user to provide the path.

---

## Phase 2: Read the Story

Read the full story file. Extract and hold in context:

- **Story name and ID**
- **GDD Requirement TR-ID(s)** referenced (e.g., `TR-combat-001`)
- **Manifest Version** embedded in the story header (e.g., `2026-03-10`)
- **ADR reference(s)** referenced
- **Acceptance Criteria** — the complete list (every checkbox item)
- **Implementation files** — files listed under "files to create/modify"
- **Story Type** — the `Type:` field from the story header (Logic / Integration / Visual/Feel / UI / Config/Data)
- **Engine notes** — any engine-specific constraints noted
- **Definition of Done** — if present, the story-level DoD
- **Estimated vs actual scope** — if an estimate was noted

Also read:
- `docs/architecture/tr-registry.yaml` — look up each TR-ID in the story.
  Read the *current* `requirement` text from the registry entry. This is the
  source of truth for what the GDD required — do not use any requirement text
  that may be quoted inline in the story (it may be stale).
- The referenced GDD section — just the acceptance criteria and key rules, not
  the full document. Use this to cross-check the registry text is still accurate.
- The referenced ADR(s) — just the Decision and Consequences sections
- `docs/architecture/control-manifest.md` header — extract the current
  `Manifest Version:` date (used in Phase 4 staleness check)

---

## Phase 3: Verify Acceptance Criteria

For each acceptance criterion in the story, attempt verification using one of
three methods:

### Automatic verification (run without asking)

- **File existence check**: `Glob` for files the story said would be created.
- **Test pass check**: if a test file path is mentioned, run it via `Bash`.
- **No hardcoded values check**: `Grep` for numeric literals in gameplay code
  paths that should be in config files.
- **No hardcoded strings check**: `Grep` for player-facing strings in `src/`
  that should be in localization files.
- **Dependency check**: if a criterion says "depends on X", check that X exists.

### Manual verification with confirmation (use `AskUserQuestion`)

- Criteria about subjective qualities ("feels responsive", "animations play correctly")
- Criteria about gameplay behaviour ("player takes damage when...", "enemy responds to...")
- Performance criteria ("completes within Xms") — ask if profiled or accept as assumed

Batch up to 4 manual verification questions into a single `AskUserQuestion` call:

```
question: "Does [criterion]?"
options: "Yes — passes", "No — fails", "Not tested yet"
```

### Unverifiable (flag without blocking)

- Criteria that require a full game build to test (end-to-end gameplay scenarios)
- Mark as: `DEFERRED — requires playtest session`

### Test-Criterion Traceability

After completing the pass/fail/deferred check above, map each acceptance
criterion to the test that covers it:

For each acceptance criterion in the story:

1. Ask: is there a test — unit, integration, or confirmed manual playtest — that
   directly verifies this criterion?
   - **Unit test**: check `tests/unit/` for a test file or function name that
     matches the criterion's subject (use `Glob` and `Grep`)
   - **Integration test**: check `tests/integration/` similarly
   - **Manual confirmation**: if the criterion was verified via `AskUserQuestion`
     above with a "Yes — passes" answer, count that as a manual test

2. Produce a traceability table:

```
| Criterion | Test | Status |
|-----------|------|--------|
| AC-1: [criterion text] | tests/unit/[system]/test_foo.[ext]::test_bar | COVERED |
| AC-2: [criterion text] | Manual playtest confirmation | COVERED |
| AC-3: [criterion text] | — | UNTESTED |
```

3. Apply these escalation rules:

   - If **>50% of criteria are UNTESTED**: escalate to **BLOCKING** — test
     coverage is insufficient to confirm the story is actually done. The verdict
     in Phase 6 cannot be COMPLETE until coverage improves.
   - If **some (≤50%) criteria are UNTESTED**: remain ADVISORY — does not block
     completion, but must appear in Completion Notes.
   - If **all criteria are COVERED**: no action needed beyond including the
     table in the report.

4. For any ADVISORY untested criteria, add to the Completion Notes in Phase 7:
   `"Untested criteria: [AC-N list]. Recommend adding tests in a follow-up story."`

### Test Evidence Requirement

Based on the Story Type extracted in Phase 2, check for required evidence:

| Story Type | Required Evidence | Gate Level |
|---|---|---|
| **Logic** | Automated unit test in `tests/unit/[system]/` — must exist and pass | BLOCKING |
| **Integration** | Integration test in `tests/integration/[system]/` OR playtest doc | BLOCKING |
| **Visual/Feel** | Screenshot + sign-off in `production/qa/evidence/` | ADVISORY |
| **UI** | Manual walkthrough doc OR interaction test in `production/qa/evidence/` | ADVISORY |
| **Config/Data** | Smoke check pass report in `production/qa/smoke-*.md` | ADVISORY |

**For Logic stories**: first read the story's **Test Evidence** section to extract the
exact required file path. Use `Glob` to check that exact path. If the exact path is not
found, also search `tests/unit/[system]/` broadly (the file may have been placed at a
slightly different location). If no test file is found at either location:
- Flag as **BLOCKING**: "Logic story has no unit test file. Story requires it at
  `[exact-path-from-Test-Evidence-section]`. Create and run the test before marking
  this story Complete."

**For Integration stories**: read the story's **Test Evidence** section for the exact
required path. Use `Glob` to check that exact path first, then search
`tests/integration/[system]/` broadly, then check `production/session-logs/` for a
playtest record referencing this story.
If none found: flag as **BLOCKING** (same rule as Logic).

**For Visual/Feel and UI stories**: glob `production/qa/evidence/` for a file
referencing this story.
- If none: flag as **ADVISORY** — "No manual test evidence found. Create `production/qa/evidence/[story-slug]-evidence.md` using the test-evidence template and obtain sign-off before final closure."
- If found: read the file and check the sign-off table for unchecked boxes. Grep for lines matching `| .* | .* | .* | \[ \] Approved` (a sign-off row with an unchecked checkbox). If any unchecked sign-off rows are found: flag as **ADVISORY** — "Evidence file found at `[path]` but [N] sign-off(s) are still pending (shown as `[ ] Approved` in the sign-off table). Obtain required sign-offs before final closure. Note: for solo developers, all roles may be signed off by the same person."
- If all sign-off rows show `[x] Approved` or equivalent: note "Evidence file found and all sign-offs complete — ADVISORY passed."

**For Config/Data stories**: check for any `production/qa/smoke-*.md` file.
If none: flag as **ADVISORY** — "No smoke check report found. Run `/smoke-check`."

**If no Story Type is set**: flag as **ADVISORY** —
"Story Type not declared. Add `Type: [Logic|Integration|Visual/Feel|UI|Config/Data]`
to the story header to enable test evidence gate enforcement in future stories."

Any BLOCKING test evidence gap prevents the COMPLETE verdict in Phase 6.

---

## Phase 4: Check for Deviations

Compare the implementation against the design documents.

Run these checks automatically:

1. **GDD rules check**: Using the current requirement text from `tr-registry.yaml`
   (looked up by the story's TR-ID), check that the implementation reflects what
   the GDD actually requires now — not what it required when the story was written.
   `Grep` the implemented files for key function names, data structures, or class
   names mentioned in the current GDD section.

2. **Manifest version staleness check**: Compare the `Manifest Version:` date
   embedded in the story header against the `Manifest Version:` date in the
   current `docs/architecture/control-manifest.md` header.
   - If they match → pass silently.
   - If the story's version is older → flag as ADVISORY:
     `ADVISORY: Story was written against manifest v[story-date]; current manifest
     is v[current-date]. New rules may apply. Run /story-readiness to check.`
   - If control-manifest.md does not exist → skip this check.

3. **ADR constraints check**: Read the referenced ADR's Decision section. Check
   for forbidden patterns from `docs/architecture/control-manifest.md` (if it
   exists). `Grep` for patterns explicitly forbidden in the ADR.

4. **Hardcoded values check**: `Grep` the implemented files for numeric literals
   in gameplay logic that should be in data files.

5. **Scope check**: Did the implementation touch files outside the story's stated
   scope? (files not listed in "files to create/modify")

For each deviation found, categorize:

- **BLOCKING** — implementation contradicts the GDD or ADR (must fix before
  marking complete)
- **ADVISORY** — implementation drifts slightly from spec but is functionally
  equivalent (document, user decides)
- **OUT OF SCOPE** — additional files were touched beyond the story's stated
  boundary (flag for awareness — may be valid or scope creep)

---

## Phase 4b: QA Coverage Gate

**Review mode check** — apply before spawning QL-TEST-COVERAGE:
- `solo` → skip. Note: "QL-TEST-COVERAGE skipped — Solo mode." Proceed to Phase 5.
- `lean` → skip (not a PHASE-GATE). Note: "QL-TEST-COVERAGE skipped — Lean mode." Proceed to Phase 5.
- `full` → spawn as normal.

After completing the deviation checks in Phase 4, spawn `qa-lead` via Task using gate **QL-TEST-COVERAGE** (`.claude/docs/director-gates.md`).

Pass:
- The story file path and story type
- Test file paths found during Phase 3 (exact paths, or "none found")
- The story's `## QA Test Cases` section (the pre-written test specs from story creation)
- The story's `## Acceptance Criteria` list

The qa-lead reviews whether the tests actually cover what was specified — not just whether files exist.

Apply the verdict:
- **ADEQUATE** → proceed to Phase 5
- **GAPS** → flag as **ADVISORY**: "QA lead identified coverage gaps: [list]. Story can complete but gaps should be addressed in a follow-up story."
- **INADEQUATE** → flag as **BLOCKING**: "QA lead: critical logic is untested. Verdict cannot be COMPLETE until coverage improves. Specific gaps: [list]."

Skip this phase for Config/Data stories (no code tests required).

---

## Phase 4c: Deferred Story Stub Check

**Run for every story, before Phase 5.**

Grep the story file body for any of these patterns (case-insensitive):
- `deferred`
- `later story`
- `future story`
- `later sprint`

If **no matches found**: proceed silently.

If **matches found**: for each match, extract the deferred item description. Then:

1. Glob `production/epics/[epic-slug]/story-*.md` — list all story files in the same epic directory.
2. Check whether any existing story file covers the deferred item (by name or filename keyword match).
3. If a stub exists → proceed silently. Note "Deferred item `[X]` has a stub at `[path]`."
4. If **no stub exists** → flag as **ADVISORY**:

   > ⚠️ **Deferred story stub missing**: This story defers `[item]` but no stub exists in
   > `production/epics/[slug]/`. Create a stub story file before this story is marked done,
   > or it will fall through the backlog permanently.

   Use `AskUserQuestion`:
   - Prompt: "Deferred item found with no backlog stub: `[item]`. How do you want to handle this?"
   - Options:
     - `[A] Create a stub story file now — I'll fill in details later (Recommended)`
     - `[B] Skip — I'll create the stub manually`

   If [A]: create a minimal stub at `production/epics/[slug]/story-NNN-[kebab-name].md`:
   ```markdown
   # Story: [Deferred Item Name]

   > **Epic**: [Epic Name]
   > **Status**: Not Started
   > **Story ID**: TBD
   > **Source**: Deferred from [this story file path]

   ## Context

   Deferred from [story name]: "[exact deferred text from story]"

   ## Acceptance Criteria

   - [ ] AC-1: [TBD — fill in before sprint planning]
   ```
   Confirm: "Stub created at `[path]`."

   If [B]: continue without creating the stub. Add to Completion Notes in Phase 7:
   "Deferred item `[X]` has no backlog stub — add manually before next sprint planning."

---

## Phase 4d: Presentation Readiness (Advisory)

**Run for every story. Skip only if the story has no visual or interactive output (pure data migration, config change, etc.).**

Use `AskUserQuestion`:

```
question: "Presentation readiness (advisory): Is this feature screenworthy as-is?"
options:
  - "Yes — ready to screenshot or GIF"
  - "Has issues — I'll describe them"
  - "N/A — not a visual or interactive feature"
```

If **"Yes"** or **"N/A"**: proceed silently to Phase 5.

If **"Has issues"**: prompt the user:

> "Describe each presentation issue in one line. I'll log them to the epic's polish register."

After receiving the user's description:

1. Determine the epic slug from the story file path (e.g., `production/epics/workshop-ui/story-006.md` → slug `workshop-ui`, epic name `Workshop UI`).
2. Locate or create `production/epics/[slug]/POLISH.md`:
   - **If the file does not exist**: create it with this header:
     ```markdown
     # Polish Register — [epic-name]
     *Small visual/presentation issues. Not backlog stories. Swept before showable events.*

     | ID | Issue | Status | Sprint | Story |
     |----|-------|--------|--------|-------|
     ```
   - **If the file exists**: read it to determine the next ID (count existing `| P` rows and increment).
3. For each issue described, append one row:
   ```
   | P[NNN] | [issue description] | open | [current sprint, e.g. S8] | [story ID, e.g. S8-06] |
   ```
   Use three-digit zero-padded IDs (`P001`, `P002`, …).
4. Confirm: "Logged [N] item(s) to `[path]`."

Proceed to Phase 5.

---

## Phase 5: Lead Programmer Code Review Gate

**Review mode check** — apply before spawning LP-CODE-REVIEW:
- `solo` → skip. Note: "LP-CODE-REVIEW skipped — Solo mode." Proceed to Phase 6 (completion report).
- `lean` → auto-detect, then act:
  1. Read `production/session-state/active.md`. Search for a `Session Extract — /code-review` block that references any of this story's implementation files or the story file path.
  2. **Found** → code review already run. Note: "Code review detected in session state — skipping re-run." Proceed to Phase 6.
  3. **Not found** → use `AskUserQuestion`:
     - Prompt: "No /code-review found for this story. Run it now?"
     - Options:
       - `Yes — run /code-review now` → spawn LP-CODE-REVIEW via Task (see below)
       - `No — skipping code review for this story` → proceed to Phase 6, note Skipped
       - `No — I'll run /code-review before the sprint close-out` → proceed to Phase 6, note Pending
- `full` → auto-detect, then act:
  1. Same session state check as lean.
  2. **Found** → skip re-run, proceed to Phase 6.
  3. **Not found** → spawn LP-CODE-REVIEW via Task immediately. No AskUserQuestion.

Spawn `lead-programmer` via Task using gate **LP-CODE-REVIEW** (`.claude/docs/director-gates.md`).

Pass: implementation file paths, story file path, relevant GDD section, governing ADR.

Present the verdict to the user. If CONCERNS, surface them via `AskUserQuestion`:
- Options: `Revise flagged issues` / `Accept and proceed` / `Discuss further`
If REJECT, do not proceed to Phase 6 verdict until the issues are resolved.

If the story has no implementation files yet (verdict is being run before coding is done), skip this phase and note: "LP-CODE-REVIEW skipped — no implementation files found. Run after implementation is complete."

---

## Phase 6: Present the Completion Report

Before updating any files, present the full report:

```markdown
## Story Done: [Story Name]
**Story**: [file path]
**Date**: [today]

### Acceptance Criteria: [X/Y passing]
- [x] [Criterion 1] — auto-verified (test passes)
- [x] [Criterion 2] — confirmed
- [ ] [Criterion 3] — FAILS: [reason]
- [?] [Criterion 4] — DEFERRED: requires playtest

### Test-Criterion Traceability
| Criterion | Test | Status |
|-----------|------|--------|
| AC-1: [text] | [tests/unit/system/test_file.[ext]::test_name] | COVERED |
| AC-2: [text] | Manual confirmation | COVERED |
| AC-3: [text] | — | UNTESTED |

### Test Evidence
**Story Type**: [Logic | Integration | Visual/Feel | UI | Config/Data | Not declared]
**Required evidence**: [unit test file | integration test or playtest | screenshot + sign-off | walkthrough doc | smoke check pass]
**Evidence found**: [YES — `[path]` | NO — BLOCKING | NO — ADVISORY]

### Deviations
[NONE] OR:
- BLOCKING: [description] — [GDD/ADR reference]
- ADVISORY: [description] — user accepted / flagged for tech debt

### Scope
[All changes within stated scope] OR:
- Extra files touched: [list] — [note whether valid or scope creep]

### Verdict: COMPLETE / COMPLETE WITH NOTES / BLOCKED
```

**Verdict definitions:**
- **COMPLETE**: all criteria pass, no blocking deviations
- **COMPLETE WITH NOTES**: all criteria pass, advisory deviations documented
- **BLOCKED**: failing criteria or blocking deviations must be resolved first

If the verdict is **BLOCKED**: do not proceed to Phase 7. List what must be
fixed. Offer to help fix the blocking items.

---

## Phase 7: Update Story Status

Use `AskUserQuestion` before writing anything:
- Prompt: "Verification complete. How do you want to proceed?"
- Options:
  - `Close the story — update file, mark Complete, log notes (Recommended)`
  - `Close and log advisory deviations as tech debt in docs/tech-debt-register.md`
  - `There are issues I want to fix first — don't close yet`
  - `Accept deviations as-is and close anyway`

If "Close", "Close and log tech debt", or "Accept deviations": edit the story file.
If "Close and log tech debt": after updating the story file, also append the advisory deviations to `docs/tech-debt-register.md` (create the file if it does not exist).
If "Fix first": stop here and list what the user flagged. Do not write any files.

1. Update the status field: `Status: Complete`
2. Update the `Last Updated:` field in the story header to today's date (format: `YYYY-MM-DD`). If the field does not exist, add it after the `Status:` line.
3. Add a `## Completion Notes` section at the bottom:

```markdown
## Completion Notes
**Completed**: [date]
**Criteria**: [X/Y passing] ([any deferred items listed])
**Deviations**: [None] or [list of advisory deviations]
**Test Evidence**: [Logic: test file at path | Visual/Feel: evidence doc at path | None required (Config/Data)]
**Code Review**: [Pending / Complete / Skipped]
```

4. If the user chose "Close and log tech debt": append each advisory deviation to `production/tech-debt/register.md` in this format:
   ```
   ## TD-NNN: [Short description]

   **Status**: Open
   **Severity**: Low / Medium / High
   **Sprint Logged**: Sprint [N]
   **Source Story**: [story file path]

   [One-paragraph description of the deviation and why it was deferred]

   ### Target Fix
   [Sprint or milestone when this should be addressed]
   ```
   Determine the next TD-NNN by reading the existing file and incrementing the highest existing ID. Create the file with a `# Tech Debt Register` heading if it does not exist.

5. **Update `production/sprint-status.yaml`** (if it exists):
   - Find the entry matching this story's file path or ID
   - Set `status: done` and `completed: [today's date]`
   - Update the top-level `updated` field
   - This is a silent update — no extra approval needed (already approved in step above)

6. **Update `production/backlog.yaml`** (if it exists):
   - Find the entry matching this story's ID or `file` path
   - Set `status: done` and `completed_date: [today's date]`
   - This is a silent update — no extra approval needed

7. **Suggest a git commit**: Output a ready-to-use commit command covering the implementation files from the dev-story summary and the updated story file:

```
Suggested commit:
git add [src/ and tests/ files changed during implementation] [story-file-path]
git commit -m "feat: [story title] ([TR-ID])"
```

The `validate-commit.sh` hook will verify design doc references and check for hardcoded values automatically.

### Session State Update

After updating the story file, silently append to
`production/session-state/active.md`:

    ## Session Extract — /story-done [date]
    - Verdict: [COMPLETE / COMPLETE WITH NOTES / BLOCKED]
    - Story: [story file path] — [story title]
    - Tech debt logged: [N items, or "None"]
    - Next recommended: [next ready story title and path, or "None identified"]

If `active.md` does not exist, create it with this block as the initial content.
Confirm in conversation: "Session state updated."

---

## Phase 8: Surface the Next Story

After completion, help the developer keep momentum:

1. Read the current sprint plan from `production/sprints/`.
2. Find stories that are:
   - Status: READY or NOT STARTED
   - Not blocked by other incomplete stories
   - In the Must Have or Should Have tier

Present:

```
### Next Up
The following stories are ready to pick up:
1. [Story name] — [1-line description] — Est: [X hrs]
2. [Story name] — [1-line description] — Est: [X hrs]

Run `/story-readiness [path]` to confirm a story is implementation-ready
before starting.
```

If no more Must Have stories remain in this sprint (all are Complete or Blocked):

```
### Sprint Close-Out Sequence

All Must Have stories are complete. QA sign-off is required before advancing.
Run the full sequence with one command:

`/sprint-close` — orchestrates all five steps in order with gate-and-record confirmation at each.

Or run manually in this order:
1. `/milestone-review` — capture product health before closing
2. `/smoke-check sprint` — verify the critical path still works end-to-end
3. `/team-qa sprint` — full QA cycle: test case execution, bug triage, sign-off report
4. `/retrospective` — capture what went well, what didn't, and action items for the next sprint
5. `/gate-check` — advance to the next phase once QA approves (only if advancing a phase)

Then in a fresh session: `/sprint-plan new` — plan the next sprint with velocity data and retro action items pre-loaded.

Do not run `/gate-check` until `/team-qa` returns APPROVED or APPROVED WITH CONDITIONS.
```

If there are Should Have stories still unstarted, surface them alongside the close-out sequence so the user can choose: close the sprint now, or pull in more work first.

If no more stories are ready but Must Have stories are still In Progress (not Complete):
"No more stories ready to start — [N] Must Have stories still in progress. Continue implementing those before sprint close-out."

---

## Collaborative Protocol

- **Never mark a story complete without user approval** — Phase 7 requires an
  explicit "yes" before any file is edited.
- **Never auto-fix failing criteria** — report them and ask what to do.
- **Deviations are facts, not judgments** — present them neutrally; the user
  decides if they are acceptable.
- **BLOCKED verdict is advisory** — the user can override and mark complete
  anyway; document the risk explicitly if they do.
- Use `AskUserQuestion` for the code review prompt and for batching manual
  criteria confirmations.

---

## Recommended Next Steps

- Run `/story-readiness [next-story-path]` to validate the next story before starting implementation
- If all Must Have stories are complete: run `/smoke-check sprint` → `/team-qa sprint` → `/gate-check`
- If tech debt was logged: track it via `/tech-debt` to keep the register current
