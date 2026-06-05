---
name: code-recon
description: "Map the full dependency footprint of a file or system before touching it. Finds all callers, callees, signal connections, scene references, and autoload usage. Use before implementing in unfamiliar code or when a change might ripple across systems. Read-only — produces a map, makes no changes."
argument-hint: "[file-path | system-name]"
user-invocable: true
allowed-tools: Read, Glob, Grep
model: sonnet
---

> **Make no changes during this skill.** Read-only reconnaissance only. Output the map, then stop. The implementing agent uses the map — it does not act on findings here.

## Phase 1 — Identify Target

**If an argument is provided:**
- If it looks like a file path (contains `/` or `.gd`/`.cs`/`.tscn`): treat as file target.
- If it's a system name (e.g. "combat", "inventory"): Glob `src/**/*[name]*` to find candidate files. List them and pick the most likely entry point.

**If no argument:** ask "What file or system should I map?" Then proceed.

Read `docs/CONTEXT.md` if it exists. Note any canonical terms relevant to the target — use them in the map output.

---

## Phase 2 — Read the Target

Read the target file in full. Extract and hold:

- **Public API:** all functions/methods with `func` (GDScript) or `public`/`protected` (C#) — note names and signatures
- **Signals emitted:** `signal` declarations and `emit_signal()` / `.emit()` calls
- **Signals connected to:** `connect()` calls and `@onready` signal connections
- **Autoloads referenced:** any bare identifier that matches `project.godot` autoload names (e.g. `EventBus.`, `GameState.`, `AudioManager.`)
- **Exported variables:** `@export` declarations — these are editor-facing coupling points
- **Scene path references:** `preload()`, `load()`, `PackedScene` — note the paths

If the target is a `.tscn` scene file rather than a script: read it, extract attached script path, child node types, and `[ext_resource]` references.

---

## Phase 3 — Find Callers

Grep `src/` for references to the target's public API, class name, and file path:

```
grep -r "[ClassName]" src/
grep -r "[filename without extension]" src/
grep -r "res://[relative-path-to-target]" src/
```

Also grep `scenes/` for scene instantiation references:
```
grep -r "[target-scene-filename]" scenes/
```

For each caller found: note the file path, line number, and what it's calling.

**Check `project.godot`** for autoload registration — if the target is registered as an autoload, every file in the project is a potential caller.

---

## Phase 4 — Produce the Map

Output in this format:

```
## Code Recon: [target file or system name]

Entry point:  [file path]
Scene:        [attached scene path, if applicable] → [root node type]
Autoload:     [YES — registered as "[name]" in project.godot] | NO

### Callers  (N files reference this)
- [file]:[line] — [what it calls / how it uses the target]
- ...

### Callees  (this depends on)
- [file or autoload] — [what is called]
- ...

### Signals
- Emits:      [signal name]([params]) → connected by [callers if known]
- Listens to: [signal source].[signal name] → [handler function]

### Scene references
- Preloads:   [scene paths this file preloads]
- Instantiated by: [scenes that include this as a child or inst_scene]

### Exports
- @export [type] [var_name]  — [brief note on purpose if inferable]

### CONTEXT.md terms
- [term used in this system] — canonical / flagged as forbidden alias

### Risk zones
- [anything surprising: deep signal chains, circular references, direct node path access, God Script size, missing @export for hardcoded values]
```

Omit any section with nothing to report. Do not pad with "none found" entries.

---

## Phase 5 — Finish

State: **Recon complete.** No changes made.

If invoked standalone by the user: suggest next steps based on what was found:
- Large file (>300 lines) or many callers (>5): "Consider `/improve-codebase-architecture --focus [path]` before making changes."
- Signal chain 3+ hops deep: "Signal chain depth is a risk — changes to emitted signals will cascade."
- Registered autoload with many callers: "This is a global dependency — any interface change affects the whole project."
- No test coverage found in `tests/`: "No tests found for this system — write a regression test before modifying."
