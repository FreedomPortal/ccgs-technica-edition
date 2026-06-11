---
name: refresh-docs
description: Audit engine reference doc staleness and populate module files via version-aware web fetch. audit: staleness report. update [engine] [module]: prompts for target version, uses WebSearch/WebFetch, writes with approval.
argument-hint: "[audit | update [engine] [module] [--web]]"
user-invocable: true
allowed-tools: Read, Glob, Write, WebSearch, WebFetch
model: sonnet
---

# /refresh-docs

Maintains `docs/engine-reference/` so agents always read accurate, version-specific API documentation.

Supports any engine, any version — past or future. Never hardcodes "latest". The `update` mode always asks which version to document before fetching anything.

## Modes

| Command | Description | Model |
|---------|-------------|-------|
| `/refresh-docs audit` | Scan for stale and missing module files | Haiku |
| `/refresh-docs update [engine] [module]` | Populate or refresh one module (version-aware) | Sonnet |

Supported engines: `godot`, `unity`, `unreal`

---

## Mode: audit

Read-only. Outputs a staleness report; writes nothing.

### Phase 1 — Load Config

Read `docs/engine-reference/README.md`.

Extract from YAML frontmatter (first `---` block):
- `staleness_threshold_days` (default: 90 if absent or not parseable)
- `analytics_staleness_threshold_days` (default: 365 if absent)

### Phase 2 — Scan Engine Reference Files

For each `.md` file under `docs/engine-reference/` (excluding `README.md` and `VERSION.md`):
1. Extract `Last verified: YYYY-MM-DD` date (case-insensitive, both "Last verified" and "Last Verified" match).
2. If line contains `[stub`, `[EMPTY`, or `not verified`: classify as **EMPTY-STUB** (skip date check).
3. If no date and not a stub: classify as **MISSING-DATE**.
4. If date found: calculate age in days from today.
   - Age > threshold → **STALE**
   - Age ≤ threshold → **OK**

### Phase 3 — Check Missing Modules

For each detected engine subdirectory under `docs/engine-reference/`:

**Expected for all engines:**

| File | Priority |
|------|----------|
| `modules/scripting.md` | HIGH |
| `modules/scene-management.md` | HIGH |
| `modules/rendering.md` | MEDIUM |
| `modules/physics.md` | MEDIUM |
| `modules/animation.md` | MEDIUM |
| `modules/audio.md` | MEDIUM |
| `modules/input.md` | MEDIUM |
| `modules/navigation.md` | MEDIUM |
| `modules/networking.md` | MEDIUM |
| `modules/ui.md` | MEDIUM |
| `PLUGINS.md` | MEDIUM |
| `breaking-changes.md` | MEDIUM |
| `current-best-practices.md` | MEDIUM |
| `deprecated-apis.md` | MEDIUM |

**Godot only:**

| File | Priority |
|------|----------|
| `modules/csharp.md` | MEDIUM |
| `modules/build-export.md` | LOW |

**Unity only:**

| File | Priority |
|------|----------|
| `modules/build-export.md` | LOW |

Mark each file as: PRESENT (has real date) | EMPTY-STUB | MISSING.

### Phase 4 — Analytics Reference Check

Check `docs/reference/analytics/genre-benchmarks.md`:
- Missing → report as MISSING.
- Present: extract `Last Verified:` date, calculate age vs `analytics_staleness_threshold_days`.
- Flag as STALE or OK.

### Phase 5 — Output Report

```
# Engine Reference Audit — [YYYY-MM-DD]
Threshold: [N] days | Engines: [list]

## Stale Files (verified but > [N] days ago)
| Engine | File | Last Verified | Age |
|--------|------|--------------|-----|

## Empty Stubs (created but not populated)
| Engine | File | Priority | Populate with |
|--------|------|----------|---------------|
| godot | modules/scripting.md | HIGH | /refresh-docs update godot scripting --web |

## Missing Files (not yet created)
| Engine | File | Priority |
|--------|------|---------|

## Analytics Reference
| File | Status | Last Verified | Age |
|------|--------|--------------|-----|

## Summary
- OK: N files current
- Stale: N files need refresh
- Stubs: N files need population
- Missing: N files need creation

## Recommended Actions (priority order)
1. /refresh-docs update [engine] [module] --web   [HIGH — empty stub]
...
```

If everything is current: "All engine reference files are within the [N]-day threshold."

---

## Mode: update [engine] [module]

Populates or refreshes a single module file. Always asks for the target version first.

### Module Path Mapping

| Argument | File |
|----------|------|
| `scripting` | `modules/scripting.md` |
| `csharp` | `modules/csharp.md` (Godot only) |
| `scene-management` | `modules/scene-management.md` |
| `rendering` | `modules/rendering.md` |
| `physics` | `modules/physics.md` |
| `animation` | `modules/animation.md` |
| `audio` | `modules/audio.md` |
| `input` | `modules/input.md` |
| `navigation` | `modules/navigation.md` |
| `networking` | `modules/networking.md` |
| `ui` | `modules/ui.md` |
| `build-export` | `modules/build-export.md` |
| `plugins` | `PLUGINS.md` |
| `breaking-changes` | `breaking-changes.md` |
| `best-practices` | `current-best-practices.md` |
| `deprecated` | `deprecated-apis.md` |

### Phase 1 — Validate + Version Prompt

1. Validate `[engine]` is a known engine directory under `docs/engine-reference/`.
2. Resolve module argument to file path using the mapping table above.
3. Read `docs/engine-reference/[engine]/VERSION.md` for the currently pinned version and last verified date.
4. If module file exists and has a real date: show current status.

Present:

```
Updating: docs/engine-reference/[engine]/[module-path]
Currently pinned engine version: [version] (pinned: [date])
Current module status: [OK / STALE since YYYY-MM-DD / EMPTY-STUB / MISSING]

Target version to document?
Examples: "Godot 4.6", "Unity 6.1", "Unreal Engine 5.5"
Leave blank to refresh same version ([current]):
```

Wait for user input before proceeding.

### Phase 2 — Without `--web` Flag (default)

Output a structured manual checklist and stop. Do not write.

```
## Manual Verification Checklist — [Engine] [Module]
Target version: [version]

Official documentation to check:
[engine-specific URLs for this module — see URL Patterns below]

Steps:
1. Open the migration guide for [version]
2. Find entries relevant to [module domain]
3. Note any API changes, new patterns, or deprecations
4. Run `/refresh-docs update [engine] [module] --web` to auto-populate from these sources
   (or populate the file manually using template: .claude/docs/templates/engine-ref-module.md)
```

### Phase 3 — With `--web` Flag

Use WebSearch to locate:
1. Official migration guide for `[engine]` from the previous version to `[target-version]`
2. Changelog entries for `[target-version]` relevant to `[module]` domain
3. Official API reference for `[module]` domain in `[target-version]`

**URL patterns by engine (WebSearch starting points):**

- **Godot**: `site:docs.godotengine.org upgrading_to_godot_[version]` + official changelog
- **Unity**: `site:docs.unity3d.com UpgradeGuide [version]`
- **Unreal**: `site:dev.epicgames.com "[version] release notes"`

Use WebFetch on the most relevant URLs found. Extract only information relevant to the `[module]` domain.

### Phase 4 — Draft

Compose module file content using `.claude/docs/templates/engine-ref-module.md` as format guide:

- `Last verified: [today's date]` | `Engine: [Engine Name target-version]`
- `## What Changed Since ~[previous-version]` — API changes from changelog, grouped by version
- `## Current API Patterns` — correct code examples for `[target-version]`
- `## Common Mistakes` — old patterns (still in LLM training data) that are now wrong
- `## Official Documentation` — URLs fetched + canonical reference links

**Accuracy rule**: Only include claims that appeared in the fetched official docs. If a change wasn't found in official sources, omit it or mark `[needs-verification]`. Never fabricate API details.

Present draft to user before writing.

### Phase 5 — Write

Ask: "May I write `docs/engine-reference/[engine]/[module-path]`? [Y/N]"

On approval:
- Write module file.
- If version changed from pinned: ask "Update VERSION.md pinned version to [target-version]? [Y/N]"

---

## Official Documentation URL Reference

Keep these updated as engine doc sites change:

### Godot
- Migration guides: `https://docs.godotengine.org/en/stable/tutorials/migrating/`
- Changelog: `https://github.com/godotengine/godot/blob/master/CHANGELOG.md`
- Release notes: `https://godotengine.org/releases/`
- GDScript: `https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/`
- C#: `https://docs.godotengine.org/en/stable/tutorials/scripting/c_sharp/`

### Unity
- Upgrade guides: `https://docs.unity3d.com/Manual/UpgradeGuides.html`
- Release notes: `https://unity.com/releases/editor/whats-new/`

### Unreal Engine
- Release notes: `https://dev.epicgames.com/documentation/en-us/unreal-engine/unreal-engine-5-release-notes`
- Migration guide: `https://dev.epicgames.com/documentation/en-us/unreal-engine/updating-and-migrating-projects-in-unreal-engine`

---

## Recommended Next Steps

Verdict: COMPLETE — engine reference updated.

- Run `/refresh-docs audit` to check overall reference health after updates
- Run `/refresh-docs update [engine] [module] --web` to populate additional modules
