---
name: export-build
description: "Export a release build of the game using [ENGINE]'s headless export. Verifies export templates are configured, runs the export, checks the output file exists, and logs the result to production/qa/builds.md. This skill operates according to the standards defined in SKILL.md."
argument-hint: "[platform: windows | linux | mac | web]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Bash, Write, Edit, Task
---

When this skill is invoked:

## Phase 1: Parse Arguments

If an argument is provided (e.g., `/export-build windows`), record the target platform. If no argument is provided, proceed to Phase 3 to ask.

Supported values: `windows`, `linux`, `mac`, `web`

---

## Phase 2: Detect Project State

**Check export presets:**

Read the export configuration file (e.g., `export_presets.cfg`) in the project root. If it does not exist:

> "No export configuration found. Export presets must be configured in the [ENGINE] editor before a headless build can run.
>
> Steps to configure:
> 1. Open the project in the [ENGINE] editor
> 2. Go to Project → Export
> 3. Add a preset for your target platform and configure export templates
> 4. Save the configuration
>
> Run `/export-build` again after configuring presets."

Stop and do not proceed.

**Detect the [ENGINE] binary:**

Run the following detection steps in order, stopping at the first success:

a) `[ENGINE_CMD] --version` — succeeds if the engine binary is on PATH
b) `test -x "$[ENGINE]_BIN" && "$[ENGINE]_BIN" --version` — succeeds if the environment variable is set
c) Check common install paths on the host system.

If all steps fail:

> "[ENGINE] binary not found. To fix this, choose one of:
>
> **Option A — Add to PATH**: Add the executable directory to your system PATH.
> **Option B — Set $[ENGINE]_BIN**: Run `export [ENGINE]_BIN=\"/path/to/binary\"` in your terminal.
>
> Run `/export-build` again after resolving."

Stop and do not proceed.

Store the working binary path as `[ENGINE_BIN]`.

**Detect game version:**

1. Read the project manifest (e.g., `project.[ENGINE]`) — look for version metadata.
2. If not found: run `git describe --tags --abbrev=0` to get the latest tag.
3. If no tags: use `git rev-parse --short HEAD` as the version string.
4. If git is unavailable: use the current date as `YYYY-MM-DD`.

Store as `[VERSION]`.

---

## Phase 3: Platform Selection

If the user provided a valid platform argument in Phase 1, skip this phase.

Read the export configuration and extract available preset names.

Use `AskUserQuestion`:
- Prompt: "Which platform would you like to export?"
- Options: [one entry per detected preset, plus "Cancel"]

---

## Phase 4: Resolve Preset Name

Read the configuration and find the entry matching the selected platform. The CLI requires the preset name verbatim.

Store the resolved preset name as `[PRESET_NAME]`.

Determine the output filename extension based on the platform (e.g., `.exe` for Windows, `.app` for Mac).

Read the project manifest for the game name. Store as `[GAME_NAME]`.

Output path: `builds/[VERSION]/[PLATFORM]/[GAME_NAME].[EXT]`

---

## Phase 5: Pre-Export Verification

Spawn the **[ENGINE]-specialist** agent via Task with this prompt:

```
Review the [ENGINE] [ENGINE_VERSION] export configuration for a headless CLI build targeting [PRESET_NAME].

Read:
- Export configuration files — verify the preset exists and has a valid path.
- Necessary credentials or keystore references (flag if missing).

Report:
1. READY or BLOCKED with a specific reason.
2. Any missing export templates or plugins.
3. Any platform-specific warnings (signing, notarization, etc.).
```

If the agent returns BLOCKED: surface the reason to the user and stop.

---

## Phase 6: Confirm and Export

Show the user the exact command that will be run:

```bash
[ENGINE_BIN] --headless --export-release "[PRESET_NAME]" "builds/[VERSION]/[PLATFORM]/[GAME_NAME].[EXT]"
```

Use `AskUserQuestion`:
- Prompt: "Ready to run the export. Proceed?"
- Options: `Yes, export now`, `No, cancel`

Create the output directory and check for `.gitignore` status for the `builds/` folder.
```bash
mkdir -p "builds/[VERSION]/[PLATFORM]"
```

After creating the directory, check whether `builds/` is listed in `.gitignore`.
If it is NOT present in `.gitignore`:

> "Note: `builds/` is not in your `.gitignore`. Binary build artifacts
> should generally not be committed to git. Consider adding `builds/` to
> `.gitignore` before the next commit."

Do not auto-edit `.gitignore` — surface the note only.

Run the export:

```bash
[ENGINE_BIN] --headless --export-release "[PRESET_NAME]" "builds/[VERSION]/[PLATFORM]/[GAME_NAME].[EXT]"
```

Run the export and capture output.

---

## Phase 7: Verify Output

Check that the output file exists and is non-zero in size.

```bash
test -s "builds/[VERSION]/[PLATFORM]/[GAME_NAME].[EXT]"
```

If the file is missing or empty:
- Show the captured stdout/stderr from Phase 6
- Report: **FAILED** — output file not produced

If the file exists and is non-zero:
- Report: **PASS** — file confirmed at `builds/[VERSION]/[PLATFORM]/[GAME_NAME].[EXT]`

---

## Phase 8: Log Result

Ask: "May I log this build to `production/qa/builds.md`?"

Wait for confirmation before writing.

If `production/qa/builds.md` does not exist, create it with this header:

```markdown
# Build Log

| Date | Version | Platform | Preset | Result | Output Path |
|------|---------|----------|--------|--------|-------------|
```

Append one row:

```
| [DATE] | [VERSION] | [PLATFORM] | [PRESET_NAME] | PASS / FAIL | builds/[VERSION]/[PLATFORM]/[GAME_NAME].[EXT] |
```

---

## Phase 9: Summary

```
Export Build — [GAME_NAME] v[VERSION]
======================================
Platform:   [PLATFORM]
Preset:     [PRESET_NAME]
Output:     builds/[VERSION]/[PLATFORM]/[GAME_NAME].[EXT]
Result:     PASS / FAIL

[If PASS:]
Next steps:
1. Smoke-test the exported binary on a clean machine before distribution
2. If distributing via Steam: use `steamcmd` to upload the build
3. Run /release-checklist before publishing to players

[If FAIL:]
Error output:
[captured stderr]

Next steps:
1. Check that export templates are installed (Editor → Export → Manage Export Templates)
2. Verify the preset name matches exactly: "[PRESET_NAME]"
3. Set $[ENGINE] if the binary path changes between sessions
```

---

## Collaborative Protocol

- **Never run the export without showing the exact command and getting approval** — Phase 6 is a required gate
- **Never write to `production/qa/builds.md` without asking** — Phase 8 requires explicit approval
- **Never edit `.gitignore` automatically** — surface the note only, let the user decide
- If the [ENGINE]-specialist agent returns BLOCKED, always stop and surface the reason — do not attempt to workaround template or signing issues
- For web exports: note that the output requires a web server to run (cannot be opened directly from the filesystem) — include this in the Phase 9 summary when platform is `web`
*   Refer to **SKILL.md** for general procedural guidelines.