---
name: code-recon
description: "Map the full dependency footprint of a file or system before touching it. Finds all callers, callees, event/signal connections, scene/prefab references, and global singletons. Engine-aware: reads technical-preferences.md and applies Godot, Unity, or Unreal heuristics. Read-only — produces a map, makes no changes."
argument-hint: "[file-path | system-name]"
user-invocable: true
allowed-tools: Read, Glob, Grep
model: sonnet
---

> **Make no changes during this skill.** Read-only reconnaissance only. Output the map, then stop. The implementing agent uses the map — it does not act on findings here.

## Phase 1 — Identify Target and Engine

**Detect engine:** Read `.claude/docs/technical-preferences.md`, extract the `Engine:` field.
- `Godot` → apply Godot heuristics throughout
- `Unity` → apply Unity heuristics throughout
- `Unreal Engine` / `Unreal` → apply Unreal heuristics throughout
- Unconfigured / `[TO BE CONFIGURED]` → apply generic heuristics, note the limitation in output

**Identify target:**
- Path argument (contains `/` or known extension): treat as file target directly.
- System name (e.g. "combat", "inventory"): Glob `src/**/*[name]*` to find candidates, pick the most likely entry point.
- No argument: ask "What file or system should I map?" then proceed.

Read `docs/CONTEXT.md` if it exists. Note canonical terms relevant to the target.

---

## Phase 2 — Read the Target

Read the target file in full. Extract based on engine:

### Godot
- **Public API:** `func` declarations — name and parameter list
- **Signals emitted:** `signal` declarations; `emit_signal()` and `.emit()` call sites
- **Signal connections:** `connect()` calls; `@onready` signal subscriptions
- **Autoloads referenced:** bare identifiers matching autoload names from `project.godot`
- **Editor exposure:** `@export` declarations
- **Asset references:** `preload()`, `load()`, `PackedScene` — note paths
- **Scene target:** if `.tscn`, extract attached script, child node types, `[ext_resource]` refs

### Unity
- **Public API:** `public` and `protected` C# method signatures
- **Events:** `UnityEvent`, C# `event`/`delegate`/`Action<>`/`Func<>` fields
- **Event subscriptions:** `+=` on event/delegate fields; `AddListener()` calls
- **Globals:** `static Instance`; `ServiceLocator.Get<>()`; `FindObjectOfType<>()`; `GetComponent<>()` on external objects
- **Inspector exposure:** `[SerializeField]`, `[Header]`, bare `public` fields
- **Asset references:** `Resources.Load`, `Addressables.LoadAssetAsync`, `[SerializeReference]`
- **Prefab target:** if `.prefab`, extract attached components and child hierarchy

### Unreal
- **Public API:** `UFUNCTION()` declarations; public C++ method signatures
- **Delegates:** `DECLARE_DELEGATE`, `DECLARE_MULTICAST_DELEGATE`, `DECLARE_DYNAMIC_MULTICAST_DELEGATE` declarations
- **Delegate bindings:** `.AddDynamic()`, `.AddUObject()`, `.Broadcast()` call sites
- **Globals:** `GetGameInstance()`, `GetGameMode()`, `UGameplayStatics::`, subsystem `GetSubsystem<>()`
- **Editor exposure:** `UPROPERTY()` with any specifier — note `EditAnywhere`, `BlueprintCallable`, `Replicated`
- **Asset references:** `TSoftObjectPtr`, `TSubclassOf`, `ConstructorHelpers::FObjectFinder`
- **Blueprint target:** if `.uasset`, note it requires the Unreal editor to inspect — flag for manual review

---

## Phase 3 — Find Callers

Grep the source tree for references to the target's class name, file path, and public API entry points.

### Godot
```
grep -r "[ClassName]" src/
grep -r "res://[relative-path-to-target]" src/
grep -r "[scene-filename]" scenes/
```
Check `project.godot` for autoload registration — if registered, flag as global dependency.

### Unity
```
grep -r "[ClassName]" Assets/ --include="*.cs"
grep -r "GetComponent<[ClassName]>" Assets/ --include="*.cs"
grep -r "FindObjectOfType<[ClassName]>" Assets/ --include="*.cs"
grep -r "[ClassName]" Assets/ --include="*.prefab"
```
Check for `[RequireComponent(typeof([ClassName]))]` — implicit coupling.

### Unreal
```
grep -r "[ClassName]" Source/ --include="*.h"
grep -r "[ClassName]" Source/ --include="*.cpp"
grep -r "TSubclassOf<[ClassName]>" Source/
grep -r "Cast<[ClassName]>" Source/
```
Note: Blueprint references to C++ classes require the editor — flag if Blueprint callers are likely.

### Generic fallback
```
grep -r "[ClassName]" src/
grep -r "[filename-without-extension]" src/
```

For each caller: note file path, line number, and what it is calling.

---

## Phase 4 — Produce the Map

Output in this format. Use engine-appropriate field names in brackets:

```
## Code Recon: [target file or system name]
Engine: [Godot | Unity | Unreal | Unknown]

Entry point:   [file path]
[Scene/Prefab/Blueprint]: [attached asset path, if applicable]
[Autoload/Singleton/Subsystem]: [YES — registered as "[name]"] | NO

### Callers  (N files reference this)
- [file]:[line] — [what it calls / how it uses the target]

### Callees  (this depends on)
- [file, autoload, service, or subsystem] — [what is called]

### [Signals / Events / Delegates]
- Emits/Broadcasts: [name]([params]) → connected by [callers if known]
- Listens to:       [source].[name] → [handler]

### [Scene refs / Prefab refs / Asset refs]
- Loads:           [asset paths loaded at runtime]
- Instantiated by: [files or assets that spawn this]

### [Exports / Inspector fields / UPROPERTY fields]
- [annotation] [type] [name] — [purpose if inferable]

### CONTEXT.md terms
- [term] — canonical ✓ | forbidden alias ✗ (correct term: [X])

### Risk zones
- [engine-specific risk flags — see below]
```

Omit sections with nothing to report.

---

## Risk Zone Reference by Engine

Include only applicable risks found during the recon.

### Godot
- Script >300 lines → likely God Script, split by responsibility
- Signal chain 3+ hops → cascade risk on interface changes
- `get_node("../../...")` direct path → fragile, replace with signal or `@export`
- Registered autoload + many callers → global dependency, interface changes are breaking
- Missing `@export` for values that should be tunable → hardcoded, not data-driven

### Unity
- `FindObjectOfType<>()` in hot path → expensive, use injection or cached ref
- `static Instance` singleton → tight coupling, hard to test; prefer ScriptableObject events or dependency injection
- MonoBehaviour >300 lines → God Object; split into components
- `Update()` doing non-trivial work → profile first before changing
- Deep event chain (3+ `UnityEvent` hops) → cascade risk
- Missing `[SerializeField]` on tunables → hardcoded, not inspector-driven

### Unreal
- `Cast<>()` at every callsite → missing interface abstraction
- Blueprint doing heavy logic → should be C++; Blueprint for wiring only
- Direct `AActor*` ref without null check → crash risk on actor destruction
- `Tick()` doing non-trivial work → profile; many systems should be event-driven
- `UPROPERTY` without `Replicated` on networked actors → replication gap
- Missing `GameplayTag` where string comparison is used → brittle, not data-driven

### Generic
- File >300 lines → likely oversized; assess split
- No test coverage found in `tests/` → write regression test before modifying
- Many callers (>5) → high blast radius; changes need broader review

---

## Phase 5 — Finish

Verdict: **COMPLETE** — recon done. No changes made. Engine: [detected].

If engine was unconfigured: "Run `/setup-engine` to enable engine-specific pattern detection."

If invoked standalone, flag the top risks and suggest next steps:
- Many callers or large file: "Consider `/improve-codebase-architecture --focus [path]`."
- Event/signal chain 3+ deep: "Interface changes will cascade — map the full chain before proceeding."
- Registered global: "Any API change here affects the whole project."
- No tests: "Write a regression test before modifying this system."
