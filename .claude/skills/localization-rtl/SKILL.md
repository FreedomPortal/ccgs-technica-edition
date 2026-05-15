---
name: localization-rtl
description: RTL layout validation for Arabic (ar), Hebrew (he), Persian (fa), and Urdu (ur). Runs 5 checks: RTL layout flag, hardcoded positional layout, string assembly, font support, directional assets. Outputs READY / CONCERNS / NOT READY verdict.
argument-hint: "[ar|he|fa|ur]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Task, AskUserQuestion
model: sonnet
---

# /localization-rtl [locale?]

**Purpose**: Validate the game's UI and code for RTL (right-to-left) layout support. Catches
common RTL implementation errors before a locale ships: missing layout flags, positional
layout assumptions, bad string concatenation, missing fonts, and directional assets that
break under text mirroring.

**Supported RTL locales**: Arabic (`ar`), Hebrew (`he`), Persian (`fa`), Urdu (`ur`).

**Important**: This skill performs static code and file analysis. It CANNOT replace visual
verification in-engine — always do a manual RTL pass in the engine before shipping an
RTL locale.

---

## Phase 1: Locale Selection

If a locale argument is provided, validate it is one of: `ar`, `he`, `fa`, `ur`.

If no argument: "Which RTL locale should this check target? (ar / he / fa / ur)"

If the locale is not in the supported RTL list:
```
[locale] is not an RTL locale. /localization-rtl supports: ar (Arabic), he (Hebrew),
fa (Persian/Farsi), ur (Urdu).

For LTR locale validation, use /localization-qa.
```

---

## Phase 2: Run 5 RTL Checks

Spawn `localization-specialist` via Task:

```
RTL Layout Validation

Target locale: [locale]
Engine: [derive from CLAUDE.md or .claude/docs/technical-preferences.md]

Run the following 5 checks. For each check, list every finding with:
  FILE: [path]
  LINE: [line number if applicable]
  FINDING: [what was found]
  SEVERITY: HIGH (blocks RTL ship) / MEDIUM (should fix) / LOW (advisory)
  FIX: [recommended correction]

---

CHECK 1: RTL LAYOUT FLAG
Confirm that UI containers have RTL layout configured for the target locale.
Engine-specific targets:
  - Godot: search src/ for Control nodes. Flag any Control subclass that sets
    layout_direction to LAYOUT_DIRECTION_LTR without a locale guard. Look for
    set_layout_direction() calls and [layout_direction = ...] in .tscn files.
  - Unity: search for TextMeshPro components; flag any without RTL Support package import.
  - Unreal: search for UTextBlock or UHorizontalBox; flag any without text direction override.
If no engine detected, search for "layout_direction" and "rtl" across src/ and flag absence.
Severity: HIGH if missing on root containers.

---

CHECK 2: HARDCODED POSITIONAL LAYOUT
Search src/ for patterns that assume LTR reading direction:
  - Pixel offset anchoring using left/right absolute values without RTL guard
    (e.g., position.x = 10, anchor_left = 0, margin_left = N)
  - HBoxContainer or equivalent horizontal container child order assumptions
    (first child = leftmost — reverses under RTL)
  - Hardcoded x-position for UI elements (e.g., rect_position.x = 100)
  - "left" or "right" in anchor variable names without RTL conditional

Flag each instance. If inside a function that checks current locale, note as LOW.
Severity: HIGH if no locale guard present.

---

CHECK 3: STRING ASSEMBLY
Search src/ for string concatenation near UI output code:
  - `+` operator used to join strings that will be displayed as UI text
  - `%s` positional format strings (position-dependent, breaks in RTL grammar)
  - String interpolation that assumes subject-verb-object order

Flag occurrences. Named placeholders (e.g., {name}, %{character}) are acceptable.
Severity: MEDIUM (grammar issues vary by language; not always broken, but risky).

---

CHECK 4: FONT SUPPORT
Search assets/fonts/ (or equivalent) for fonts loaded in the project.
  - Identify fonts by filename and any .import or .tres references in src/
  - Flag any font that does NOT include Arabic/Hebrew Unicode range coverage
    (look for font names: Noto Sans Arabic, Amiri, Arial Unicode, Scheherazade,
    Frank Ruhl Libre, SBL Hebrew, or similar; flag Latin-only fonts like Roboto,
    Open Sans, custom pixel fonts)
  - Pixel art fonts are almost certainly Latin-only — flag as HIGH

If no fonts directory found: "No fonts directory detected. Verify font loading
in src/ and confirm Arabic/Hebrew-capable fonts are included for RTL locales."
Severity: HIGH if only Latin fonts found.

---

CHECK 5: DIRECTIONAL ASSETS
Search assets/ for filenames or references suggesting directional UI elements:
  - "arrow", "chevron", "back", "forward", "next", "prev", "left", "right"
    in asset filenames (images, sprites, icons)
  - Progress bars described as left-to-right fill in code (e.g., value mapped to width)
  - Asymmetric UI panels (e.g., "speech_bubble_left.png")

For each found asset, check if a mirrored variant exists (e.g., arrow_left.png + arrow_right.png).
Flag assets with no mirrored variant as needing RTL adaptation.
Severity: MEDIUM for icons (can often be CSS-mirrored); HIGH for baked fill-direction logic.

---

After all 5 checks, output:

RTL Validation — [locale] — [date]
=====================================
Engine: [detected]
Checks run: 5

CHECK 1 — RTL Layout Flag:       [PASS / N findings (H/M/L)]
CHECK 2 — Positional Layout:     [PASS / N findings (H/M/L)]
CHECK 3 — String Assembly:       [PASS / N findings (H/M/L)]
CHECK 4 — Font Support:          [PASS / N findings (H/M/L)]
CHECK 5 — Directional Assets:    [PASS / N findings (H/M/L)]

HIGH SEVERITY findings:
  [list all HIGH findings]

MEDIUM SEVERITY findings:
  [list all MEDIUM findings]

LOW SEVERITY findings:
  [list all LOW findings]

VERDICT: READY / CONCERNS / NOT READY

READY     — 0 HIGH findings
CONCERNS  — 1+ MEDIUM, 0 HIGH
NOT READY — 1+ HIGH findings

IMPORTANT: This static analysis cannot replace in-engine visual verification.
After implementing fixes, do a manual RTL walkthrough in the engine before shipping.
```

---

## Phase 3: Present Report

Display the full report from the localization-specialist.

---

## Phase 4: Write Report

Ask: "May I write this RTL validation report to `production/localization/rtl-check-[locale]-[date].md`?"

If yes, write the report with all findings, verdict, and the manual verification reminder.

---

## Phase 5: Next Steps

Based on verdict:

**NOT READY:**
```
RTL check — NOT READY for [locale].
Fix all HIGH severity findings before shipping. Recommended order:
1. Font support (enables rendering)
2. RTL layout flag (enables mirroring)
3. Positional layout (most time-consuming)
4. String assembly
5. Directional assets

After fixes: re-run /localization-rtl [locale] to confirm.
Then: manual in-engine RTL walkthrough before final sign-off.
```

**CONCERNS:**
```
RTL check — CONCERNS for [locale].
MEDIUM findings are advisory but recommended fixes. Assess each:
- String assembly issues may cause grammar problems in [locale] specifically
- Directional assets may look incorrect under mirroring

After addressing concerns: manual in-engine RTL walkthrough before final sign-off.
```

**READY:**
```
RTL check — READY for [locale] (static analysis only).
No blocking issues found.

Required next step: manual in-engine RTL walkthrough before shipping.
Enable [locale] in-engine, navigate all screens, and verify:
  □ Text renders right-to-left throughout
  □ Containers mirror correctly
  □ No layout overflow or clipping
  □ Icons and arrows face the correct direction
  □ Progress bars and fills flow RTL
```

---

## Collaborative Protocol

- This skill is read-only — it never modifies source files
- All findings are reports; fixes must be implemented by the programmer manually
- Severity ratings are conservative — a HIGH means "do not ship without fixing this"
- In-engine visual verification is mandatory regardless of READY verdict
