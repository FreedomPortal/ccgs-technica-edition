---
name: l10n-i18n
description: "Internationalization (i18n) readiness audit. Checks code for locale-naive patterns BEFORE translation begins: number/date/currency formatting without locale APIs, string concatenation that breaks under RTL grammar, missing plural form support, hardcoded locale assumptions. Distinct from /l10n-prepare (which wraps strings) — this checks that the CODE is ready for localization."
argument-hint: "[--scope path] [--review full|lean|solo]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Task, AskUserQuestion
---

# /l10n-i18n — Internationalization Readiness Audit

**i18n vs l10n distinction:**
- **i18n (this skill)**: Is the code *architected* to support localization? Numbers, dates,
  currencies, plural forms, locale-aware comparisons, layout assumptions.
- **l10n (`/l10n-prepare`)**: Are the *strings* extracted and wrapped?

Run this skill BEFORE `/l10n-prepare` or alongside it in a first-time setup. Issues found
here require code changes — not just string extraction.

**Verdict:** `I18N_READY` / `NEEDS_WORK` / `NOT_READY`

---

## Phase 0: Resolve Options

1. If `--review [mode]` passed → use that
2. Else read `production/review-mode.txt` → use that value
3. Else → default to `lean`

If `--scope [path]` passed → limit scan to that path. Otherwise scan `src/`.

Read `.claude/docs/technical-preferences.md` for engine type. Store as `[ENGINE]`.

---

## Phase 1: Run 6 i18n Checks

Spawn `localization-lead` via Task:

```
Internationalization Readiness Audit

Engine: [ENGINE]
Scope: [path — default src/]

Run all 6 checks below. For each finding, report:
  FILE: [path]
  LINE: [line number]
  PATTERN: [the code found]
  ISSUE: [why this is an i18n problem]
  SEVERITY: HIGH (blocks localization) / MEDIUM (will cause issues in specific locales) / LOW (best practice)
  FIX: [recommended correction]

---

CHECK 1: LOCALE-NAIVE NUMBER FORMATTING
Scan for number-to-string conversions that produce locale-sensitive output without
using a locale-aware formatter.

Patterns to flag:
  - str(float_value) or String(float_value) used in UI text output context
  - Direct string interpolation of floats (e.g., "%s%%", "Damage: %d")
  - Hardcoded thousands separators or decimal points ("1,000", "3.14") in UI strings
  - Number formatting functions that don't accept a locale parameter

Engine-specific:
  - Godot: flag `str()` called on float/int near `.text =` or `label.set_text()`
  - Unity: flag `.ToString()` on numeric types near UI text assignment
  - Unreal: flag FString::FromInt / FString::SanitizeFloat near UTextBlock assignment

Note: Internal calculations, debug output, and file I/O do NOT need locale-aware formatting.
Only flag output that reaches the UI.
Severity: MEDIUM — decimal/thousand separator differs across locales (1.000,00 vs 1,000.00)

---

CHECK 2: LOCALE-NAIVE DATE AND TIME FORMATTING
Scan for date/time formatting that produces locale-sensitive output without locale param.

Patterns to flag:
  - Direct datetime string construction: day + "/" + month + "/" + year patterns
  - Hardcoded date format strings: "MM/DD/YYYY", "DD-MM-YYYY", "YYYY/MM/DD"
  - OS time functions called and formatted without locale parameter:
    - Godot: Time.get_datetime_string_from_system() used directly in UI
    - Unity: DateTime.ToString() without CultureInfo parameter
    - General: strftime() / date format strings without locale injection
  - 12-hour vs 24-hour time: hardcoded AM/PM strings
  - Month names hardcoded in English

Severity: MEDIUM for format order (USA vs EU vs ISO); HIGH for hardcoded month/day names

---

CHECK 3: LOCALE-NAIVE CURRENCY FORMATTING
Scan for currency display without locale-aware formatting.

Patterns to flag:
  - Currency symbol hardcoded before number: "$" + str(price), "£" + amount
  - Currency symbol hardcoded after number: str(price) + " USD"
  - No locale-aware currency formatter used
  - Price calculations that produce floats displayed directly in UI

Note: Games using fictional in-game currency (coins, gems) are exempt from locale
currency formatting — flag only if real-world currencies appear (IAP prices, DLC).
Severity: HIGH if real-world currency; LOW if fictional currency

---

CHECK 4: STRING CONCATENATION THAT BREAKS GRAMMAR
Scan for string assembly that assumes English subject-verb-object word order.

Patterns to flag:
  1. Concatenation with + operator for user-facing sentences:
     "You have " + str(count) + " items"  →  word order breaks in German, Japanese
  2. Positional format specifiers that fix argument position:
     "%s defeated %s" — subject/object order varies by language
  3. Embedded noun phrases that need grammatical gender agreement:
     "a " + item_name  (article "a/an" and gender don't translate)
  4. Conditional article selection based only on vowel check:
     "a" if name[0] not in "AEIOUaeiou" else "an"  — meaningless outside English

Acceptable (do NOT flag):
  - Named placeholders: "{attacker} defeated {defender}" — word order can be swapped by translator
  - Single interpolated value with no surrounding words: "Health: {hp}"

Severity: MEDIUM for simple concatenation; HIGH for positional format specifiers

---

CHECK 5: PLURAL FORM GAPS
Detect places where plural logic exists but uses only English binary (singular/plural).

Patterns to flag:
  1. Ternary/conditional plural that provides exactly 2 forms:
     count == 1 ? "item" : "items"
     "item" if count == 1 else "items"
     count == 1 and "item" or "items"
  2. String keys in the string table where the English has "item/items" variants
     but the key schema has no plural_forms field
  3. Plural logic NOT using the engine's plural form system:
     - Godot: should use tr_n("singular", "plural", n) or plural_forms in CSV/PO
     - Unity: should use Smart.Format or LocalizedString with plural rules
     - Unreal: should use FText::Format with plural argument
  4. Hardcoded plural suffix rules: str[:-1] + "ies", word + "s"

Note: Russian has 3 plural forms, Arabic has 6, Polish has 4. Binary plural is
insufficient for most non-English locales.
Severity: HIGH — pluralization breaks in most Slavic and Semitic languages

---

CHECK 6: HARDCODED LOCALE ASSUMPTIONS
Scan for code that hardcodes locale-specific behavior.

Patterns to flag:
  1. Locale code hardcoded as string: "en", "en_US", "en-US" in runtime logic
     (not in config/setup — in conditional branches or string comparisons)
  2. Alphabet/character range assumptions:
     char >= 'A' && char <= 'Z'  — breaks for non-Latin scripts
     char.isalpha() used for input validation that will run on non-Latin input
  3. Sort order that assumes English alphabetical order (locale-unaware sort)
  4. Text measurement assuming monospace or Latin character widths:
     string.length() used for UI layout calculations (CJK chars are wider)
  5. Regex patterns matching English-only character classes: [a-zA-Z]+
     when the field will receive non-Latin input

Severity: MEDIUM for sort order; HIGH for character range validation on user input

---

After all 6 checks, output:

I18N Audit — [date]
====================
Engine: [detected]
Scope: [path]

CHECK 1 — Number Formatting:    [PASS / N findings (H/M/L)]
CHECK 2 — Date/Time Formatting: [PASS / N findings (H/M/L)]
CHECK 3 — Currency Formatting:  [PASS / N findings (H/M/L)]
CHECK 4 — String Concatenation: [PASS / N findings (H/M/L)]
CHECK 5 — Plural Form Gaps:     [PASS / N findings (H/M/L)]
CHECK 6 — Locale Assumptions:   [PASS / N findings (H/M/L)]

HIGH SEVERITY findings: [list all]
MEDIUM SEVERITY findings: [list all]
LOW SEVERITY findings: [list all]

VERDICT: I18N_READY / NEEDS_WORK / NOT_READY

I18N_READY   — 0 HIGH, 0 MEDIUM findings
NEEDS_WORK   — 1+ MEDIUM, 0 HIGH findings
NOT_READY    — 1+ HIGH findings
```

---

## Phase 2: Present Findings

Display the full report. Summarize HIGH findings prominently.

If no source code exists yet:
> "No source code found in `src/`. i18n audit runs on implementation — come back after
> code is written. Run `/l10n-prepare scaffold` now to set up the string table structure."
Stop.

---

## Phase 3: Write Report

Ask: "May I write this i18n audit to `production/localization/i18n-audit-[date].md`?"

If yes, write report including all findings, verdict, and fix recommendations.

---

## Phase 4: Next Steps

Based on verdict:

**NOT_READY:**
```
i18n Audit — NOT_READY
[N] HIGH severity issues must be fixed before starting translation.
Fixing these after translations are delivered is extremely costly.

Priority order:
1. Plural form gaps — affects correctness in most non-English locales
2. String concatenation — grammar breaks require string table restructuring
3. Hardcoded locale assumptions — may require architecture changes
4. Number/date/currency formatting — usually localised with engine APIs

After fixing HIGH items: re-run /l10n-i18n to confirm.
Then: /l10n-prepare scan to start string extraction.
```

**NEEDS_WORK:**
```
i18n Audit — NEEDS_WORK
[N] MEDIUM severity issues. Translation can proceed but these will cause
locale-specific problems (broken grammar in German, wrong numbers in some locales, etc.)

Recommended: fix MEDIUM issues before calling string freeze.
When ready: /l10n-prepare to extract and wrap strings.
```

**I18N_READY:**
```
i18n Audit — I18N_READY
No blocking i18n issues found.

Next: /l10n-prepare scan — extract and wrap hardcoded strings for translation.
```

---

## Collaborative Protocol

- This skill is read-only — reports findings, does not modify source files
- Fixes must be implemented by a programmer (spawn `gameplay-programmer` or relevant engine specialist)
- Check 5 (plural forms) is the most commonly missed — surface it clearly even if count is low
- If no string table exists yet: still run checks — i18n issues are code problems, not string problems
