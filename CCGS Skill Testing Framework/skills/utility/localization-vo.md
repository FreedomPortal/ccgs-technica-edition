# Skill Spec: /localization-vo

> **Category**: utility
> **Priority**: low
> **Spec written**: 2026-05-26

## Skill Summary

`/localization-vo` manages the voice-over pipeline for localized games across four subcommands: `scan` (generates a per-character recording manifest by reading `vo.*` keys from the string table and checking audio file existence); `script [locale]` (generates per-character recording scripts with source text, translated text, expected filename, emotion tag, director notes, and pronunciation flags); `validate [locale]` (checks audio file existence, naming convention, and format for all VO keys); and `integrate [locale]` (searches `src/` for VO audio references, flagging hardcoded locale paths as HIGH severity and verifying key-to-file mappings). VO keys must follow the `vo.[character].[line_id]` pattern. The skill is largely read-only; only the `script` subcommand writes a file (after approval).

---

## Static Assertions

- [ ] Frontmatter has all required fields (`name`, `description`, `argument-hint`, `user-invocable`, `allowed-tools`)
- [ ] 2+ phase headings found
- [ ] At least one verdict keyword present (`PASS`, `FAIL`, `CONCERNS`, `APPROVED`, `BLOCKED`, `COMPLETE`, `READY`)
- [ ] If `allowed-tools` includes Write/Edit: `"May I write"` language present
- [ ] Next-step handoff section present at end

---

## Director Gate Checks

- **N/A**: `localization-vo` is a pipeline management skill for audio assets. It does not invoke creative-director, technical-director, or producer gate phases. Its READY/CONCERNS/NOT READY verdicts are operational status indicators for the audio and localization leads, not project phase gates.

---

## Test Cases

### Case 1: Happy Path — Scan Produces Character Manifest
**Fixture**:
- `assets/data/strings/strings-en.json` has 8 keys matching `vo.*`: `vo.player.intro_01`, `vo.player.intro_02`, `vo.rival_1.greeting_01`, etc.
- `assets/data/strings/strings-ja.json` exists
- `assets/audio/vo/en/player/` has 2 of the 2 expected player lines
- `assets/audio/vo/en/rival_1/` has 0 of the 1 expected rival line
- `assets/audio/vo/ja/player/` has 0 of the 2 expected player lines
- Subcommand: `scan`

**Expected behavior**:
1. Parses `scan` subcommand
2. Spawns `localization-specialist` to read string table and check audio file existence
3. Presents character manifest table per character, per locale (Recorded vs Missing counts)
4. Lists missing file paths for each character/locale combination
5. No files written (scan is read-only)

**Assertions**:
- [ ] Character manifest shows correct Recorded/Missing counts per locale
- [ ] Missing file paths listed with expected path format (`assets/audio/vo/[locale]/[character]/[key_underscored].ogg`)
- [ ] No "May I write" prompt fires (read-only subcommand)

**Case Verdict**: PASS

---

### Case 2: Failure — Validate Finds Missing and Misnaming Errors (NOT READY)
**Fixture**:
- `strings-en.json` has 5 VO keys for two characters
- `assets/audio/vo/fr/player/` exists but contains:
  - `vo_player_intro_01.ogg` — correct
  - `vo_player_intro_02.WAV` — wrong format (uppercase extension)
  - `Vo_Player_Victory_01.ogg` — naming error (uppercase letters)
- `assets/audio/vo/fr/rival_1/` — missing entirely (1 file expected)
- Subcommand: `validate fr`

**Expected behavior**:
1. Spawns `localization-specialist` for audio file validation
2. Reports: 5 total, 1 found/correct, 1 missing, 1 naming error, 1 format error, 1 missing (rival directory)
3. Lists all MISSING, NAMING ERROR, FORMAT ERROR items explicitly
4. Verdict: **NOT READY** (missing files present)

**Assertions**:
- [ ] `NOT READY` verdict in output
- [ ] Missing files listed with expected paths
- [ ] Naming error listed with actual vs expected filename
- [ ] Format error listed with actual vs expected extension
- [ ] No files written (validate is read-only)

**Case Verdict**: PASS

---

### Case 3: Mode Variant — Script Generation for Single Character
**Fixture**:
- `strings-en.json` has 3 `vo.player.*` keys and 2 `vo.rival_1.*` keys
- `strings-ja.json` has translations for all 5 keys
- `design/narrative/character-sheets.md` exists with player and rival notes
- User answers "player" when asked which character(s) to script
- Subcommand: `script ja`

**Expected behavior**:
1. Asks: "Which character(s) should this script cover? (all / [character name])" — user answers "player"
2. Spawns `localization-specialist` with locale `ja` and character filter `player`
3. Script output shows only the 3 player lines with Japanese text, expected filename, emotion, director notes, pronunciation flags
4. Presents script preview
5. Asks: "May I write this recording script to `production/localization/vo-scripts/ja/player-script-[date].md`?"
6. On approval, writes script file

**Assertions**:
- [ ] Character filter applied — only `player` lines in script (not rival lines)
- [ ] Japanese translated text shown for each line
- [ ] Expected filename shown in `key_underscored.ogg` format
- [ ] "May I write" fires before script file is written
- [ ] Script path follows `production/localization/vo-scripts/[locale]/[character]-script-[date].md` convention

**Case Verdict**: PASS

---

### Case 4: Edge Case — Scan with No VO Keys in String Table
**Fixture**:
- `strings-en.json` exists with 20 keys, none matching `vo.*` pattern
- Subcommand: `scan`

**Expected behavior**:
1. Spawns `localization-specialist` to scan for `vo.*` keys
2. Finds zero matching keys
3. Outputs: "No VO keys detected in string table. VO keys must follow pattern `vo.[character].[line_id]` to be tracked by this pipeline."
4. Stops cleanly

**Assertions**:
- [ ] Correct no-VO-keys message displayed with pattern example
- [ ] Skill terminates without error
- [ ] No files written

**Case Verdict**: PASS

---

### Case 5: Protocol — Integrate Subcommand Flags Hardcoded Paths (Read-Only, No Fix)
**Fixture**:
- `src/` contains GDScript with: `AudioServer.load("assets/audio/vo/en/player/vo_player_intro_01.ogg")`
- One reference uses a valid key-based lookup
- All key-based references exist in `strings-en.json`
- Subcommand: `integrate en`

**Expected behavior**:
1. Spawns `localization-specialist` to scan `src/` for VO audio references
2. Finds 1 hardcoded locale path (`/en/` embedded) — HIGH severity
3. Finds 1 key-based reference — key exists in string table — KEY_FOUND
4. Outputs integration check report with HIGH finding flagged
5. Verdict: **NOT READY** (hardcoded path present)
6. Skill does NOT auto-fix the hardcoded path — reports only

**Assertions**:
- [ ] HIGH severity finding listed with file:line and the hardcoded path
- [ ] "replace with dynamic locale resolver" recommendation present
- [ ] `NOT READY` verdict in output
- [ ] No source files modified (read-only)
- [ ] No "May I write" prompt for source file (integrate is read-only)

**Case Verdict**: PASS

---

## Protocol Compliance

- [ ] Uses `"May I write"` before any file writes (or is read-only and skips this)
- [ ] Presents findings/draft to user before requesting approval
- [ ] Ends with a recommended next step or follow-up action
- [ ] Does not auto-create files without user approval

---

## Coverage Notes

- The `scan` subcommand checks audio file existence by constructing expected paths from key names (dots replaced with underscores). If the key naming convention is inconsistent in the project, the manifest may show false MISSINGs — a runtime quality gap.
- The `validate` subcommand's format check looks at file extensions only (`.ogg` or `.wav`) and cannot verify audio content, bitrate, or sample rate — full audio QA requires listening in-engine.
- The `integrate` subcommand cannot verify whether a dynamic locale resolver is correctly implemented — it only flags the absence of one (hardcoded path). The correctness of the resolver logic is a runtime/code-review concern.
- No argument or unrecognized argument triggers the usage help block — this graceful fallback is specified but not separately cased here as it is a trivial output-only path.
