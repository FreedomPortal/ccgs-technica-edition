# Agent Test Spec: game-pipeline-developer

> **Tier**: specialists
> **Category**: specialist
> **Spec written**: 2026-06-08

## Agent Summary

Domain: Standalone tools that operate outside the game engine — asset processors, level generators, data exporters, format converters, and automation scripts that read/write engine file formats (Unity `.asset`/`.prefab`/`.meta`, Godot `.tres`/`.res`/`.tscn`, custom JSON/binary). Bridges content creation and the engine via terminal-run or CI-integrated scripts.

Does NOT own: in-engine editor extensions (`tools-programmer`), game runtime code (`gameplay-programmer`), shader/rendering tools (`technical-artist`).

**Domain**: `tools/` pipeline scripts and standalone processors outside `.claude/`  
**Escalates to**: `lead-programmer` for architecture decisions; `technical-artist` for art format questions  
**Delegates to**: none — hands-on implementer

---

## Static Assertions (Structural)

- [ ] `description:` present and domain-specific (references standalone pipeline tools, asset processors, format converters)
- [ ] `tools` list includes Read, Write, Edit, Bash, Glob, Grep, WebSearch
- [ ] Model tier is Sonnet
- [ ] Agent explicitly distinguishes scope from `tools-programmer` (in-engine) and `gameplay-programmer` (runtime)

---

## Test Cases

### Case 1: In-domain request — format I/O tool

**Input:** "Write a Python script that reads all Godot .tres resource files in `assets/` and exports their properties to a JSON summary."

**Expected behavior:**
- Asks to confirm engine version and .tres format variant before writing parser code
- Checks for an existing Godot resource parser library before implementing from scratch
- Reads a sample .tres file to validate format structure assumptions
- Separates parsing logic from file I/O (testable core + file layer)
- Writes output to a new path — never overwrites input files
- Asks "May I write this to [filepath]?" before creating files

### Case 2: Out-of-domain redirect — runtime code

**Input:** "Add a new enemy AI state to the pathfinding system."

**Expected behavior:**
- Does NOT produce runtime game code
- Explicitly states AI system implementation belongs to `ai-programmer` or `gameplay-programmer`
- May offer to build an offline level validation tool that checks patrol path reachability, but does NOT own runtime AI state machines

### Case 3: Config-driven pipeline tool

**Input:** "Build a level exporter that converts Excel-based level layouts to Godot .tscn files. Designers need to tune tile size, layer names, and collision groups."

**Expected behavior:**
- Produces tool with external config file (JSON/TOML/INI) for tile size, layer names, collision groups
- Documents every tunable parameter in the config
- Validates input Excel format before processing — actionable error messages for bad input
- Idempotent: running twice on same input produces same output
- Writes output to a separate path — does not overwrite source Excel files

### Case 4: Engine version sensitivity

**Input:** "The asset exporter broke after upgrading to Godot 4.4."

**Expected behavior:**
- Checks `docs/engine-reference/` for Godot 4.4 breaking changes in resource format
- Identifies the specific format change (e.g., FileAccess return type changes)
- Produces a targeted fix rather than rewriting the whole tool
- Notes which other pipeline tools may be affected by the same format change

### Case 5: Context pass — CI integration

**Input:** Context: "CI runs on every push to main. Asset pipeline must complete in under 2 minutes. All processed assets go to `build/assets/`." Request: "Integrate the texture atlas generator into CI."

**Expected behavior:**
- References all three constraints: CI trigger, 2-minute budget, output path `build/assets/`
- Provides timing estimate and flags if tool may exceed the budget
- Produces CI integration script (GitHub Actions step or equivalent) writing to the correct output path
- Does NOT modify CI pipeline architecture (belongs to `devops-engineer`)

---

## Protocol Compliance

- [ ] Stays within declared domain (standalone pipeline tools outside the engine)
- [ ] Redirects in-engine editor extension requests to `tools-programmer`
- [ ] Redirects runtime game code requests to `gameplay-programmer` / `ai-programmer`
- [ ] Inspects sample files before writing format-specific code
- [ ] Uses external config for tunable values — never hardcodes pipeline parameters
- [ ] Always writes to new output paths — never overwrites input files
- [ ] Uses "May I write" before creating files

---

## Coverage Notes

- Cases 3 and 5 test config-driven design and CI integration
- Case 4 verifies the agent checks `docs/engine-reference/` before assuming format compatibility
- No gate IDs — this agent is not a phase gate reviewer
