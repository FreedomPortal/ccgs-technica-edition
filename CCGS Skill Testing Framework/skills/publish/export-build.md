# Skill Spec: /export-build

> **Category**: utility
> **Priority**: low
> **Spec written**: 2026-05-26

## Skill Summary

`/export-build` exports a release build of the game using the configured engine's headless CLI export. It accepts an optional `[platform]` argument (windows, linux, mac, web). It verifies export presets exist, detects the engine binary via PATH or environment variable, resolves the game version from project manifest or git tags, selects the target platform (asking if not provided), spawns an engine-specialist subagent via Task to pre-verify export configuration, then shows the exact export command for user approval before running it. Output is verified for existence and non-zero size. Results are logged to `production/qa/builds.md` with a separate approval gate. Ends with a structured summary block reporting PASS or FAIL with next steps.

---

## Static Assertions

- [ ] Frontmatter has all required fields (`name`, `description`, `argument-hint`, `user-invocable`, `allowed-tools`)
- [ ] 2+ phase headings found
- [ ] At least one verdict keyword present (`PASS`, `FAIL`, `CONCERNS`, `APPROVED`, `BLOCKED`, `COMPLETE`, `READY`)
- [ ] If `allowed-tools` includes Write/Edit: `"May I write"` language present
- [ ] Next-step handoff section present at end

---

## Director Gate Checks

- **Engine-specialist subagent gate (Phase 5)**: An engine-specialist agent is spawned via Task before the export runs. If it returns BLOCKED, the skill halts and surfaces the reason. This is a hard blocking gate — the export command is never run while the subagent is BLOCKED.

---

## Test Cases

### Case 1: Happy Path — Windows Export With Argument
**Fixture**:
- Invoked as `/export-build windows`
- `export_presets.cfg` exists in project root with a "Windows Desktop" preset
- Engine binary is on PATH (`godot --version` succeeds)
- `project.godot` contains version metadata: `1.0.0`
- Engine-specialist subagent returns READY
- User confirms export in Phase 6
- User approves build log write in Phase 8

**Expected behavior**:
1. Parses argument — platform is `windows`
2. Reads `export_presets.cfg` — preset found
3. Detects binary via PATH
4. Reads version from `project.godot` — stores `1.0.0`
5. Skips Phase 3 (platform argument provided)
6. Resolves preset name and output extension `.exe`
7. Spawns engine-specialist subagent — returns READY
8. Shows exact command: `godot --headless --export-release "Windows Desktop" "builds/1.0.0/windows/[GAME_NAME].exe"`
9. User confirms — directory created, export runs
10. Checks `builds/` is in `.gitignore` — surfaces note if not
11. Verifies output file exists and non-zero — reports PASS
12. Asks "May I log this build to `production/qa/builds.md`?" — user approves
13. Appends row to builds.md
14. Outputs summary with PASS and next steps

**Assertions**:
- [ ] Export command is shown to user before running
- [ ] Engine-specialist subagent is spawned before export
- [ ] Output file verified for existence and non-zero size
- [ ] Build log entry appended to `production/qa/builds.md`
- [ ] Summary contains PASS and next steps
- [ ] `.gitignore` check is performed

**Case Verdict**: PASS

---

### Case 2: Failure — No Export Presets File
**Fixture**:
- `export_presets.cfg` does not exist in project root
- All other conditions normal

**Expected behavior**:
1. Phase 2 reads `export_presets.cfg` — absent
2. Emits prescribed error with four-step remediation instructions
3. Stops — no binary detection, no export, no file written

**Assertions**:
- [ ] Error message includes steps to configure presets in the engine editor
- [ ] Skill halts at Phase 2
- [ ] No export command is run

**Case Verdict**: PASS

---

### Case 3: Failure — Engine Binary Not Found
**Fixture**:
- `export_presets.cfg` exists
- `godot --version` fails (not on PATH)
- `$GODOT_BIN` environment variable not set
- No engine binary at common install paths

**Expected behavior**:
1. Phase 2 detects preset file — OK
2. All three binary detection steps fail
3. Emits prescribed error with Option A (PATH) and Option B ($[ENGINE]_BIN) remediation
4. Stops — no export attempted

**Assertions**:
- [ ] Error message includes Option A and Option B remediation paths
- [ ] Skill halts at Phase 2 binary detection step
- [ ] No export command is constructed or shown

**Case Verdict**: PASS

---

### Case 4: Edge Case — Engine-Specialist Returns BLOCKED
**Fixture**:
- Export presets file exists
- Engine binary found
- Version detected
- Engine-specialist subagent returns BLOCKED with reason: "Export template for Windows not installed"

**Expected behavior**:
1. Phases 1–4 complete successfully
2. Phase 5 spawns engine-specialist — returns BLOCKED
3. Skill surfaces the BLOCKED reason to user
4. Stops — no export command is shown or run
5. User receives actionable error message from specialist

**Assertions**:
- [ ] Skill halts when specialist returns BLOCKED
- [ ] BLOCKED reason is surfaced to user
- [ ] Export command is never shown
- [ ] No directory is created, no build is run

**Case Verdict**: PASS

---

### Case 5: Protocol — Two Approval Gates (Export + Build Log)
**Fixture**:
- All phases complete up to Phase 6
- Export runs successfully — output file exists
- Skill is at Phase 8 log step

**Expected behavior**:
1. Phase 6: "Ready to run the export. Proceed?" shown with exact command — first approval gate
2. Export runs only after user confirms
3. Phase 8: "May I log this build to `production/qa/builds.md`?" — second approval gate
4. Build log is written only after user approves Phase 8
5. `.gitignore` note is surfaced but `.gitignore` is never auto-edited

**Assertions**:
- [ ] Uses "May I write" before file writes (Phase 8)
- [ ] Export command shown before running (Phase 6)
- [ ] No auto-write of builds.md
- [ ] `.gitignore` is never auto-modified

**Case Verdict**: PASS

---

## Protocol Compliance

- [ ] Uses `"May I write"` before any file writes (or is read-only and skips this)
- [ ] Presents findings/draft to user before requesting approval
- [ ] Ends with a recommended next step or follow-up action
- [ ] Does not auto-create files without user approval

---

## Coverage Notes

- Engine binary detection steps (a/b/c) and common install path scanning are runtime behaviors — static spec cannot enumerate all common paths.
- Web export note ("requires a web server to run — cannot be opened directly from filesystem") is a runtime-only inclusion in the Phase 9 summary.
- Version detection fallback chain (project manifest → git tag → git short hash → date) is runtime logic; static spec only asserts the fallback chain exists.
- Builds made on Windows (the project environment) may have platform-specific binary path conventions that differ from the generic `[ENGINE_BIN]` placeholder in the SKILL.md.
- The `[ENGINE]` placeholder throughout the skill is intentionally engine-agnostic — runtime test must supply a concrete engine configuration to exercise this skill fully.
