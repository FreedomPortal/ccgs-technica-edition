# Skill Spec: /localization-rtl

> **Category**: utility
> **Priority**: low
> **Spec written**: 2026-05-26

## Skill Summary

`/localization-rtl` validates game source code and assets for RTL (right-to-left) layout support before shipping Arabic (`ar`), Hebrew (`he`), Persian (`fa`), or Urdu (`ur`) locales. It runs five static checks via a `localization-specialist` subagent: (1) RTL layout flag presence on UI containers, (2) hardcoded positional layout assumptions (LTR anchors, absolute x-positions), (3) string assembly patterns that break in RTL grammar, (4) font support for Arabic/Hebrew Unicode ranges, and (5) directional asset coverage (arrows, chevrons, fill-direction logic). It produces a READY / CONCERNS / NOT READY verdict based on HIGH severity finding count and asks approval to write a report to `production/localization/rtl-check-[locale]-[date].md`. The skill is entirely read-only and never modifies source files.

---

## Static Assertions

- [ ] Frontmatter has all required fields (`name`, `description`, `argument-hint`, `user-invocable`, `allowed-tools`)
- [ ] 2+ phase headings found
- [ ] At least one verdict keyword present (`PASS`, `FAIL`, `CONCERNS`, `APPROVED`, `BLOCKED`, `COMPLETE`, `READY`)
- [ ] If `allowed-tools` includes Write/Edit: `"May I write"` language present
- [ ] Next-step handoff section present at end

---

## Director Gate Checks

- **N/A**: `localization-rtl` is a static analysis and reporting skill. It does not invoke creative-director, technical-director, or producer gate agents. Its READY/CONCERNS/NOT READY verdict is advisory output for the programmer responsible for RTL implementation; it is not a phase gate that blocks project progression in the CCGS pipeline directly.

---

## Test Cases

### Case 1: Happy Path — RTL Check Returns READY
**Fixture**:
- Godot 4 project; engine detected from `technical-preferences.md`
- `src/` contains Control nodes with `layout_direction = LAYOUT_DIRECTION_AUTO` (no hardcoded LTR)
- `assets/fonts/` includes `NotoSansArabic.ttf`
- No positional x-anchoring without locale guards
- No string concatenation for UI text; named placeholders used
- `assets/` has both `arrow_left.png` and `arrow_right.png`
- Argument: `ar`

**Expected behavior**:
1. Validates `ar` is a supported RTL locale
2. Spawns `localization-specialist` with all 5 checks
3. All 5 checks pass — 0 HIGH, 0 MEDIUM, 0 LOW findings
4. Verdict: **READY**
5. Displays READY message with manual in-engine walkthrough checklist
6. Asks: "May I write this RTL validation report to `production/localization/rtl-check-ar-[date].md`?"
7. On approval, writes report

**Assertions**:
- [ ] `READY` verdict in output
- [ ] All 5 checks listed as PASS in the summary table
- [ ] Manual in-engine walkthrough checklist included in next steps
- [ ] "May I write" fires before report is written

**Case Verdict**: PASS

---

### Case 2: Failure — Multiple HIGH Findings (NOT READY)
**Fixture**:
- Godot 4 project
- `src/` has Control nodes with `layout_direction = LAYOUT_DIRECTION_LTR` hardcoded (no locale guard)
- `assets/fonts/` contains only `Roboto.ttf` (Latin-only)
- `src/` has `position.x = 50` hardcoded with no RTL conditional
- Argument: `he`

**Expected behavior**:
1. Spawns `localization-specialist` for 5 checks
2. Check 1 (RTL Layout Flag): HIGH — `layout_direction` hardcoded to LTR
3. Check 2 (Positional Layout): HIGH — hardcoded x-position without guard
4. Check 4 (Font Support): HIGH — only Latin font found
5. Verdict: **NOT READY** (3 HIGH findings)
6. Next steps output recommended fix order: Font → RTL flag → Positional layout → String assembly → Assets

**Assertions**:
- [ ] `NOT READY` verdict in output
- [ ] All HIGH findings listed with FILE, LINE, FINDING, SEVERITY, FIX
- [ ] Recommended fix order shown in next steps
- [ ] Re-run instruction (`/localization-rtl he`) included

**Case Verdict**: PASS

---

### Case 3: Mode Variant — CONCERNS Verdict (MEDIUM Only)
**Fixture**:
- Godot 4 project; fonts are appropriate
- RTL layout flag present on root container
- `src/` has one instance of string concatenation with `+` operator for UI text (MEDIUM)
- `assets/` has `speech_bubble_left.png` with no `speech_bubble_right.png` (MEDIUM)
- No HIGH findings
- Argument: `fa`

**Expected behavior**:
1. All checks complete — 0 HIGH, 2 MEDIUM, 0 LOW
2. Verdict: **CONCERNS**
3. CONCERNS message advises on string assembly grammar risks and directional asset mirroring
4. Report write prompt fires

**Assertions**:
- [ ] `CONCERNS` verdict in output
- [ ] CONCERNS message includes guidance on MEDIUM findings (not blocked)
- [ ] No "NOT READY" messaging present
- [ ] Manual in-engine walkthrough still required (mentioned in output)

**Case Verdict**: PASS

---

### Case 4: Edge Case — Unsupported Locale Argument
**Fixture**:
- Argument: `zh` (Chinese — not RTL)

**Expected behavior**:
1. Validates locale — `zh` not in supported list (`ar`, `he`, `fa`, `ur`)
2. Outputs: "`zh` is not an RTL locale. /localization-rtl supports: ar (Arabic), he (Hebrew), fa (Persian/Farsi), ur (Urdu). For LTR locale validation, use /localization-qa."
3. Stops cleanly without spawning any subagents

**Assertions**:
- [ ] Correct unsupported-locale message with all 4 supported codes listed
- [ ] Redirect to `/localization-qa` mentioned
- [ ] No subagents spawned
- [ ] No files written

**Case Verdict**: PASS

---

### Case 5: Protocol — Read-Only Skill, Report Write Approval
**Fixture**:
- All 5 checks complete with findings
- Report ready to write

**Expected behavior**:
1. Findings displayed in full before write prompt
2. "May I write this RTL validation report to `production/localization/rtl-check-[locale]-[date].md`?" fires
3. Report written only on approval
4. No source files modified at any point during the skill run

**Assertions**:
- [ ] Uses "May I write" before report file write
- [ ] Full report content visible before approval prompt
- [ ] No source file writes at any point (skill is read-only on src/)
- [ ] No auto-write of report

**Case Verdict**: PASS

---

## Protocol Compliance

- [ ] Uses `"May I write"` before any file writes (or is read-only and skips this)
- [ ] Presents findings/draft to user before requesting approval
- [ ] Ends with a recommended next step or follow-up action
- [ ] Does not auto-create files without user approval

---

## Coverage Notes

- This skill performs STATIC analysis only. The mandatory in-engine visual verification step (text renders RTL, containers mirror, no overflow, arrows face correct direction, fills flow RTL) cannot be tested by any automated spec — it requires a human walkthrough in the engine.
- Font detection relies on filename heuristics (`NotoSansArabic`, `Amiri`, `Frank Ruhl Libre`, etc.). Custom fonts with non-standard names may be incorrectly flagged as HIGH severity even if they include the required Unicode ranges — a false-positive gap.
- Check 2 (positional layout) notes that patterns inside locale-guard conditionals should be downgraded to LOW. Correctly identifying a locale guard requires the subagent to parse control flow, which is a runtime quality behavior not verifiable statically.
- If no engine is detected from `technical-preferences.md`, the subagent falls back to a generic search for `"layout_direction"` and `"rtl"` — this fallback path is not separately cased here.
