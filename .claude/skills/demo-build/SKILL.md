---
name: demo-build
description: "Export and validate a demo build with demo-specific gates: content boundary enforcement, save isolation, end-state screen, and build verification. Requires /demo-scope to have been run first."
argument-hint: "[windows|linux|mac|web] (optional: --review full|lean|solo)"
user-invocable: true
allowed-tools: Read, Glob, Grep, Bash, Write, Edit, Task, AskUserQuestion
---

## Phase 0: Resolve Review Mode

1. If `--review [mode]` was passed → use that
2. Else read `production/review-mode.txt` → use that value
3. Else → default to `lean`

---

## Phase 1: Prerequisites Check

**Check demo scope doc:**

Read `design/demo/demo-scope.md`. If it does not exist:
> "`design/demo/demo-scope.md` not found. Run `/demo-scope` first to define what
> goes in the demo before exporting a build."
Stop.

**Check export presets:**

Read `export_presets.cfg`. If it does not exist:
> "No `export_presets.cfg` found. Export presets must be configured in the Godot
> editor before a headless build can run (Project → Export → Add preset)."
Stop.

**Detect Early Access mode:**

Read `design/demo/demo-plan.md` (or `production/demo/*/demo-plan.md` if demo-id is known).
Check for `--early-access` in arguments OR `Early Access: true` in the plan header.
Store as `EA_MODE = true/false`. Used in Phase 1b below.

**Detect Godot binary** — check in this order:

a) `godot --version` — succeeds if `godot` is on PATH
b) `test -x "$GODOT" && "$GODOT" --version` — if `$GODOT` env var is set
c) Common Steam paths on Windows:
   - `"/c/Program Files (x86)/Steam/steamapps/common/Godot Engine/godot.windows.editor.x86_64.exe" --version`
   - `"/c/Program Files/Steam/steamapps/common/Godot Engine/godot.windows.editor.x86_64.exe" --version`

If all fail:
> "Godot binary not found. Set `$GODOT` to the executable path, or add Godot to
> your system PATH, then re-run `/demo-build`."
Stop.

Store binary as `[GODOT_BIN]`.

**Detect game version:**

1. Read `project.godot` for `config/version=` under `[application]`
2. Else `git describe --tags --abbrev=0`
3. Else `git rev-parse --short HEAD`
4. Else use current date as `YYYY-MM-DD`

Store as `[VERSION]`.

---

## Phase 1b: Early Access Publishing Checklist *(EA mode only — skip if EA_MODE = false)*

Before exporting an EA build, verify publishing requirements are in place. An EA build that ships
without these is a missed opportunity that cannot be undone after players buy in.

Check each item using `Glob` and `Read`. For items that can't be auto-verified, use `AskUserQuestion`.

**Required before EA build ships publicly:**
- [ ] EA store page is live (not just drafted) — check `production/publishing/store-page*` or ask
- [ ] EA pricing is set and published on the target store — ask user to confirm
- [ ] EA roadmap has been communicated to players (store page, community post, or in-game) — ask
- [ ] EA roadmap commitments are documented at `production/demo/[id]/ea-roadmap.md` — Glob check
- [ ] Known issues list is ready to publish — ask if user has prepared one
- [ ] Player feedback channel is active (Discord, Steam forums, etc.) — ask

**Advisory (CONCERNS if missing — not blocking for this build):**
- [ ] `/publish-check` has been run and EA requirements satisfied
- [ ] Press kit updated to reflect EA status

Present the checklist results:

```
## EA Publishing Checklist

Required:
- [x] Store page live
- [ ] EA pricing set — NOT CONFIRMED
- ...

Advisory:
- [ ] /publish-check run — not verified

EA Checklist: [PASS | CONCERNS | FAIL]
```

If **FAIL** (any Required item is missing):
Use `AskUserQuestion`:
- Prompt: "EA publishing checklist has unmet required items. Build will produce a valid binary but should not be distributed publicly until these are resolved. How do you want to proceed?"
- Options:
  - `[A] Continue — this is an internal EA build or I'll resolve these before publishing`
  - `[B] Stop — I'll complete the publishing checklist first`

If Stop: end here.
If Continue: log the unmet items as known risks in the build log (Phase 7).

---

## Phase 2: Platform Selection

If a platform argument was passed, use it. Otherwise read `export_presets.cfg`,
extract all `name=` values from `[preset.*]` blocks, and use `AskUserQuestion`:

- Prompt: "Which platform would you like to export the demo for?"
- Options: [one per detected preset, plus "Cancel"]

Resolve the exact preset `name=` value as `[PRESET_NAME]`.

Determine output extension:
| Platform contains | Extension |
|-------------------|-----------|
| `windows` / `Windows` | `.exe` |
| `linux` / `Linux` | `.x86_64` |
| `mac` / `Mac` / `macos` | `.app` |
| `web` / `Web` / `html` | `.html` |

Output path: `builds/demo/[VERSION]/[PLATFORM]/[GAME_NAME]_demo.[EXT]`

---

## Phase 3: Demo Content Gate Audit

Spawn `godot-specialist` via Task with this prompt:

```
Perform a demo content gate audit for a demo build.

Read:
- design/demo/demo-scope.md — the demo scope: what is included, what is locked
- src/ — scan for any content gate implementation (look for demo mode flags,
  feature flags, scene locks, or any variable/constant named "demo", "is_demo",
  "DEMO_MODE", or similar)
- export_presets.cfg — check whether a separate demo preset exists or if the
  full-game preset is being reused

Assess each item listed under "Excluded / Locked Content" in demo-scope.md:
For each locked item: is there evidence of a code-level lock in src/?

Report:
1. GATED items — code evidence found that this content is locked in demo mode
2. UNGATED items — no code lock found; content may be accessible in the demo build
3. UNKNOWN — content not yet implemented (not a gate failure, just note it)
4. Whether a dedicated demo export preset exists (recommended) or if the full-game
   preset is being reused (flag as a risk — easy to accidentally ship wrong content)

Do not run any commands or write any files. Research and report only.
```

Present the audit result. If UNGATED items exist:
> "Demo content gate audit found ungated content: [list]. These items are listed
> as excluded in the scope but have no code-level lock. The demo build may expose
> full-game content to players.
>
> Resolve before building: add demo-mode guards in code or remove the content
> from the demo export preset's include list."

Use `AskUserQuestion`:
- Prompt: "How do you want to proceed?"
- Options:
  - `Continue anyway — I'll fix content gates after this build (test build only)`
  - `Stop — I'll add the content gates first, then re-run /demo-build`

If Stop: end here. If Continue: note the ungated items as known risks in the build log.

---

## Phase 4: Save Isolation Check

Read `design/demo/demo-scope.md` for the "Save Data Handling" section.

If save handling is **Isolated** or **No save**:

Spawn `godot-specialist` via Task:

```
Check the save/load implementation for demo save isolation.

Read:
- src/ — look for save file path constants or save directory references
  (e.g., "user://save", "user://", FileAccess.open paths)
- design/demo/demo-scope.md — save data handling requirement

Report:
1. Where save files are written (the exact path or user:// location)
2. Whether demo saves would be written to the same location as full-game saves
3. Whether any demo-mode save prefix/suffix/directory exists

Do not run commands or write files. Report only.
```

If demo and full-game saves share a path, surface a warning:
> "Demo and full-game saves appear to share the same file path. A player who
> runs the demo after purchasing the full game may have their save overwritten
> or corrupted. Recommend adding a demo-specific save prefix (e.g.,
> `user://demo_save.dat`) before distributing this build."

Continue regardless — the user may accept this risk for an internal build.

---

## Phase 5: Confirm and Export

Show the user the exact command that will run:

```
[GODOT_BIN] --headless --export-release "[PRESET_NAME]" "builds/demo/[VERSION]/[PLATFORM]/[GAME_NAME]_demo.[EXT]"
```

Also display:
- Content gate status: [X gated / Y ungated / Z unknown]
- Save isolation: [confirmed / warning / not checked]
- Known risks: [list any ungated items if user chose Continue in Phase 3]

Use `AskUserQuestion`:
- Prompt: "Ready to export the demo build?"
- Options: `Yes, export now`, `No, cancel`

If cancelled: stop.

Create the output directory:
```bash
mkdir -p "builds/demo/[VERSION]/[PLATFORM]"
```

Check `.gitignore` — if `builds/` is not listed, surface a note (do not auto-edit):
> "Note: `builds/` is not in your `.gitignore`. Demo binaries should not be committed to git."

Run the export:
```bash
[GODOT_BIN] --headless --export-release "[PRESET_NAME]" "builds/demo/[VERSION]/[PLATFORM]/[GAME_NAME]_demo.[EXT]"
```

Capture stdout, stderr, and exit code.

---

## Phase 6: Verify Output

Check the output file exists and is non-zero in size:
```bash
test -s "builds/demo/[VERSION]/[PLATFORM]/[GAME_NAME]_demo.[EXT]"
```

If missing or empty: report FAILED with captured stderr.
If present and non-zero: report PASS.

---

## Phase 7: Log Result

Ask: "May I write this build entry to `production/qa/demo-builds.md`?"

If yes, create or append to `production/qa/demo-builds.md`:

```markdown
# Demo Build Log

| Date | Version | Platform | Result | Content Gates | Save Isolation | Output Path |
|------|---------|----------|--------|--------------|----------------|-------------|
```

Append one row per build.

---

## Phase 8: Summary

```
Demo Build — [GAME_NAME] v[VERSION]
=====================================
Platform:        [PLATFORM]
Output:          builds/demo/[VERSION]/[PLATFORM]/[GAME_NAME]_demo.[EXT]
Result:          PASS / FAIL
Content gates:   [X gated, Y ungated, Z unknown]
Save isolation:  [confirmed / warning / not checked]

[If PASS:]
Next steps:
1. Smoke-test the demo binary on a clean machine before distribution
2. Run /demo-playtest with this build to validate first impression and onboarding
3. After 2+ sessions: run /demo-feedback to synthesize patterns and get a go/no-go verdict
4. If blockers found: run /demo-iterate to resolve them, then rebuild
5. When feedback clears: run /demo-polish, then /demo-build for the final public build
6. For Steam Next Fest: submit via Steamworks → Demos section
[EA only:]
7. Run /demo-gate [id] publishing — validate EA store requirements before going live
8. After EA launch: run /demo-integrate --early-access — flags roadmap commitments as Required 1.0 stories

[If FAIL:]
Error output:
[captured stderr]

[If ungated content:]
⚠️ Known risk: [list ungated items] are not code-gated in this build.
Fix before distributing to the public.
```

---

## Collaborative Protocol

- Never export without showing the exact command and receiving approval (Phase 5 gate)
- Never write to `production/qa/demo-builds.md` without asking (Phase 7)
- Never edit `.gitignore` automatically
- Always surface ungated content warnings — never silently proceed past them
- For web exports: note that the output requires a web server (cannot be opened directly from filesystem)
