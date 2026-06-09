---
name: backlog
description: Create and maintain production/backlog.yaml — the canonical cross-sprint story registry. sprint-status.yaml is a generated view; backlog.yaml is the source of truth.
model: haiku
---

# /backlog

Manages `production/backlog.yaml` — canonical record of all stories across all sprints and epics.

`sprint-status.yaml` = generated view of current sprint only. `backlog.yaml` = single source of truth.

---

## Modes

| Command | Description |
|---------|-------------|
| `/backlog init` | Build backlog.yaml from scratch by reading all story files |
| `/backlog update` | Resync backlog from current story file Status fields |
| `/backlog view` | Generate human-readable production/backlog.md |
| `/backlog story [id] [status]` | Update a single story's status directly |

---

## Mode: init

### Phase 1 — Guard

Check for existing `production/backlog.yaml`.

If found:
> "backlog.yaml already exists. Run `/backlog update` to resync, or confirm to overwrite."
> "Overwrite? [Y/N]"

- N: stop.
- Y: proceed.

### Phase 2 — Collect Stories

Glob: `production/epics/**/*.md`, then filter out files named exactly `EPIC.md`.

Read active sprint number from `production/sprint-status.yaml` field `sprint:`.

For each story file, extract the following fields. Story files use multiple formats (bold-pair `**Field**: value`, table row `| Field | Value |`, blockquote `> **Field**: value`) — try all patterns before marking a field unknown.

| Backlog field | Extract from | Notes |
|--------------|-------------|-------|
| `id` | Title line or `Story ID:` / `**Story ID**:` field | e.g. `S5-09`, `S3-01`. If absent: generate as `[epic-slug]-[file-number]`. |
| `epic` | File path segment between `epics/` and `/story-` | Use directory name as slug (already normalized). |
| `name` | Title after ID separator ` — ` or `: ` | Strip leading `Story ` prefix and trailing whitespace. |
| `file` | Relative path from project root | e.g. `production/epics/economy/story-004-loot-drop-impl.md` |
| `status_raw` | `Status:` field value | Map per Status Mapping table below. |
| `sprint` | `Sprint:` field; or digits in story-ID prefix (S5-09 → 5) | Integer. `null` if not determinable. |
| `priority` | `Priority:` field | Normalize: `must-have` / `should-have` / `nice-to-have`. `""` if absent. |
| `estimate_days` | `Estimate:` field | Strip `d`, `days`, `(~N hours)` suffixes. Float. `0.0` if absent. |
| `completed_date` | `**Completed**:` line in Completion Notes section | YYYY-MM-DD string. `""` if not found. |
| `tags` | `Type:` field | Split on `(primary)`, `(secondary)`, `,`. Lowercase slugs. |
| `milestone_target` | Not yet assigned | Always `""` at init — assigned by `/roadmap init`. |

**Status Mapping** (story `Status:` → backlog `status`):

| Story Status | Active sprint? | Backlog Status |
|-------------|---------------|---------------|
| Complete | — | `done` |
| Not Started | sprint == active sprint | `in-sprint` |
| Not Started | sprint < active sprint (closed) | `carried-over` |
| Not Started | no sprint field | `backlog` |
| In Progress | — | `in-sprint` |
| Blocked | — | `blocked` |
| Ready | — | `ready` |

### Phase 3 — Collect Sprint-Status Orphans

Read `production/sprint-status.yaml`. Find any story entries whose `file` path has no matching file on disk and is not already covered by Phase 2.

Add these as `orphan-sprint-entry` status with `file: "[missing]"`.

### Phase 4 — Write

Ask: "May I write `production/backlog.yaml`? [Y/N]"

On approval, write the file (see Schema section).

Display summary after write:

```
Backlog initialized: [date]

Stories: [total]
  done:          N
  in-sprint:     N
  carried-over:  N
  backlog:       N
  blocked:       N
  orphan-sprint: N

Milestone targets: all empty — run /roadmap init to assign.
```

---

## Mode: update

Resync backlog.yaml from current story file Status fields.

### Phase 1 — Load

Read `production/backlog.yaml`. If missing: prompt to run `/backlog init` instead.

### Phase 2 — Resync Each Entry

For each story in backlog.yaml where `file != "[missing]"`:
1. Re-read the story file (`file` field path)
2. Re-extract `status_raw`, `completed_date`, `sprint`
3. Apply Status Mapping
4. Record change if status differs from current backlog value

New story files (on disk but not in backlog): add them (same extraction as init Phase 2).

Missing story files (path in backlog but file deleted): change status to `archived`.

### Phase 3 — Write

Changes found → display diff table, ask write approval, write backlog.yaml.
No changes → "Backlog is current — no updates needed."

---

## Mode: view

Generate `production/backlog.md` — human-readable project backlog view.

### Phase 1 — Read

Read `production/backlog.yaml`. If missing: "Run `/backlog init` first."

Read `production/sprint-status.yaml` for active sprint number.

### Phase 2 — Filter (optional args)

- `--milestone [name]` — show only stories with `milestone_target: [name]`
- `--status [status]` — show only stories with matching status
- `--epic [slug]` — show only stories in specified epic

### Phase 3 — Generate + Write

Group stories by epic. Within each epic, sort: in-sprint → ready → backlog → carried-over → done.

Ask: "May I write `production/backlog.md`? [Y/N]"

Output format:

```markdown
# Project Backlog
Generated: [date] | Stage: [stage] | Active Sprint: N

## Summary
| Status | Count | Est. Days |
|--------|-------|-----------|
| done | N | N |
| in-sprint | N | N |
| carried-over | N | N |
| backlog | N | N |
| blocked | N | N |

## [Epic Display Name]
| ID | Name | Status | Priority | Sprint | Est | Milestone |
|----|------|--------|----------|--------|-----|-----------|
| S5-09 | Implement LootDropSystem | done | should-have | 5 | 1.5d | — |
```

---

## Mode: story [id] [status]

Update a single story's status directly in `backlog.yaml`.

Valid statuses: `backlog` `ready` `in-sprint` `done` `carried-over` `blocked` `cancelled`

If `status: done` and no `completed_date` set: use today's date.

Show current → new status diff. Ask write approval. Write.

---

## Schema: backlog.yaml

```yaml
# production/backlog.yaml
# Canonical story registry. Source of truth for all stories across all sprints.
# sprint-status.yaml is a GENERATED VIEW of the current sprint — regenerate with /sprint-plan if lost.
# Update this file via: /story-done, /sprint-close, /sprint-plan new, /backlog update
schema_version: "1.0"
generated: "YYYY-MM-DD"

stories:
  - id: "S5-09"
    epic: economy
    name: "Implement LootDropSystem"
    file: production/epics/economy/story-004-loot-drop-impl.md
    status: done            # backlog | ready | in-sprint | done | carried-over | blocked | cancelled | archived | orphan-sprint-entry
    milestone_target: ""   # assigned by /roadmap init
    priority: should-have  # must-have | should-have | nice-to-have | ""
    estimate_days: 1.5
    sprint: 5              # integer or null
    completed_date: "2026-06-09"
    tags:
      - logic
      - integration
```

**Status reference:**

| Status | Meaning |
|--------|---------|
| `backlog` | Exists, not yet planned into a sprint |
| `ready` | Dependencies met; prioritized for next sprint planning |
| `in-sprint` | Currently in the active sprint |
| `done` | Completed and accepted |
| `carried-over` | Was in a closed sprint but not completed |
| `blocked` | Blocked by unresolved dependency or external factor |
| `cancelled` | Removed from scope |
| `archived` | Story file deleted from disk |
| `orphan-sprint-entry` | In sprint-status.yaml but story file missing |

---

## Staleness Warning

This file can go stale if skills that close stories (`/story-done`) and close sprints (`/sprint-close`) do not write to it. Phase 2 (Write Path) wires those skills to keep this file current. Until Phase 2 is complete, run `/backlog update` after each story completion or sprint close to resync.
