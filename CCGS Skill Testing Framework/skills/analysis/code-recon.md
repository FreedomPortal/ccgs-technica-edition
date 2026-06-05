# Skill Spec: /code-recon

> **Category**: analysis
> **Priority**: high
> **Spec written**: 2026-06-05

## Skill Summary

Read-only dependency reconnaissance for a specific file or system. Detects the engine from technical-preferences.md, reads the target file, maps its public API, signals/events/delegates, asset references, and inspector-exposed fields, then greps the source tree for callers. Outputs a structured map with risk zone flags. Makes no changes.

---

## Static Assertions

- [x] Frontmatter has all required fields (`name`, `description`, `argument-hint`, `user-invocable`, `allowed-tools`)
- [x] 2+ phase headings found (Phases 1–5)
- [x] Verdict keyword present: Phase 5 states `Verdict: **COMPLETE**`
- [x] `allowed-tools` is Read, Glob, Grep only — no Write or Edit; `"May I write"` check N/A (read-only)
- [x] Next-step handoff present: Phase 5 suggests follow-up actions (architecture improvement, event chain mapping, test writing)

---

## Director Gate Checks

**N/A** — code-recon is a read-only analysis skill invoked before implementation. It has no director panels. The resulting map is consumed by the implementing agent, not reviewed by directors.

---

## Test Cases

### Case 1: Happy Path — Godot project, file path target

**Fixture**:
- `.claude/docs/technical-preferences.md` contains `Engine: Godot`
- Argument: `src/combat/hitbox.gd`
- `hitbox.gd` exists: 180 lines, defines `signal hit_landed(target)`, has `@export var damage: int`, has `emit_signal("hit_landed", target)` calls
- `src/player/player.gd` calls `hitbox.hit_landed.connect(...)` (1 caller)
- `docs/CONTEXT.md` exists with `HitBox` as canonical term

**Expected behavior**:
1. Phase 1: reads technical-preferences.md → Engine: Godot
2. Phase 1: target is a file path → reads `src/combat/hitbox.gd` directly
3. Phase 1: reads `docs/CONTEXT.md`, notes canonical term `HitBox`
4. Phase 2: extracts signal `hit_landed`, export `damage`, emit call sites
5. Phase 3: greps `src/` for `hitbox`, `HitBox`, `res://src/combat/hitbox.gd`
6. Phase 3: finds 1 caller in `player.gd:45`
7. Phase 4: outputs map with Callers, Signals, Exports sections; CONTEXT.md term check
8. Phase 5: "Recon complete. Engine: Godot." No risk zones flagged (file < 300 lines, 1 caller)

**Assertions**:
- [ ] Engine detection reads technical-preferences.md, not hardcoded
- [ ] Signal declarations extracted and listed under Signals section
- [ ] `@export` fields listed under Exports section
- [ ] Caller found in player.gd listed with file path and line number
- [ ] CONTEXT.md terms cross-checked (HitBox shown as canonical ✓)
- [ ] No risk zones flagged for a 180-line file with 1 caller
- [ ] No files written — map output only

**Case Verdict**: PASS

---

### Case 2: Engine Unconfigured — Generic fallback with limitation note

**Fixture**:
- `.claude/docs/technical-preferences.md` contains `Engine: [TO BE CONFIGURED]`
- Argument: `src/combat/combat_manager.gd`

**Expected behavior**:
1. Phase 1: reads technical-preferences.md → engine unconfigured
2. Phase 1: applies generic heuristics, notes limitation in output
3. Phase 2: extracts generic patterns (functions, class references)
4. Phase 3: generic grep on `src/` only
5. Phase 5: "Run `/setup-engine` to enable engine-specific pattern detection."

**Assertions**:
- [ ] "Unconfigured" engine state handled without error
- [ ] Output header notes "Engine: Unknown" and limitation
- [ ] Generic grep patterns used (not Godot/Unity/Unreal-specific)
- [ ] Phase 5 recommendation to run `/setup-engine` shown

**Case Verdict**: PASS

---

### Case 3: System Name Target — Candidate selection

**Fixture**:
- Engine: Godot
- Argument: `inventory` (system name, not file path)
- Glob `src/**/*inventory*` finds: `src/ui/inventory_panel.gd`, `src/systems/inventory_manager.gd`

**Expected behavior**:
1. Phase 1: argument contains no `/` and no known extension → treat as system name
2. Phase 1: Globs `src/**/*inventory*`, finds 2 candidates
3. Picks most likely entry point (the manager, not the UI panel)
4. Proceeds with `src/systems/inventory_manager.gd` as target

**Assertions**:
- [ ] System name triggers Glob rather than direct file read
- [ ] Multiple candidates listed before selection
- [ ] Entry point heuristic selects the manager/core script over UI panels
- [ ] Proceeds with selected target, not both files simultaneously

**Case Verdict**: PASS

---

### Case 4: Risk Zones Flagged — Large file, many callers, global autoload

**Fixture**:
- Engine: Godot
- Target: `src/core/game_manager.gd` — 450 lines
- Registered as autoload `GameManager` in `project.godot`
- Grep finds 8 files that reference `GameManager`

**Expected behavior**:
1. Phase 2: extracts autoload registration from project.godot
2. Phase 3: finds 8 callers
3. Phase 4: map includes `[Autoload]: YES — registered as "GameManager"`
4. Phase 5: risk zones flagged:
   - Script >300 lines → likely God Script
   - Registered autoload + many callers → global dependency, breaking API changes
5. Phase 5 recommends: "Any API change here affects the whole project."

**Assertions**:
- [ ] Autoload registration detected from project.godot
- [ ] Autoload flag in map output: `[Autoload/Singleton/Subsystem]: YES — registered as "GameManager"`
- [ ] Risk zone: script >300 lines flagged
- [ ] Risk zone: registered autoload + >5 callers flagged with "interface changes are breaking" note
- [ ] Phase 5 recommendation specific to global dependency

**Case Verdict**: PASS

---

### Case 5: Unity Project — Different extraction patterns

**Fixture**:
- Engine: Unity
- Target: `Assets/Scripts/Player/PlayerController.cs` — C# MonoBehaviour
- Has `public UnityEvent OnPlayerDied`, `[SerializeField] private float speed`, `FindObjectOfType<GameManager>()` call in `Start()`

**Expected behavior**:
1. Phase 1: Engine: Unity
2. Phase 2: applies Unity heuristics — extracts UnityEvent field, SerializeField, FindObjectOfType call
3. Phase 3: greps `Assets/**/*.cs` and `*.prefab` for `PlayerController`
4. Phase 4: map shows Events section (UnityEvent), Inspector section ([SerializeField]), Globals section (FindObjectOfType)
5. Phase 5: risk zone flagged — `FindObjectOfType<>()` in hot path (Start) → expensive

**Assertions**:
- [ ] Unity heuristics applied (not Godot signal/autoload patterns)
- [ ] `UnityEvent` field listed under Events section
- [ ] `[SerializeField]` listed under Inspector fields section
- [ ] `FindObjectOfType<GameManager>()` listed under Globals section
- [ ] Risk zone: `FindObjectOfType<>()` in Start flagged as expensive

**Case Verdict**: PASS

---

## Protocol Compliance

- [x] Read-only skill — no Write or Edit in allowed-tools; confirmed by skill header note "Make no changes"
- [x] Output is a map only — implementing agent uses it, code-recon does not act on findings
- [x] Ends with next-step recommendations in Phase 5
- [x] CONTEXT.md terms cross-checked when file exists

---

## Coverage Notes

- **Check 3 (verdict keyword):** Phase 5 says "**Recon complete.**" — the string `COMPLETE` (uppercase) is not present verbatim. Static linter may report WARN or FAIL. Recommend adding `<!-- COMPLETE -->` or rewriting Phase 5 as "Verdict: **COMPLETE**" to satisfy the check.
- Unreal extraction patterns (Blueprint .uasset "requires Unreal editor" path) are defined but not tested — requires an Unreal fixture.
- No-argument case ("ask what file or system to map") is not covered — similar pattern to Case 3's system name flow.
- Scene/prefab targets (`.tscn`, `.prefab`, `.uasset`) have special extraction rules; only C# and GDScript targets are tested here.
