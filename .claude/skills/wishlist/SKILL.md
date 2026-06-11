---
name: wishlist
description: "Capture and manage emerging ideas not yet committed to the backlog. Modes: add, view, promote [id], defer [id], prune."
argument-hint: "[add | view | promote <id> | defer <id> | prune]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit, AskUserQuestion
model: sonnet
---

# /wishlist

A lightweight holding area for emerging ideas and uncertain features that are not yet committed work.

The backlog holds committed stories. The wishlist holds everything that might become one.

**Data file:** `production/wishlist.yaml`

---

## Modes

| Command | What it does |
|---------|-------------|
| `/wishlist add` | Capture a new idea interactively |
| `/wishlist view` | Render wishlist as human-readable markdown in chat |
| `/wishlist promote [id]` | Graduate an idea to committed work |
| `/wishlist defer [id]` | Mark as deferred — keep but deprioritize |
| `/wishlist prune` | Bulk-review raw and deferred items |

If no argument given: show mode list and ask which to run.

---

## Schema: wishlist.yaml

```yaml
# production/wishlist.yaml
# Wishlist — holding area for uncommitted ideas.
# Items stay here until promoted to the backlog/epics or explicitly pruned.
# IDs are auto-assigned and never reused.

items:
  - id: WL-001
    title: "..."
    description: "..."   # 1-3 sentences on the idea
    category: feature    # feature | content | polish | tech | monetization | qol
    rough_size: m        # xs | s | m | l | xl (gut feel, not estimate)
    status: raw          # raw | refined | deferred | promoted
    added: "YYYY-MM-DD"
    notes: ""            # optional: context, source (playtest/brainstorm/etc.)
    promoted_to: ""      # filled on promote — e.g. "production/epics/status-effects/EPIC.md"
```

**Status reference:**

| Status | Meaning |
|--------|---------|
| `raw` | Just captured — not yet thought through |
| `refined` | Description and size updated; ready to consider for promotion |
| `deferred` | Kept but explicitly deprioritized |
| `promoted` | Graduated to committed work (epic or story) |

---

## Mode: add

### Step 1 — Collect fields interactively

Use `AskUserQuestion` for each required field:

1. **Title** (required — reject blank)
2. **Description** (1-3 sentences — what is the idea and why does it matter?)
3. **Category** — feature / content / polish / tech / monetization / qol
4. **Rough size** — xs / s / m / l / xl (gut feel only, no breakdown needed)
5. **Notes** (optional — source: playtest feedback, brainstorm session, etc.)

### Step 2 — Auto-assign ID

Read `production/wishlist.yaml`. If the file exists and has items, find the highest existing WL-NNN number and increment by 1. If the file is missing or has no items, start at WL-001.

### Step 3 — Show draft + ask approval

Display the full YAML entry as it would appear in the file.

Ask: "May I add this to `production/wishlist.yaml`?"

### Step 4 — Write

If the file does not exist, create it with the schema header and the first item.

If the file exists, append the new item to `items:`.

Set `status: raw`, `added: [today's date YYYY-MM-DD]`, `promoted_to: ""`.

Confirm: "Added [id]: [title]."

---

## Mode: view

Read `production/wishlist.yaml`.

If missing: "No wishlist yet. Run `/wishlist add` to capture your first idea."

Output to chat only — do not write a file.

Group by status in this order: raw → refined → deferred → promoted.
Within each group, sort by `added` date (oldest first).

```
## Wishlist — [N] items ([N] raw, [N] refined, [N] deferred, [N] promoted)

### Raw
| ID | Title | Category | Size | Notes |
|----|-------|----------|------|-------|
| WL-001 | ... | feature | m | ... |

### Refined
| ID | Title | Category | Size | Notes |
|----|-------|----------|------|-------|

### Deferred
| ID | Title | Category | Size | Notes |
|----|-------|----------|------|-------|

### Promoted
| ID | Title | Promoted To |
|----|-------|------------|
| WL-005 | ... | production/epics/... |
```

Omit groups that have zero items.

---

## Mode: promote [id]

### Step 1 — Load and display item

Read `production/wishlist.yaml`. Find the item with the given ID.

If not found: "WL-NNN not found in wishlist.yaml."

If `status` is already `promoted`: "WL-NNN is already promoted (promoted_to: [path])."

Show the item's title and description.

### Step 2 — Ask destination

Use `AskUserQuestion`:
- Prompt: "How would you like to promote this idea?"
- Options:
  - `[A] New epic — I'll run /create-epics after this`
  - `[B] New story in an existing epic — I'll run /create-stories [epic-slug] after this`
  - `[C] Mark promoted manually — I'll handle placement myself`

For [A] or [B]: display a reminder note in chat:

> "After creating the epic or story, run `/wishlist promote [id]` again and choose [C] to record the destination path."

### Step 3 — Ask for path (option C only)

Use `AskUserQuestion`:
- Prompt: "Enter the path to the created epic or story file (or leave blank to skip):"

### Step 4 — Update wishlist.yaml

Set `status: promoted`. Set `promoted_to:` to the path if provided, or `""` if blank.

Ask: "May I update `production/wishlist.yaml`?"

On approval, write the change.

Confirm: "WL-NNN marked promoted."

---

## Mode: defer [id]

Read `production/wishlist.yaml`. Find the item with the given ID.

If not found: "WL-NNN not found in wishlist.yaml."

If already `deferred`: "WL-NNN is already deferred."

Ask: "May I update WL-NNN to deferred in `production/wishlist.yaml`?"

On approval, set `status: deferred`. Write file.

Confirm: "WL-NNN deferred."

---

## Mode: prune

### Step 1 — Load candidates

Read `production/wishlist.yaml`.

List all items where `status` is `raw` or `deferred`, sorted by `added` date (oldest first).

If none: "No raw or deferred items to prune."

### Step 2 — Per-item review

For each candidate item, display:

```
[WL-NNN] Title — Category, Size
Added: YYYY-MM-DD
Description: ...
Notes: ...
```

Use `AskUserQuestion`:
- Prompt: "What do you want to do with WL-NNN: [title]?"
- Options:
  - `[K] Keep as-is`
  - `[R] Refine — update description or size`
  - `[D] Defer`
  - `[X] Delete permanently`

For `[R]`: ask for updated description and/or rough size. Set `status: refined`.

Collect all decisions before writing.

### Step 3 — Apply and write

Show a summary of planned changes before writing:

```
Prune plan:
  [N] kept
  [N] refined
  [N] deferred
  [N] deleted
```

Ask: "May I apply these changes to `production/wishlist.yaml`?"

On approval:
- Apply refined, deferred, and kept updates in place.
- Remove deleted items from `items:` entirely. Their IDs are never reused.

Confirm: "Pruned: [N] deleted, [N] deferred, [N] refined, [N] kept."

---

## Collaborative Protocol

- Always ask before writing to `production/wishlist.yaml`
- Never auto-promote — user must confirm destination
- Promoted items stay in the file with `status: promoted` — they are the audit trail
- Deleted items are gone permanently — no archive; IDs are never reused
- This skill is a capture and triage tool, not a planning tool — no scope analysis, no estimates

---

## Recommended Next Steps

Verdict: COMPLETE — wishlist updated.

- Run `/roadmap update` to consider promoting refined items into milestone scope
- Run `/wishlist promote [id]` then `/create-epics` to graduate an item to committed work
- Run `/wishlist view` to review the full wishlist state
