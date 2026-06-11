---
name: export-module
description: Extract a game system as a reusable module package — source files, ADRs, GDD sections, and tests — into exports/modules/[name]/. Performs boundary analysis to classify dependencies as logic/engine-API/project-specific before extracting. Read-only on src/; writes only to exports/modules/.
model: sonnet
argument-hint: "[system-name] — e.g. /export-module economy"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Task, AskUserQuestion
---

# /export-module

Packages a game system for reuse: boundary analysis → coupling report → extraction plan → user approval → package write.

**Key constraint:** This skill is **read-only on `src/`**. It writes only to `exports/modules/[system-name]/`. The developer integrates the extracted package into the target project manually.

**Output:** `exports/modules/[system-name]/`
```
src/          — extracted source files (copies, not moves)
docs/         — relevant GDD sections + governing ADRs
tests/        — extracted test files
README.md     — module overview, integration instructions, adapter interface
ADAPTER.md    — project-specific integration points the receiver must implement
```

---

## Phase 1 — Identify System

**Argument:** `$ARGUMENTS[0]` = system name (e.g. `economy`, `inventory`, `combat`).

If no argument: use `AskUserQuestion`:
- Prompt: "Which system do you want to export as a reusable module?"
- Options: list any epics found in `production/backlog.yaml`, or `[E] Enter name manually`

### Locate source files

1. Glob `src/**/*[system-name]*` (case-insensitive) to find source files.
2. Also grep `src/` for the system name in class definitions, autoload registrations, or file headers.
3. If zero files found: stop — "No source files found for '[name]'. Check the system name and try again."

Record the file list as the **candidate source set**.

### Locate ADRs

Grep `docs/architecture/ADR-*.md` for the system name. For each matching ADR:
- Read `## Summary` and `## Engine Compatibility` sections only (not the full ADR)
- Record: ADR number, title, engine compatibility Knowledge Risk level

If zero ADRs found: note as **ADR-less system** — package will be code-only with a warning.

### Locate GDD sections

Grep `design/gdd/` for the system name. Record matching files + the section headings that mention the system.

### Locate test files

Glob `tests/**/*[system-name]*`. Record matching files.

### Code-recon check

Check `docs/export/code-recon-[system-name].md` for a cached dependency map.
- If found and recent (within 30 days): use it.
- If not found: spawn a `lead-programmer` subagent via Task to run `/code-recon [system-name]` and return the dependency map. Use that output for Phase 2.

---

## Phase 2 — Boundary Analysis

For each file in the candidate source set, classify every external dependency:

### Dependency classes

| Class | Definition | Portability |
|-------|-----------|-------------|
| **Logic** | Pure code — formulas, state machines, data structures; no engine calls | Fully portable |
| **Engine API** | Engine-specific calls — `get_node()`, `$Node`, signals, `GetComponent()`, delegates | Portable with adapter layer |
| **Project coupling** | Hardcoded project-specific references — autoload names, scene paths, project constants, global singletons | Not portable — must abstract |

### Classification heuristics

**Godot projects** — flag as Engine API:
- `get_node()`, `$NodeName`, `find_child()`, `get_parent()`
- Signal `emit_signal()` / `connect()` calls to nodes outside the system
- `preload()` / `load()` with `res://` paths outside the system's own directory
- `Engine.get_singleton()`, autoload access by name

Flag as Project coupling:
- Hardcoded autoload names (e.g. `GameManager.get_part(...)` where `GameManager` is a project autoload)
- Scene paths that reference other systems' scenes (`res://src/other_system/...`)
- Hardcoded constants defined in another system's file

**Unity projects** — Engine API: `GetComponent`, `FindObjectOfType`, `UnityEvent`, `ScriptableObject` references outside the system. Project coupling: hardcoded GameObject names, scene references, `GameManager` singleton access.

**Unreal projects** — Engine API: `TSubclassOf`, `TWeakObjectPtr`, delegates, `GetWorld()`. Project coupling: hardcoded `UGameInstance` subclass access, level-specific references.

### Output per file

```
File: src/[path]/[filename]
  Logic:            [N] dependencies — [list key ones]
  Engine API:       [N] dependencies — [list key ones]
  Project coupling: [N] dependencies — [list each one explicitly]
```

Sum totals across all files.

---

## Phase 3 — Coupling Report

Present findings before proceeding:

```
## Boundary Analysis: [system-name]

Source files: [N] | ADRs: [N] | GDD sections: [N] | Test files: [N]

Dependency Summary:
  Logic (portable):        [N] dependencies
  Engine API (adaptable):  [N] dependencies
  Project coupling (stuck): [N] dependencies

Project Coupling Details — these must be abstracted before the module is reusable:
  1. [file:line] — [description] — Suggested: [abstraction approach]
  2. [file:line] — [description] — Suggested: [abstraction approach]
  ...

Portability Assessment:
  [HIGH]   — 0 project couplings. Drop-in portable.
  [MEDIUM] — 1–3 project couplings. Adapter layer needed.
  [LOW]    — 4+ project couplings. Significant abstraction required.

ADR Coverage:
  [covered] — [N] ADRs govern this system
  [WARNING] — No ADRs found. Exported module will have no documented contracts.
              Run /architecture-decision first for a complete export.

Engine Compatibility Risk: [LOW/MEDIUM/HIGH — highest risk across governing ADRs]
```

Pause for user review. Use `AskUserQuestion`:
- Prompt: "Portability is [level]. Proceed with extraction plan? [Y/N/Edit]"
- Options:
  - `[A] Yes — proceed`
  - `[B] No — stop here`
  - `[C] I want to fix the couplings first — pause`

If `[C]`: stop. Tell user which files to edit and what couplings to resolve. They re-run `/export-module` after fixing.

---

## Phase 4 — Extraction Plan

Generate the extraction plan (do not write files yet):

```
## Extraction Plan: exports/modules/[system-name]/

Files to copy (no changes needed):
  → src/[system-name]/[file].gd → exports/modules/[system-name]/src/

Files requiring adaptation (project couplings to stub out):
  → src/[system-name]/[file].gd → exports/modules/[system-name]/src/
     Adaptation: [what changes — e.g. "Replace GameManager autoload with injected IDependency parameter"]

Docs to include:
  → design/gdd/[section].md sections: [list headings] → exports/modules/[system-name]/docs/
  → docs/architecture/ADR-[NNNN]-*.md → exports/modules/[system-name]/docs/

Tests to copy:
  → tests/[system-name]/[file].gd → exports/modules/[system-name]/tests/

Files to generate:
  → exports/modules/[system-name]/README.md (generated)
  → exports/modules/[system-name]/ADAPTER.md (generated)
```

Ask: "May I write this extraction to `exports/modules/[system-name]/`? [Y/N]"

---

## Phase 5 — Package Write

On approval:

### 5a. Copy source files

For each "copy" file: write verbatim to `exports/modules/[system-name]/src/`.

For each "adaptation" file: write to `exports/modules/[system-name]/src/` with:
- Project coupling lines replaced by a `# ADAPTER: [description]` comment stub
- A `# TODO: inject [dependency] — see ADAPTER.md` at the top of the file

Do NOT modify the originals in `src/`.

### 5b. Copy docs

For GDD sections: extract the relevant section(s) only (from heading to next same-level heading). Write to `exports/modules/[system-name]/docs/gdd-[source-filename].md`.

For ADRs: copy in full to `exports/modules/[system-name]/docs/`.

### 5c. Copy tests

Write verbatim to `exports/modules/[system-name]/tests/`. Note that tests referencing project couplings may fail in the target project — add a comment block at top of each adapted test file listing assumptions.

### 5d. Generate README.md

```markdown
# Module: [system-name]
Extracted from: [project name] | Date: [YYYY-MM-DD]
Engine: [from ADR Engine Compatibility or "Unspecified"]
Portability: [HIGH/MEDIUM/LOW]

## What This Module Does
[2-sentence summary from the GDD or ADR Summary field]

## Integration
1. Copy `src/` into your project's source directory.
2. Implement the interfaces listed in `ADAPTER.md`.
3. [Any engine-specific wiring steps — e.g. "Register as autoload in Godot project settings"]

## Dependencies
| Dependency | Class | Notes |
|-----------|-------|-------|
| [name] | Logic / Engine API / Adapter | [how to satisfy] |

## Architecture
[ADR Summary fields, one paragraph each, for each governing ADR]

## Test Coverage
[N] test files included. Run with [engine test command].
Known test assumptions: see comments in `tests/` files.
```

### 5e. Generate ADAPTER.md

```markdown
# Adapter Interface: [system-name]
These are the project-specific integration points the receiver must implement.
Each stub in `src/` has a `# ADAPTER:` comment marking where to wire in your implementation.

## Required Integrations

### [Coupling 1 name]
**File:** `src/[filename]` — line [N]
**What it needs:** [what the system expects — e.g. "A part database that returns PartData by part_id"]
**Interface contract:**
```
[pseudocode or language-specific interface definition]
```
**Example implementation (Godot):** [one-liner showing how to wire it in]

### [Coupling 2 name]
...

## Optional Integrations
[Engine API adapters that have sensible defaults but can be overridden]
```

---

## Phase 6 — Summary

After writing:

```
✅ Module exported: exports/modules/[system-name]/

  src/      [N] files ([N] copied, [N] adapted)
  docs/     [N] files ([N] GDD sections, [N] ADRs)
  tests/    [N] files
  README.md
  ADAPTER.md — [N] integration points to implement

Portability: [HIGH/MEDIUM/LOW]
ADR coverage: [covered / WARNING: no ADRs]
Engine risk: [LOW/MEDIUM/HIGH]

Next steps:
  - HIGH portability: copy src/ into target project, run tests.
  - MEDIUM portability: implement ADAPTER.md stubs, then run tests.
  - LOW portability: review ADAPTER.md stubs first — significant wiring required.
  [If ADR-less]: Run /architecture-decision for [system-name] to add contract docs to future exports.
```

Verdict: COMPLETE — module exported to `exports/modules/[system-name]/`.
