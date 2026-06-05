# Skill Spec: /demo-build

> **Category**: utility
> **Priority**: low
> **Spec written**: 2026-05-26

## Skill Summary

`/demo-build` exports and validates a Godot demo build with demo-specific quality gates. It checks prerequisites (demo-scope.md, export_presets.cfg, Godot binary), prompts platform selection, runs a `godot-specialist` content gate audit to verify that excluded content is code-gated, checks save isolation against the scope's save handling requirement, displays the exact export command for approval, runs the headless Godot export, and verifies the output file exists and is non-empty. Build results are logged to `production/qa/demo-builds.md` after explicit approval. The skill accepts an optional platform argument (`windows|linux|mac|web`) and an optional `--review full|lean|solo` flag. Output: binary at `builds/demo/[VERSION]/[PLATFORM]/[GAME_NAME]_demo.[EXT]`.

---

## Static Assertions

- [ ] Frontmatter has all required fields (`name`, `description`, `argument-hint`, `user-invocable`, `allowed-tools`)
- [ ] 2+ phase headings found
- [ ] At least one verdict keyword present (`PASS`, `FAIL`, `COMPLETE`)
- [ ] If `allowed-tools` includes Write/Edit: `"May I write"` language present
- [ ] Next-step handoff section present at end

---

## Director Gate Checks

- **N/A**: `/demo-build` does not invoke any director phase gate. The content gate audit is a technical check run by a `godot-specialist` subagent, not a director gate. No gate IDs are defined.

---

## Test Cases

### Case 1: Happy Path — Clean export with all content gated
**Fixture**:
- `design/demo/demo-scope.md` exists with "Excluded / Locked Content" section
- `export_presets.cfg` exists with a "Windows Desktop" preset
- Godot binary available on PATH
- `project.godot` has `config/version = "0.3.0"`
- `src/` contains `is_demo = true` flag guarding all excluded content
- Save handling: Isolated (demo saves to `user://demo_save.dat`)

**Expected behavior**:
1. Phase 1 prerequisites pass; binary detected; version resolved as "0.3.0"
2. Phase 2 platform resolved as Windows from preset list
3. Phase 3 godot-specialist audit returns all excluded items as GATED
4. Phase 4 save isolation check confirms demo save path differs from full-game path
5. Phase 5 shows exact command; user approves export
6. Export runs; output file exists and is non-zero
7. Phase 6: PASS result reported
8. Phase 7 asks "May I log this demo build to `production/qa/demo-builds.md`?"

**Assertions**:
- [ ] Exact export command shown before running
- [ ] Content gate audit result (X gated / Y ungated / Z unknown) displayed
- [ ] Save isolation status displayed
- [ ] Build result is PASS
- [ ] "May I log" asked before writing to demo-builds.md
- [ ] Summary includes output path, platform, result, content gate status, save isolation
- [ ] Next steps reference `/demo-playtest` and `/demo-feedback`
**Case Verdict**: PASS

---

### Case 2: Failure — demo-scope.md not found
**Fixture**:
- `design/demo/demo-scope.md` does not exist
- `export_presets.cfg` exists

**Expected behavior**:
1. Phase 1 reads demo-scope.md — not found
2. Skill outputs: "`design/demo/demo-scope.md` not found. Run `/demo-scope` first to define what goes in the demo before exporting a build."
3. Skill stops; no export command run

**Assertions**:
- [ ] Error message explicitly references `/demo-scope`
- [ ] No Bash export command executed
- [ ] No `AskUserQuestion` for platform selection
- [ ] No file written
**Case Verdict**: PASS

---

### Case 3: Mode Variant — Platform argument passed directly
**Fixture**:
- All prerequisites present
- Skill invoked as `/demo-build linux`
- Linux preset exists in `export_presets.cfg`

**Expected behavior**:
1. Phase 0 resolves review mode from `production/review-mode.txt` or defaults to lean
2. Phase 2 uses the passed `linux` argument; no `AskUserQuestion` for platform
3. Output path uses `.x86_64` extension
4. Phases 3–8 proceed normally

**Assertions**:
- [ ] No platform selection question asked when argument is passed
- [ ] Output extension is `.x86_64` for linux
- [ ] Output path follows `builds/demo/[VERSION]/linux/[GAME_NAME]_demo.x86_64` pattern
**Case Verdict**: PASS

---

### Case 4: Edge Case — Ungated content detected; user chooses to continue
**Fixture**:
- `design/demo/demo-scope.md` has "Chapter 2" and "Multiplayer Mode" as excluded
- `src/` has no demo flag guarding "Multiplayer Mode" (ungated)
- "Chapter 2" is gated

**Expected behavior**:
1. Phase 3 godot-specialist audit returns: 1 GATED (Chapter 2), 1 UNGATED (Multiplayer Mode)
2. Skill surfaces warning: "Demo content gate audit found ungated content: Multiplayer Mode"
3. `AskUserQuestion` with options: Continue anyway / Stop
4. User chooses "Continue anyway — I'll fix content gates after this build (test build only)"
5. Ungated items noted as known risks; export proceeds
6. Phase 8 summary includes warning emoji and list of ungated items

**Assertions**:
- [ ] Warning message lists specific ungated items
- [ ] `AskUserQuestion` presented before proceeding past gate failure
- [ ] If continue: ungated items listed as known risks in summary
- [ ] Build proceeds and can still PASS despite ungated content
**Case Verdict**: PASS

---

### Case 5: Protocol — Approval gate before export command runs
**Fixture**:
- All prerequisites present; all gates clear
- Review mode: lean

**Expected behavior**:
1. Phases 1–4 complete cleanly
2. Phase 5 displays the exact Godot headless command
3. Displays content gate status and save isolation status
4. `AskUserQuestion`: "Ready to export the demo build?" with Yes/No options
5. No export runs until user selects Yes
6. Phase 7 asks "May I log this demo build to `production/qa/demo-builds.md`?" — separate approval
7. `.gitignore` note emitted if `builds/` not listed (without auto-editing)

**Assertions**:
- [ ] Exact export command shown before running (not after)
- [ ] Export does not run without explicit Yes from user
- [ ] Build log write uses "May I log" language (not auto-write)
- [ ] `.gitignore` is never auto-edited
**Case Verdict**: PASS

---

## Protocol Compliance

- [ ] Uses `"May I write"` (or "May I log") before any file writes (or is read-only and skips this)
- [ ] Presents findings/draft to user before requesting approval
- [ ] Ends with a recommended next step or follow-up action
- [ ] Does not auto-create files without user approval

---

## Coverage Notes

- Godot binary detection (PATH / `$GODOT` env / Steam paths) is runtime-only; static specs can only verify the detection logic is documented.
- Web export note ("requires a web server") is runtime output only.
- The `.gitignore` check is advisory and non-blocking; auto-edit prevention is runtime behavior.
- Version detection priority order (project.godot → git tag → git SHA → date) is runtime-only.
