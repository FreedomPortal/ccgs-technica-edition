# Skill Spec: /wishlist
> **Category**: pipeline
> **Priority**: medium
> **Spec written**: 2026-06-11

## Skill Summary

`/wishlist` is a capture-and-triage tool for uncommitted ideas that are not yet ready for the backlog. It operates in five explicit modes — `add`, `view`, `promote`, `defer`, `prune` — each with distinct interactive flows. The data file is `production/wishlist.yaml`, which the skill creates on first use. Every write to that file requires explicit user approval via the "May I write/update/apply" gate pattern. The skill deliberately excludes scope analysis and estimation; it is a holding area and audit trail, not a planning tool.

---

## Static Assertions

- [x] Frontmatter has all required fields — `name`, `description`, `argument-hint`, `user-invocable`, `allowed-tools`, `model` all present
- [x] 2+ phase headings — six mode sections (Modes, add, view, promote, defer, prune) plus Collaborative Protocol and Recommended Next Steps
- [x] Verdict keyword present — "Verdict: COMPLETE — wishlist updated." in Recommended Next Steps
- [x] If Write/Edit in allowed-tools: "May I write" language present — `add` mode: "May I add this to `production/wishlist.yaml`?"; `promote` mode: "May I update `production/wishlist.yaml`?"; `defer` mode: "May I update WL-NNN to deferred in `production/wishlist.yaml`?"; `prune` mode: "May I apply these changes to `production/wishlist.yaml`?"
- [x] Next-step handoff present — Recommended Next Steps section lists `/roadmap update`, `/wishlist promote [id]` + `/create-epics`, `/wishlist view`

---

## Director Gate Checks

N/A — the skill contains no director review invocations, no gate-check calls, and no references to phase-gate verdicts or director agents.

---

## Test Cases

### Case 1: Happy Path — add new item to existing wishlist

**Fixture:**
- `production/wishlist.yaml` exists with two items (WL-001, WL-002, both `status: raw`)

**Expected behavior:**
1. Skill prompts for title (rejects blank), description, category, rough size, notes (optional)
2. Reads wishlist.yaml, finds highest ID = WL-002, assigns WL-003
3. Displays full YAML entry as draft
4. Asks "May I add this to `production/wishlist.yaml`?"
5. On approval: appends item with `status: raw`, `added: [today]`, `promoted_to: ""`
6. Confirms "Added WL-003: [title]."
7. Ends with verdict and next-step suggestions

**Assertions:**
- [ ] Each field collected via separate `AskUserQuestion` calls (not a single bulk prompt)
- [ ] ID assigned by incrementing highest existing ID, not by counting items
- [ ] Draft shown before approval gate (P3)
- [ ] Exact "May I add this to `production/wishlist.yaml`?" phrasing used
- [ ] `status: raw` set automatically (not prompted)
- [ ] `added` set to today's date automatically
- [ ] `promoted_to: ""` set automatically
- [ ] Confirmation message includes assigned ID and title
- [ ] Verdict: COMPLETE present in closing output

**Verdict:** PASS if all assertions hold

---

### Case 2: Failure / Blocked — add mode, blank title submitted

**Fixture:**
- `production/wishlist.yaml` exists or missing (either state)
- User submits empty string for title field

**Expected behavior:**
1. Skill reaches Step 1, prompts for title
2. User submits blank/empty value
3. Skill rejects and re-prompts — does not proceed to description field
4. Process only continues once a non-blank title is provided

**Assertions:**
- [ ] Blank title explicitly rejected per "required — reject blank" instruction
- [ ] Skill re-prompts for title rather than proceeding with empty value
- [ ] No ID auto-assigned until valid title exists
- [ ] No write attempted on blank title submission

**Verdict:** PASS if blank title is rejected and re-prompted; FAIL if skill proceeds with empty title

---

### Case 3: Mode Variant — view mode with mixed-status wishlist

**Fixture:**
- `production/wishlist.yaml` exists with items across all four statuses: raw, refined, deferred, promoted
- One promoted item has `promoted_to` path set; one has `promoted_to: ""`

**Expected behavior:**
1. Skill reads wishlist.yaml
2. Outputs markdown table grouped by status in order: raw → refined → deferred → promoted
3. Within each group, items sorted by `added` date oldest first
4. Promoted group uses the `| ID | Title | Promoted To |` column format (not the standard 5-column format)
5. All four groups rendered (none omitted since all have items)
6. Summary header shows correct item counts per status
7. No file write performed

**Assertions:**
- [ ] Output goes to chat only — no `Write` or `Edit` tool call made (P3)
- [ ] Status groups appear in raw → refined → deferred → promoted order
- [ ] Promoted group uses narrower 3-column table layout
- [ ] Groups with zero items omitted per "Omit groups that have zero items"
- [ ] If wishlist.yaml is missing: output is exactly "No wishlist yet. Run `/wishlist add` to capture your first idea." with no other output
- [ ] No approval gate triggered (view is read-only)

**Verdict:** PASS if output matches schema exactly with no file writes

---

### Case 4: Edge Case — promote mode, ID already promoted

**Fixture:**
- `production/wishlist.yaml` contains WL-004 with `status: promoted`, `promoted_to: "production/epics/dash-mechanic/EPIC.md"`

**Expected behavior:**
1. User runs `/wishlist promote WL-004`
2. Skill reads wishlist.yaml, finds WL-004
3. Detects `status: promoted`
4. Outputs: "WL-NNN is already promoted (promoted_to: [path])."
5. Stops — does not proceed to destination selection steps

**Assertions:**
- [ ] Already-promoted guard triggers before AskUserQuestion for destination
- [ ] Output includes the existing `promoted_to` path in the message
- [ ] No write performed
- [ ] No approval gate triggered

**Variant — ID not found:**
- [ ] If ID does not exist in file: output is "WL-NNN not found in wishlist.yaml." and skill stops

**Verdict:** PASS if both guard conditions halt execution with correct messages

---

### Case 5: Most Relevant Variant — prune mode full flow with mixed decisions

**Fixture:**
- `production/wishlist.yaml` contains 4 items: WL-001 (`raw`, oldest), WL-002 (`deferred`), WL-003 (`raw`), WL-004 (`promoted`) — promoted item is excluded from prune candidates
- User decisions: WL-001 Keep, WL-002 Refine (new description + size), WL-003 Delete

**Expected behavior:**
1. Skill loads wishlist.yaml, lists only `raw` and `deferred` items (WL-001, WL-002, WL-003) sorted oldest first
2. WL-004 (promoted) excluded from prune candidates
3. For each candidate: displays `[WL-NNN] Title — Category, Size / Added / Description / Notes` block
4. AskUserQuestion per item with K/R/D/X options
5. For WL-002 (Refine): additional prompts for updated description and/or rough size; sets `status: refined`
6. All decisions collected before any write
7. Displays prune plan summary: "Prune plan: [N] kept / [N] refined / [N] deferred / [N] deleted"
8. Asks "May I apply these changes to `production/wishlist.yaml`?"
9. On approval: WL-002 updated to refined with new values, WL-003 removed from items entirely, WL-001 unchanged
10. Confirms "Pruned: 1 deleted, 0 deferred, 1 refined, 1 kept."
11. WL-003's ID never reused

**Assertions:**
- [ ] Only `raw` and `deferred` items listed as candidates — `promoted` (and `refined`) excluded (P2)
- [ ] Items sorted by `added` date, oldest first
- [ ] All decisions collected before write (batch collection per instruction)
- [ ] Prune plan summary shown before approval gate
- [ ] Single "May I apply these changes" gate for the full batch — not per-item write gates (P3 note: batch is explicitly specified here)
- [ ] Deleted items removed from `items:` array entirely
- [ ] Refined items have `status: refined` set plus updated fields
- [ ] Confirmation message matches "Pruned: [N] deleted, [N] deferred, [N] refined, [N] kept." format
- [ ] If no raw/deferred items exist: output is "No raw or deferred items to prune." and skill stops

**Verdict:** PASS if batch collect → summary display → single approval gate → write sequence is followed exactly

---

## Protocol Compliance

- [x] "May I write" before file writes — present in all four write-capable modes (`add`, `promote`, `defer`, `prune`) with mode-specific phrasing
- [x] Presents findings before approval — `add` shows full YAML draft; `prune` shows prune plan summary; `promote` shows item title and description before destination question
- [x] Ends with next step — Recommended Next Steps section provides three concrete follow-on commands
- [x] No auto-create without approval — both file creation (first item) and all subsequent writes gate on explicit "May I" approval

---

## Coverage Notes

**P1 — Output files follow project template; skill references template path:**
Partially covered. The skill defines its own YAML schema inline (lines 37-52) and references the canonical path `production/wishlist.yaml`. There is no separate template file referenced. Tests should verify the emitted YAML matches the inline schema exactly (all fields present, correct defaults).

**P2 — Epics/stories respect layer ordering and priority fields:**
Not directly applicable — wishlist.yaml items have `category` and `rough_size`, not layer/priority. The prune Case 5 checks that status-based filtering correctly excludes non-candidate statuses, which is the closest analog.

**P3 — "May I write [artifact]?" before creating each output file, not batch-approving all:**
The prune mode is a deliberate exception: the skill explicitly instructs batch-collecting all decisions then issuing a single approval gate for the full set. This is by design, not a protocol violation. All other modes issue a per-action approval gate. Case 5 documents this distinction.

**P4 — In-scope gates run in full, skip in lean/solo with noted skip:**
Not applicable. The skill has no mode-switching based on project stage or director tier. No lean/solo variants are defined.

**P5 — Reads relevant GDD/ADR/manifest before producing artifacts:**
Not present. The skill is intentionally a capture tool with no design document reads. This is by design per the Collaborative Protocol: "This skill is a capture and triage tool, not a planning tool — no scope analysis, no estimates." P5 is N/A for this skill.