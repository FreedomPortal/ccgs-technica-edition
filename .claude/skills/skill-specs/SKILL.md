---
name: skill-specs
description: "Author missing behavioral test spec files for skills in the CCGS Skill Testing Framework. Two modes: single skill (interactive, one spec) or missing (batch all skills with no spec assigned in catalog.yaml). Produces CCGS Skill Testing Framework/skills/[category]/[name].md."
argument-hint: "[skill-name | missing]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit, Task
model: sonnet
---

> **Explicit invocation only**: Only run when the user explicitly calls `/skill-specs`.

## Phase 1: Parse Argument

Read the first argument.

- `missing` → go to **Phase 1B** (batch mode)
- `[skill-name]` → continue to Phase 2 (single-skill mode)
- Missing argument → output usage and stop:

```
Usage: /skill-specs [skill-name]
       /skill-specs missing
Example: /skill-specs gate-check
Example: /skill-specs missing
```

For single-skill mode: verify `.claude/skills/[name]/SKILL.md` exists. If not, stop:
"Skill '[name]' not found at `.claude/skills/[name]/SKILL.md`."

---

## Phase 1B: Missing Mode — Batch Spec Authoring

### Step 1 — Build Queue

Read `CCGS Skill Testing Framework/catalog.yaml`.

Collect all skill entries where `spec:` is an empty string `""` OR the `spec:` field is absent.

For each candidate, also check whether the spec file already exists on disk at the
`spec:` path recorded in catalog. If the path is set AND the file exists: skip — do not overwrite.

Display the queue:

```
=== Skill Specs: Missing Mode ===
Skills with no spec file: [N]
Skipped (spec path set and file exists on disk): [N]

Queue:
  1. [skill-name]  ([category])  priority: [priority]
  2. [skill-name]  ([category])  priority: [priority]
  ...

This will author [N] spec files. Proceed? [y/N]
```

If user declines, stop.

### Step 2 — Load Shared Context

Read once, reuse for all Tasks:
- `CCGS Skill Testing Framework/templates/skill-test-spec.md`
- `CCGS Skill Testing Framework/quality-rubric.md`

### Step 3 — Spawn Parallel Tasks

For each skill in the queue, spawn a Task with the authoring prompt from **Phase 3**
(substituting skill name, category, priority, and skill content).

Run Tasks in parallel — do not wait for one to finish before starting the next.

Each Task must:
1. Read the skill file at `.claude/skills/[name]/SKILL.md`
2. Author the spec content from scratch based on written instructions only
3. Return the spec content as plain text — do NOT write any files

### Step 4 — Collect Results

Wait for all Tasks to complete. Collect each returned spec body with its skill name.

Display summary:
```
Specs authored: [N]
Failed to produce: [N]  (list any that returned errors)

May I write all [N] spec files and update CCGS Skill Testing Framework/catalog.yaml?
  Paths:
    CCGS Skill Testing Framework/skills/[category]/[name].md
    [... list all]
```

Wait for confirmation before writing anything.

### Step 5 — Write and Update

For each spec in the collected results:
- Create the directory `CCGS Skill Testing Framework/skills/[category]/` if it does not exist
- Write the spec file to `CCGS Skill Testing Framework/skills/[category]/[name].md`
- Update the skill's `spec:` field in catalog.yaml to the file path just written

Update catalog.yaml in one pass for all N skills.

### Step 6 — Summary

```
=== Skill Specs: Missing Mode Complete ===

Specs written:  [N]
Skipped:        [N]  (already had spec files)
Failed:         [N]  (list if any)

Catalog updated: CCGS Skill Testing Framework/catalog.yaml

Next steps:
  /skill-test spec [name]    — verify a single spec against the live skill
  /skill-test suite          — regenerate full suite report with new spec coverage
  /skill-improve [name]      — fix any skill that spec evaluation surfaces as failing

Verdict: COMPLETE — [N] spec files authored.
```

---

## Phase 2: Single Mode — Read Skill

Read the skill file at `.claude/skills/[name]/SKILL.md` in full.

Read `CCGS Skill Testing Framework/catalog.yaml` to find:
- `category:` for this skill (needed for output path and rubric)
- `priority:` for this skill

Check for an existing spec:
- If `spec:` is set in catalog AND the file exists on disk: ask:
  - "A spec already exists at [path]. Overwrite it, or view and update the existing one?"
  - Options: `Overwrite` | `Update` | `Cancel`
  - If Cancel: stop.
  - If Update: read the existing spec file first, then proceed to Phase 3 with the existing content as starting point.

---

## Phase 3: Author Spec

Read:
- `CCGS Skill Testing Framework/templates/skill-test-spec.md` — structure template
- `CCGS Skill Testing Framework/quality-rubric.md` — category-specific rubric for this skill's category

Spawn a `general-purpose` subagent via Task with this prompt, substituting values:

```
You are authoring a behavioral test spec for the CCGS Skill Testing Framework.

Skill: /[NAME]
Category: [CATEGORY]
Priority: [PRIORITY]
Spec template: [PASTE TEMPLATE CONTENT]
Category rubric section: [PASTE MATCHING RUBRIC SECTION]

Skill content:
---
[PASTE FULL SKILL.MD CONTENT]
---

Author a complete spec file following the template structure exactly.

CRITICAL RULES:
- Document what the skill's WRITTEN INSTRUCTIONS actually do.
- Do not infer intent. Do not write what the skill should ideally do.
- If a phase is missing from the skill, that is a gap — note it in Coverage Notes.
- Test Case 5 (Director Gate): use it ONLY if this skill explicitly triggers
  director gate reviews. If it does not, replace Case 5 with the most relevant
  variant — an additional mode, edge case, or batch behavior.

For each test case, derive the fixture from what the skill's Phase 1 or Phase 2
actually reads. For expected behavior, follow the skill's phases step by step.
For assertions, verify that the skill's written instructions would satisfy each
one given the fixture — do not assert behaviors the skill does not specify.

Return the complete spec file content as plain text. Do not write any files.
```

After the Task completes, present the spec to the user for review.

---

## Phase 4: Review and Confirm

Present the authored spec inline. Ask:

"May I write this spec to `CCGS Skill Testing Framework/skills/[category]/[name].md`?"

Wait for confirmation before writing.

---

## Phase 5: Write Spec and Update Catalog

Create the directory `CCGS Skill Testing Framework/skills/[category]/` if it does not exist.

Write the spec to `CCGS Skill Testing Framework/skills/[category]/[name].md`.

Update the skill's entry in `CCGS Skill Testing Framework/catalog.yaml`:
- Set `spec: "CCGS Skill Testing Framework/skills/[category]/[name].md"`

Ask: "May I update `CCGS Skill Testing Framework/catalog.yaml` to record the spec path for [name]?"

Wait for confirmation before writing catalog.

---

## Phase 6: Next Steps

```
Spec written: CCGS Skill Testing Framework/skills/[category]/[name].md
Catalog updated: spec path recorded for /[name]

Next steps:
  /skill-test spec [name]    — evaluate this spec against the live skill
  /skill-improve [name]      — fix the skill if spec evaluation finds failures
  /skill-specs missing       — author remaining missing specs in batch
```

---

## Collaborative Protocol

- **Never write files without asking** — Phase 4 and Phase 5 each require explicit approval
- **Tasks are read-only** — subagents read and return text; all file writes happen in the parent skill
- **Never overwrite an existing spec without asking** — Phase 2 checks and prompts before proceeding
- **Specs describe current behavior** — if the skill does something incorrectly, the spec records that; the skill is fixed separately via `/skill-improve`
- **catalog.yaml update is always a separate ask** — spec file write and catalog update are two distinct approval steps in single mode
