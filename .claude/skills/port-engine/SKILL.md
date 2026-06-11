---
name: port-engine
description: Generate an engine porting guide — API inventory, ADR crosswalk, effort classification (direct/adaptation/rethink), and per-file effort estimate. Read-only analysis; writes to docs/porting/[source]-to-[target]-[date].md. Use when considering a platform or engine change.
model: sonnet
argument-hint: "[source-engine] [target-engine] — e.g. /port-engine godot unity | /port-engine godot unreal"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, AskUserQuestion
---

# /port-engine

Generates a migration guide for moving from one game engine to another.

**Scope:** Read-only analysis. Does not touch `src/`. Port execution is the developer's work; this skill produces the guide.

**Output:** `docs/porting/[source]-to-[target]-[YYYY-MM-DD].md`

---

## Supported Engine Pairs

| Source | Target |
|--------|--------|
| Godot  | Unity  |
| Godot  | Unreal |
| Unity  | Godot  |
| Unity  | Unreal |
| Unreal | Godot  |
| Unreal | Unity  |

Other pairs: proceed with best-effort API mapping; note unsupported pair in report header.

---

## Phase 1 — Parse Arguments

**Source engine:** `$ARGUMENTS[0]` (optional — auto-detect if omitted)
**Target engine:** `$ARGUMENTS[1]` (required)

If target missing: `AskUserQuestion` — "Which engine are you porting to?" with options: Godot / Unity / Unreal / Other.

**Auto-detect source engine:**
1. Read `technical-preferences.md` (or `.claude/docs/technical-preferences.md`) — look for `Engine:` field.
2. Else read `production/stage.txt` for hints.
3. Else ask: "Which engine is the source project built in?"

Normalize engine names: `godot` / `unity` / `unreal` (case-insensitive).

**Target engine reference:**
- Check `docs/engine-reference/[target-engine]/` for API snapshots.
- If missing: note "No engine reference found for [target] — API mapping uses built-in knowledge. Verify mappings against official docs before acting on this guide."

---

## Phase 2 — Engine API Inventory

Scan `src/` for engine-specific API patterns. Use the heuristics below for the detected source engine.

### Godot API patterns

| Category | Patterns to grep |
|----------|-----------------|
| Scene/node access | `get_node(`, `\$[A-Z]`, `find_child(`, `get_parent(`, `get_children(`, `add_child(`, `remove_child(`, `queue_free(` |
| Signals | `emit_signal(`, `\.connect(`, `\.disconnect(`, `signal `, `@signal` |
| Lifecycle hooks | `func _ready(`, `func _process(`, `func _physics_process(`, `func _input(`, `func _unhandled_input(`, `func _notification(` |
| Resources/assets | `preload(`, `load(`, `ResourceLoader`, `@export` |
| Physics | `move_and_slide(`, `move_and_collide(`, `PhysicsServer`, `Area2D`, `RigidBody`, `CharacterBody` |
| Rendering | `CanvasItem`, `draw_`, `Sprite2D`, `AnimationPlayer`, `AnimationTree`, `SubViewport`, `Viewport` |
| UI | `Control`, `Label`, `Button`, `Container`, `get_theme_`, `theme_override_` |
| Input | `Input\.`, `InputEvent`, `InputMap` |
| Autoloads | Grep `project.godot` for `[autoload]` section; each autoload name used in code = project coupling |
| Serialization | `to_json(`, `from_json(`, `var_to_bytes(`, `FileAccess`, `ConfigFile` |
| Networking | `MultiplayerAPI`, `ENetMultiplayerPeer`, `@rpc` |

### Unity API patterns

| Category | Patterns |
|----------|----------|
| Component access | `GetComponent<`, `FindObjectOfType<`, `FindObjectsOfType<`, `AddComponent<` |
| Lifecycle | `void Start(`, `void Awake(`, `void Update(`, `void FixedUpdate(`, `void LateUpdate(`, `void OnEnable(`, `void OnDisable(`, `void OnDestroy(` |
| Events | `UnityEvent`, `Action<`, `delegate `, `event ` |
| Physics | `Rigidbody`, `Collider`, `OnTriggerEnter`, `OnCollisionEnter`, `Physics\.` |
| Rendering | `Renderer`, `Material`, `Shader`, `Camera\.`, `RenderTexture` |
| UI | `Canvas`, `Image`, `Text`, `Button\.onClick`, `Slider`, `ScrollRect` |
| Assets | `Resources\.Load<`, `AssetDatabase\.`, `ScriptableObject` |
| Serialization | `[SerializeField]`, `JsonUtility`, `PlayerPrefs` |
| Coroutines | `StartCoroutine(`, `IEnumerator `, `yield return` |

### Unreal API patterns

| Category | Patterns |
|----------|----------|
| Object model | `UObject`, `AActor`, `UActorComponent`, `TSubclassOf<`, `TWeakObjectPtr<`, `TObjectPtr<` |
| Lifecycle | `BeginPlay(`, `Tick(`, `EndPlay(`, `PostInitializeComponents(` |
| Reflection | `UPROPERTY(`, `UFUNCTION(`, `UCLASS(`, `USTRUCT(`, `UENUM(` |
| Delegates | `DECLARE_DYNAMIC_MULTICAST_DELEGATE`, `DECLARE_DELEGATE`, `BindUFunction(`, `AddDynamic(` |
| Physics | `UPhysicsHandleComponent`, `FHitResult`, `GetWorld()->SweepSingleByChannel(` |
| Rendering | `UStaticMeshComponent`, `USkeletalMeshComponent`, `UMaterial`, `UNiagaraComponent` |
| UI | `UUserWidget`, `UWidgetComponent`, `BindWidget`, `TAttribute<` |
| Subsystems | `GetWorld()`, `GetGameInstance()`, `GetGameMode()`, `USubsystem` |

### Output per category

For each pattern with matches:
```
[Category]: N occurrences across M files
  Files: [list filenames]
```

Zero-match categories: omit from output.

---

## Phase 3 — ADR Crosswalk

Read all `docs/architecture/ADR-*.md` files.

For each ADR:
1. Check for `## Engine Compatibility` section.
2. If present: extract `Engine-specific:`, `Reason:`, `Porting note:` fields.
3. If absent: flag as **missing Engine Compatibility field**.

Count and report:
- ADRs with Engine Compatibility section: N
- ADRs flagged Engine-specific: Yes or Partial: N  
- ADRs missing Engine Compatibility field: N (these are **audit gaps** — manual review required before porting)

---

## Phase 4 — API Mapping

For each engine API found in Phase 2, classify using the mapping tables below.

### Effort classification

| Class | Definition |
|-------|-----------|
| **Direct** | Target engine has a named equivalent; essentially find-and-replace. Low effort. |
| **Adaptation** | Concept exists in target but requires structural change — different API shape, different lifecycle model, different ownership model. Medium effort. |
| **Rethink** | Source engine feature has no target equivalent; requires architectural redesign. High effort — design decisions required before coding. |

### Godot → Unity mapping

| Godot | Unity equivalent | Class |
|-------|-----------------|-------|
| `Node` hierarchy / scene tree | `GameObject` / prefab hierarchy | Adaptation — ownership model differs |
| `func _ready()` | `void Awake()` / `void Start()` | Direct |
| `func _process(delta)` | `void Update()` | Direct |
| `func _physics_process(delta)` | `void FixedUpdate()` | Direct |
| `signal` / `emit_signal` | `UnityEvent` / `Action` | Adaptation — declaration syntax differs |
| `@export` | `[SerializeField]` | Direct |
| `preload()` / `load()` | `Resources.Load<>()` / Addressables | Adaptation — asset reference model differs |
| `get_node()` / `$Node` | `GetComponent<>()` / `transform.Find()` | Adaptation — component vs node model |
| `Area2D` / physics bodies | `Collider` / `Rigidbody` | Adaptation — 2D physics layer differs |
| `AnimationPlayer` | `Animator` / `Animation` | Adaptation — animation state machine model differs |
| `SubViewport` | `RenderTexture` + Camera | Adaptation |
| `Control` nodes (UI) | `Canvas` / `RectTransform` | Adaptation — layout model differs |
| `FileAccess` | `File` / `PlayerPrefs` | Adaptation |
| `Autoloads` (singletons) | Static classes / `MonoBehaviour` singletons / `ScriptableObject` | Rethink — no native autoload; pattern choice required |
| `@rpc` networking | Mirror / Netcode for GameObjects | Rethink — no native equivalent |
| GDScript scripting | C# scripting | Rethink for complex patterns — language paradigm shift |

### Godot → Unreal mapping

| Godot | Unreal equivalent | Class |
|-------|-----------------|-------|
| `Node` / scene tree | `AActor` / `UActorComponent` hierarchy | Adaptation |
| `func _ready()` | `BeginPlay()` | Direct |
| `func _process(delta)` | `Tick(DeltaTime)` | Direct |
| `func _physics_process(delta)` | `Tick` with `bTickEvenWhenPaused` | Direct |
| `signal` / `emit_signal` | `DECLARE_DYNAMIC_MULTICAST_DELEGATE` | Adaptation — boilerplate-heavy |
| `@export` | `UPROPERTY(EditAnywhere)` | Adaptation — macro syntax |
| `preload()` / `load()` | `ConstructorHelpers::FObjectFinder` / Asset Manager | Adaptation |
| `get_node()` / `$Node` | `GetOwner()` / `FindComponentByClass<>()` | Adaptation |
| `Area2D` / physics | `UPrimitiveComponent` overlap events | Adaptation |
| `AnimationPlayer` | `UAnimMontage` / `UAnimationBlueprint` | Rethink — UE animation is Blueprint-first |
| `SubViewport` | `USceneCaptureComponent2D` | Adaptation |
| `Control` nodes (UI) | `UUserWidget` (UMG) | Rethink — UMG is Blueprint-first |
| `FileAccess` | `FFileHelper` / `UGameplayStatics::SaveGame` | Adaptation |
| `Autoloads` | `UGameInstance` subsystems / `USubsystem` | Adaptation |
| GDScript scripting | C++ + Blueprints | Rethink — full language change |

### Unity → Godot mapping

| Unity | Godot equivalent | Class |
|-------|-----------------|-------|
| `MonoBehaviour` lifecycle | `Node` lifecycle (`_ready`, `_process`) | Adaptation |
| `GetComponent<>()` | `get_node()` / typed child nodes | Adaptation |
| `UnityEvent` | `signal` | Adaptation — simpler in Godot |
| `[SerializeField]` | `@export` | Direct |
| `Resources.Load<>()` | `load()` / `preload()` | Direct |
| `Rigidbody` + `Collider` | `RigidBody2D/3D` + `CollisionShape` | Adaptation |
| `Animator` | `AnimationPlayer` / `AnimationTree` | Adaptation |
| `Canvas` UI | `Control` nodes | Adaptation |
| Static singletons | `Autoloads` | Adaptation — register in project settings |
| Coroutines | `await` / `Callable` | Adaptation |
| C# scripting | GDScript (or C# via .NET) | Direct if using Godot C# |

### Unreal → Godot / Unity mappings

Derive by reversing the Godot → Unreal table above (Rethink items remain Rethink; Direct remains Direct; Adaptation may change direction).

### For unsupported pairs

Use best-effort mapping based on concept equivalence. Mark all mappings as `[UNVERIFIED]` — the skill has no reference table for this pair.

---

## Phase 5 — Effort Estimate

### Per-file estimate

For each file in `src/`:
- Count Rethink-class API calls → each = 1.0–3.0 days (default: 2.0)
- Count Adaptation-class API calls → each = 0.25–1.0 days (default: 0.5)
- Count Direct-class API calls → each = 0.1 days

Clamp per-file estimate to reasonable bounds: min 0.1d, max 10d per file.

Sum to get total estimate range:
- Low end: use minimum per-class values
- High end: use maximum per-class values

### System-level grouping

Group files by their epic/system (from `production/backlog.yaml` epic field, or by directory). Sum estimate per system.

---

## Phase 6 — Write Guide

Ask: "May I write `docs/porting/[source]-to-[target]-[date].md`? [Y/N]"

On approval, create `docs/porting/` if it doesn't exist, then write:

```markdown
# Engine Porting Guide: [Source Engine vX.X] → [Target Engine vX.X]
Generated: [date]
Source: [engine name + version from technical-preferences.md]
Target: [engine name + version]
[WARNING: No engine reference found for [target] — verify API mappings against official docs]
[WARNING: [N] ADRs missing Engine Compatibility section — manual audit required]

## Summary

| Metric | Count |
|--------|-------|
| Source files scanned | N |
| Files requiring changes | N |
| Direct-equivalent APIs | N — low effort |
| Adaptation required | N — medium effort |
| No equivalent (rethink) | N — high effort |
| **Estimated total effort** | **[low]d – [high]d** |

Confidence: [LOW if > 20% of ADRs missing Engine Compatibility / MEDIUM otherwise]

---

## API Crosswalk

| Source API / Pattern | Target Equivalent | Class | Notes |
|---------------------|-------------------|-------|-------|
| [source pattern] | [target equivalent] | Direct/Adaptation/Rethink | [any caveat] |
...

---

## ADR Porting Notes

| ADR | Engine-Specific Decision | Porting Impact |
|-----|------------------------|----------------|
| [ADR-NNNN: title] | [Engine-specific reason from ADR] | [Porting note from ADR] |
...

### ADRs Missing Engine Compatibility Field
The following ADRs have no Engine Compatibility section. Manual audit required — porting impact unknown.
- ADR-NNNN: [title]
...
[Or: "All ADRs have Engine Compatibility fields — no gaps."]

---

## Files by Effort Category

### High Effort — Rethink Required ([N] files, ~[N]d)
These files use engine features with no direct equivalent in [target]. Architectural decisions required before coding.

| File | Rethink APIs | Est. Days |
|------|-------------|-----------|
| src/[path] | [list APIs] | [N]d |

### Medium Effort — Adaptation Required ([N] files, ~[N]d)
These files use engine APIs that have equivalents in [target] but require structural changes.

| File | Adaptation APIs | Est. Days |
|------|----------------|-----------|
| src/[path] | [list APIs] | [N]d |

### Low Effort — Direct Equivalent ([N] files, ~[N]d)
These files use engine APIs with direct named equivalents in [target]. Largely find-and-replace.

| File | Direct APIs | Est. Days |
|------|------------|-----------|
| src/[path] | [list APIs] | [N]d |

### No Engine APIs ([N] files)
Pure logic — no porting changes required.

---

## Effort by System

| System/Epic | Files | Rethink | Adaptation | Direct | Est. Days |
|-------------|-------|---------|-----------|--------|-----------|
| [system name] | N | N | N | N | [N]d |
...
| **Total** | N | N | N | N | **[low]d–[high]d** |

---

## Known Risks

1. **ADR audit gaps** — [N] ADRs missing Engine Compatibility section. These may contain engine-specific decisions not captured above.
2. **[Any Rethink API with no known target equivalent]** — requires design decision before porting work begins.
3. **No target engine reference** — [if applicable] mappings not verified against versioned docs.
[Add any other risks from ADR porting notes]
```

---

## Graceful Degradation

| Missing input | Behavior |
|---------------|----------|
| No ADRs | Skip ADR crosswalk; note "No ADRs — porting guide is code-only. Consider running /architecture-review first." |
| ADRs missing Engine Compatibility | Proceed; note count of gaps in header |
| No target engine reference | Use built-in knowledge; note unverified status |
| No `src/` directory | Stop — "No source files found. Check working directory." |
| Unsupported engine pair | Proceed with best-effort; mark all as [UNVERIFIED] |

---

## Recommended Next Steps

Verdict: COMPLETE — porting guide written.

- Review the Rethink-class APIs first — these require design decisions before any coding begins
- Run `/refresh-docs update [target-engine] scripting --web` to get versioned target API docs
- Run `/architecture-decision` for each Rethink-class system to document the new architecture contract
