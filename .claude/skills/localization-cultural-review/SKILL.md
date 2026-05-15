---
name: localization-cultural-review
description: Standalone cultural sensitivity audit of SOURCE content before translation begins. Checks symbols, numbers, humour, names, violence ratings, and text-in-images for cultural landmines across target locales.
argument-hint: "[locale] [full|scoped]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Task, AskUserQuestion
model: sonnet
---

# /localization-cultural-review

**Purpose**: Audit SOURCE content (English text, UI, asset names, imagery descriptions) for
cultural issues BEFORE sending to translators. This is not a translation quality check — it
finds content that may need adaptation, removal, or creative replacement in specific locales.

**Distinct from `/localization-qa` Phase 4**: `/localization-qa` checks that TRANSLATIONS are
culturally appropriate for a given locale. This skill checks that SOURCE CONTENT does not
contain cultural landmines that will cause issues regardless of how they are translated.

---

## When to Run

Run `/localization-cultural-review` before:
- Preparing strings for translation (`/localization-integrate export`)
- Adding a new locale target to the project
- Shipping a new content update to an existing locale

---

## Phase 1: Scope

Ask: "Which target locales should this review cover?"

Present a checklist of locales derived from `assets/data/strings/` (any `strings-[locale].json`
present) plus any locales the user lists. If no locales are configured yet, ask the user to
specify the intended target markets.

Ask: "Should this review cover: (A) Full project scan, or (B) A specific content area?"

Options:
- **Full** — scan all string tables, GDDs, UI scene names, asset references
- **Scoped** — user specifies a system, scene, or file range

---

## Phase 2: Source Scan

Spawn `localization-lead` via Task:

```
Localization Cultural Review — Source Scan

Target locales: [list]
Scope: [full / scoped — describe]

Read the following sources:
- assets/data/strings/strings-en.json (all source strings)
- Any referenced GDD files in design/gdd/ that describe UI content, character names, or story beats
- UI scene filenames in src/ (node names, button labels embedded in scene descriptions)

For each of the following cultural check categories, flag any strings or content areas
that may be problematic for the specified target locales. For each flag, note:
  - KEY: the string key or file reference
  - CONTENT: the source text or description
  - LOCALE(S): which target locale(s) are affected
  - SEVERITY: HIGH (must fix before ship) / MEDIUM (adapt or add note for translator) / LOW (monitor)
  - REASON: why this is an issue and what cultural rule it violates
  - RECOMMENDATION: suggested fix, adaptation strategy, or translator instruction

Cultural Check Categories:

1. SYMBOLS & GESTURES
   - Thumbs up (offensive in some Middle Eastern and West African cultures)
   - OK hand gesture (offensive in Brazil, some European contexts)
   - Directional gestures that assume LTR reading direction
   - Color symbolism (white = mourning in East Asian cultures; green = bad luck in some cultures)

2. NUMBERS & SUPERSTITIONS
   - 4 (death in Japanese/Chinese/Korean — "shi")
   - 13 (Western unlucky)
   - 666 (Western demonic — may flag app store reviews)
   - 7 (lucky in West, not universal)
   - Significant use of these as default values, tier counts, item counts, prices

3. HUMOUR, IDIOMS & WORDPLAY
   - English puns that cannot translate
   - Idioms that are meaningless or offensive when literal-translated
   - Sarcasm or irony that may land as sincere in some cultures
   - Pop culture references that are region-specific

4. VIOLENCE, RATINGS & CONTENT
   - Blood references (some regions have stricter ratings thresholds)
   - Gambling mechanics described in text (some regions restrict)
   - Religious or political references
   - Drug/alcohol references in text

5. NAMES & REPRESENTATIONS
   - Character names that are common surnames or offensive terms in target locales
   - Faction, organisation, or product names that conflict with existing brands or terms
   - Names that have unintended meaning in target languages

6. TEXT IN IMAGES (HARDCODED)
   - Any UI asset, texture, or image filename suggesting baked-in text
   - Logos or emblems that contain language-specific text
   - Tutorial screenshots or embedded diagrams with English labels

Report format per finding:
KEY | LOCALE | SEVERITY | CONTENT | REASON | RECOMMENDATION
```

---

## Phase 3: Present Findings

Format findings grouped by severity:

```
Localization Cultural Review — [Date]
======================================
Target locales: [list]
Scope: [full / scoped]

HIGH SEVERITY (must fix before shipping to affected locale)
-----------------------------------------------------------
[List findings]

MEDIUM SEVERITY (adapt or add translator instruction)
-----------------------------------------------------
[List findings]

LOW SEVERITY (monitor; no immediate action required)
----------------------------------------------------
[List findings]

CLEAN CATEGORIES (no issues found)
-----------------------------------
[List categories with no findings]
```

If zero findings across all categories: output "No cultural issues found for target locales. Ready to proceed to /localization-integrate export."

---

## Phase 4: Action Decision

For each HIGH and MEDIUM finding, ask the user:

"Finding [KEY] — [SEVERITY]: [REASON]. Options:
A) Fix source text now (describe fix)
B) Add translator instruction (I'll note this in the export brief)
C) Exclude from this locale (I'll flag the key as locale-excluded)
D) Accept risk — no action"

For LOW findings: "Accept all LOW severity findings and continue? (Y/N)"

---

## Phase 5: Write Report

Ask: "May I write the cultural review report to `production/localization/cultural-review-[date].md`?"

If yes, write a report containing:
- Review metadata (date, scope, target locales)
- All findings with decisions recorded
- Keys flagged for translator instruction (to be included in `/localization-integrate export` brief)
- Keys excluded from specific locales

---

## Phase 6: Integration Handoff

If any keys have translator instructions or locale exclusions, output:

```
Cultural review complete. Before running /localization-integrate export:
- [N] keys have translator instructions — these will be included in the export brief automatically
- [N] keys are excluded from [locale] — flag these during /localization-integrate import

Run /localization-integrate export when ready to send strings to translators.
```

---

## Collaborative Protocol

- Never make source text changes without showing the exact diff and receiving per-change approval
- Translator instructions are advisory — always surface them to the user for sign-off
- Locale exclusions must be explicit user decisions — never exclude automatically
- This skill audits source content only; it does not check translation files
