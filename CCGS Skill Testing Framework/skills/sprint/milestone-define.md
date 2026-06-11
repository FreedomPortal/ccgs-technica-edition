# Skill Spec: /milestone-define
> **Category**: sprint
> **Priority**: low
> **Spec written**: 2026-06-11

## Skill Summary

`/milestone-define` manages forward-looking scope contract files under `production/milestones/definitions/[name].md`. It operates in three modes: `init [name]` creates or updates a milestone definition file by gathering goal, scope, quality bar, exit criteria, and gate skill via two batched `AskUserQuestion` calls before requesting write approval; `list` reads the definitions directory and `active.txt` to display a structured milestone summary; and `activate [name]` sets the active milestone by writing `active.txt` and updating the target definition's `Status` field. The skill explicitly distinguishes definition files (forward-looking) from review files (backward-looking) and provides recommended next steps after each mode completes.

---

## Static Assertions

- [x] Frontmatter has all required fields — `name`, `description`, `argument-hint`, `user-invocable`, `allowed-tools`, `model` all present
- [x] 2+ phase headings — Mode: init has Phase 1 (Guard), Phase 2 (Gather), Phase 3 (Write); Mode: list and Mode: activate are additional structural headings
- [x] Verdict keyword present — "Verdict: COMPLETE — milestone definition written." in Recommended Next Steps
- [x] If Write/Edit in allowed-tools: "May I write" language present — Phase 3 states `Ask: "May I write production/milestones/definitions/[name].md? [Y/N]"`
- [x] Next-step handoff present — "Recommended Next Steps" section lists `/milestone-define activate [name]`, `/roadmap init`, `/gate-check`

---

## Director Gate Checks

N/A — the skill contains no director review gates, PR-SPRINT gates, or calls to any gate-check skill during its own phases. `/gate-check` appears only as a reference in the output template and in the Recommended Next Steps handoff.

---

## Test Cases

### Case 1: Happy Path — init creates new definition

**Fixture**
- `production/milestones/definitions/` exists but contains no `vertical-slice.md`
- `production/backlog.yaml` exists with at least one epic listed
- User invokes `/milestone-define init vertical-slice`

**Expected behavior**
1. Phase 1 (Guard): skill checks for existing `vertical-slice.md`, finds none, proceeds without prompting overwrite.
2. Phase 2 (Gather): skill reads `production/backlog.yaml` to populate epic checklist; issues first `AskUserQuestion` batching fields 1–4 (goal statement, in-scope epics, out-of-scope list, quality bar); issues second `AskUserQuestion` for fields 5–6 (exit criteria, gate skill).
3. Phase 3 (Write): skill asks "May I write `production/milestones/definitions/vertical-slice.md`? [Y/N]"; on Y, writes file matching the specified markdown template.
4. After write: skill suggests running `/milestone-define activate vertical-slice`.

**Assertions**
- Two `AskUserQuestion` calls issued (fields 1–4 then 5–6), not one and not three.
- Write approval prompt appears before any file is written.
- Written file contains all six template sections: Goal, In Scope, Out of Scope, Quality Bar, Exit Criteria, Gate.
- Post-write message references `/milestone-define activate vertical-slice`.

**Verdict**: PASS if all assertions hold.

---

### Case 2: Failure/Blocked — init with existing definition, user declines overwrite

**Fixture**
- `production/milestones/definitions/vertical-slice.md` already exists with content
- User invokes `/milestone-define init vertical-slice`

**Expected behavior**
1. Phase 1 (Guard): skill detects existing file, prompts "Definition for vertical-slice already exists. Overwrite? [Y/N]"
2. User responds N.
3. Skill stops — no gather phase, no write phase, no file modification.

**Assertions**
- Overwrite prompt is issued using exact or equivalent phrasing from the spec.
- No `AskUserQuestion` gather calls issued after N response.
- No Write/Edit tool calls made.
- No error thrown — clean stop.

**Verdict**: PASS if skill halts cleanly after N without touching the file.

---

### Case 3: Mode Variant — list with active milestone set

**Fixture**
- `production/milestones/definitions/` contains `vertical-slice.md` (status: active) and `demo.md` (status: planned)
- `production/milestones/active.txt` contains `vertical-slice`
- User invokes `/milestone-define list`

**Expected behavior**
1. Skill reads `production/milestones/definitions/` directory.
2. Skill reads `production/milestones/active.txt`.
3. Outputs structured table showing `Active: vertical-slice` plus one row per definition with name, status, and goal first sentence.
4. Footer line references `/milestone-define activate [name]` and `/roadmap view`.

**Assertions**
- Output header reads "Milestone Definitions" with the separator line.
- "Active:" line shows `vertical-slice` (not "none set").
- Both `vertical-slice` and `demo` appear in the listing with their respective statuses.
- Footer references both `/milestone-define activate [name]` and `/roadmap view`.
- No `AskUserQuestion` issued (list mode is read-only).
- No Write/Edit tool calls made.

**Verdict**: PASS if output matches the structured format specified in the skill and no writes occur.

---

### Case 4: Edge Case — list with empty or missing definitions directory

**Fixture**
- `production/milestones/definitions/` either does not exist or contains no `.md` files
- User invokes `/milestone-define list`

**Expected behavior**
1. Skill attempts to read `production/milestones/definitions/`.
2. Detects empty or missing directory.
3. Outputs exactly: "No milestone definitions found. Run `/milestone-define init [name]` to create the first one."
4. No further output, no error.

**Assertions**
- Output matches the exact fallback message specified in the skill.
- No crash or unhandled error from missing directory.
- No Write/Edit tool calls made.
- No `AskUserQuestion` issued.

**Verdict**: PASS if fallback message is emitted cleanly.

---

### Case 5: Edge Case — activate with no definition file present

**Fixture**
- `production/milestones/definitions/` exists but contains no `alpha.md`
- `production/milestones/active.txt` may or may not exist
- User invokes `/milestone-define activate alpha`

**Expected behavior**
1. Skill checks for `production/milestones/definitions/alpha.md`.
2. File not found: skill outputs "No definition found for alpha. Run `/milestone-define init alpha` first."
3. Skill stops — does not write `active.txt`, does not attempt to update any status fields.

**Assertions**
- Error message matches (or is equivalent to) the spec's specified wording, referencing the missing name and the corrective command.
- `production/milestones/active.txt` is not created or modified.
- No definition file is created or modified.
- No `AskUserQuestion` issued.

**Verdict**: PASS if skill surfaces the missing-definition error and halts without side effects.

---

## Protocol Compliance

- [x] "May I write" before file writes — Phase 3 (init) explicitly asks before writing the definition file; activate writes `active.txt` directly after verification (no approval gate specified for that write)
- [x] Presents findings before approval — Phase 2 gathers all fields and presents them through `AskUserQuestion` before Phase 3 write approval
- [x] Ends with next step — "Recommended Next Steps" section present with three concrete follow-on commands
- [x] No auto-create without approval — definition file creation gated by "May I write" in Phase 3; overwrite gated by Phase 1 guard

**Note on activate mode**: The spec instructs the skill to write `active.txt` and edit the status field of the target definition without an explicit "May I write" gate. This is a documented deviation from the general protocol — activate is a single-field mechanical action following an existence check, and the spec does not specify an approval prompt for it. Testers should verify this is intentional and not an oversight.

---

## Coverage Notes

| Rubric | Status | Evidence |
|--------|--------|----------|
| SP1 — reads production/milestones/ before output | COVERED | list mode reads `definitions/` and `active.txt`; init Phase 1 checks definitions dir; activate checks definitions dir |
| SP2 — PR-SPRINT or PR-MILESTONE gate in full mode | N/A | No director gate specified in skill; `/gate-check` referenced only as output field and handoff |
| SP3 — consistent structured output not free prose | COVERED | list mode specifies exact output format with separator and footer; init output follows fixed markdown template |
| SP4 — never writes sprint files without "May I write" | COVERED for init | Phase 3 gate explicit; activate `active.txt` write has no approval gate per spec (see Protocol Compliance note) |