# Skill Spec: /backlog
> **Category**: sprint
> **Priority**: medium
> **Spec written**: 2026-06-11

## Skill Summary

`/backlog` manages `production/backlog.yaml`, the canonical cross-sprint story registry that serves as the single source of truth for all stories across all epics and sprints. It operates in four distinct modes: `init` (builds backlog.yaml from scratch by globbing all story files), `update` (resyncs existing backlog entries from current story file Status fields), `view` (generates a human-readable `production/backlog.md`), and `story [id] [status]` (updates a single story's status directly). Each mode includes an explicit write-approval gate before modifying any file. The skill is assigned model `haiku` and allows Read, Glob, and Write tools.

---

## Static Assertions

- [x] Frontmatter has all required fields — `name`, `description`, `argument-hint`, `user-invocable`, `allowed-tools`, `model` all present
- [x] 2+ phase headings found — multiple Phase sections present across all four modes
- [x] At least one verdict keyword present — "Verdict: COMPLETE — backlog synchronized." present in Recommended Next Steps
- [x] If allowed-tools includes Write/Edit: "May I write" language present — init Phase 4: "May I write `production/backlog.yaml`?", view Phase 3: "May I write `production/backlog.md`?", story mode: "Ask write approval"
- [x] Next-step handoff section present — "Recommended Next Steps" section present with post-init and post-update guidance

---

## Director Gate Checks

N/A — skill contains no director review invocation language. No PR-SPRINT, PR-MILESTONE, or director gate language appears anywhere in the skill text.

---

## Test Cases

**Case 1: Happy Path — init on empty project**

Fixture: `production/epics/` contains 3 story files across 2 epics. `production/sprint-status.yaml` exists with `sprint: 3`. No `production/backlog.yaml` exists.

Expected behavior:
- Phase 1 guard passes (no existing backlog.yaml)
- Phase 2 globs story files, reads active sprint, extracts all fields from each story
- Phase 3 finds no orphan sprint-status entries
- Phase 4 asks "May I write `production/backlog.yaml`? [Y/N]"
- On Y: writes file matching the schema (schema_version, generated, stories list)
- Displays summary block with counts by status category
- Ends with note: "Milestone targets: all empty — run /roadmap init to assign."

Assertions:
- Guard does not prompt overwrite when file is absent
- Status mapping applied correctly (e.g. Not Started + sprint == active sprint → `in-sprint`)
- Summary counts match actual extracted story count
- No write occurs before approval

Verdict: PASS

---

**Case 2: Failure/Blocked — init with existing backlog.yaml, user declines overwrite**

Fixture: `production/backlog.yaml` already exists.

Expected behavior:
- Phase 1 detects existing file
- Outputs: "backlog.yaml already exists. Run `/backlog update` to resync, or confirm to overwrite." then "Overwrite? [Y/N]"
- User responds N
- Skill stops — no Phase 2 through 4 execute

Assertions:
- Stops cleanly on N with no file modification
- No write prompt for backlog.yaml is issued after decline
- No stories are extracted

Verdict: PASS if stop is immediate and clean; FAIL if skill proceeds to Phase 2

---

**Case 3: Mode Variant — update with no changes**

Fixture: `production/backlog.yaml` exists with 5 stories. All story files on disk have Status fields matching the backlog's current statuses.

Expected behavior:
- Phase 1 reads backlog.yaml successfully
- Phase 2 re-reads each story file, re-extracts status_raw, applies mapping
- No diffs detected across all entries
- Outputs: "Backlog is current — no updates needed."
- No write approval prompt issued

Assertions:
- Output message matches exactly the documented string
- No write prompt appears
- No changes written to disk

Verdict: PASS if no write is triggered; FAIL if write prompt appears with empty diff

---

**Case 4: Edge Case — story file missing from disk (archived transition) during update**

Fixture: `production/backlog.yaml` has an entry with `file: production/epics/combat/story-003-hitbox.md` and `status: in-sprint`. That file has been deleted from disk.

Expected behavior:
- Phase 2 of update mode detects the path in backlog but file no longer exists
- Changes status for that entry to `archived`
- Records this as a detected change
- Phase 3 displays diff table showing `in-sprint → archived` for that entry
- Asks write approval before writing

Assertions:
- `archived` status applied (not left as `in-sprint`, not errored)
- Diff table shown before approval gate
- Write requires explicit approval

Verdict: PASS if archived transition is shown in diff and gated; FAIL if status silently retained or error thrown

---

**Case 5: Mode Variant — view with filter arguments**

Fixture: `production/backlog.yaml` exists with stories across 3 epics, mixed statuses, mixed milestone_target values. User runs `/backlog view --epic combat`.

Expected behavior:
- Phase 1 reads backlog.yaml and sprint-status.yaml
- Phase 2 applies `--epic combat` filter, limiting output to stories with `epic: combat`
- Phase 3 generates markdown grouped by epic, sorted in-sprint → ready → backlog → carried-over → done
- Asks: "May I write `production/backlog.md`? [Y/N]"
- On approval, writes file with only combat epic stories
- Summary table at top reflects filtered counts only

Assertions:
- Non-combat epic stories absent from output
- Sort order within the epic matches documented order
- Summary table present with Status / Count / Est. Days columns
- "May I write" gate appears before any disk write

Verdict: PASS if filter respected, sort correct, gate present; FAIL if unfiltered output written or gate skipped

---

## Protocol Compliance

- [x] "May I write" before file writes — explicitly present in init Phase 4, view Phase 3, and story mode
- [x] Presents findings before approval — init shows summary after write (post-approval display); update shows diff table before write approval; story mode shows "current → new status diff" before asking approval
- [x] Ends with next step — "Recommended Next Steps" section provides explicit follow-on commands per mode
- [ ] No auto-create without approval — **GAP**: update Phase 2 documents that "New story files (on disk but not in backlog): add them" but the write approval in Phase 3 covers this as part of the diff write; the gate is present but not called out as covering new additions explicitly

---

## Coverage Notes

**SP1** — PARTIAL. `init` mode reads `production/sprint-status.yaml` for active sprint number (Phase 2). `update` mode reads `production/backlog.yaml` (Phase 1) and re-reads story files but does not re-read sprint-status.yaml. `view` mode reads both `production/backlog.yaml` and `production/sprint-status.yaml` (Phase 1). No mode reads `production/milestones/` — milestone_target is always initialized to `""` and deferred to `/roadmap init`. SP1 is partially met: sprint data is read; milestone data is not.

**SP2** — NOT MET. No director gate, PR-SPRINT, or PR-MILESTONE block appears anywhere in the skill. The skill is assigned model `haiku`, which is consistent with the coordination-rules note that haiku skills do not require director gate runs. No lean/solo/full mode distinction exists in this skill.

**SP3** — MET. `init` output is a structured summary block with labeled counts per status. `view` output uses explicit markdown tables (Summary table + per-epic story table with defined columns). `update` uses a diff table. `story` mode shows a current → new diff. All output formats are structured, not free prose.

**SP4** — MET. `init` Phase 4 asks "May I write `production/backlog.yaml`? [Y/N]" explicitly. `view` Phase 3 asks "May I write `production/backlog.md`? [Y/N]" explicitly. `story` mode states "Ask write approval. Write." `update` Phase 3 states "ask write approval, write backlog.yaml." No mode auto-writes without documented approval gate.

**Additional gap**: The `story [id] [status]` mode lacks named phase headings — it is written as a flat prose block rather than Phase 1 / Phase 2 structure. This makes phase-level testing ambiguous for that mode. The "May I write" gate is stated but not structurally isolated as a phase.

**Staleness Warning section** is informational, not procedural — it documents a known architectural gap (Phase 2 write-path integration with `/story-done` and `/sprint-close` not yet implemented). Test cases should not assume those integrations exist.