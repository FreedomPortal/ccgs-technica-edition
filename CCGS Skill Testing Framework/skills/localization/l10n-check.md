# Skill Spec: /l10n-check
> **Category**: localization
> **Priority**: low
> **Spec written**: 2026-06-11

## Skill Summary

/l10n-check is a read-only localization status snapshot. It reads `production/localization/intent.md` to determine the project's localization intent (YES / NO / LATER / missing), then — when intent is YES — collects the presence and state of all l10n pipeline artifacts (string tables, audit reports, translator briefs, LQA passes, RTL checks, freeze status) and emits a stage-aware report that categorizes each artifact as DONE, MISSING (OVERDUE), or NOT YET (UPCOMING). It writes no files. It is model: haiku and is also triggered automatically at session start when intent is YES.

---

## Static Assertions

- [x] Frontmatter has all required fields — `name`, `description`, `argument-hint`, `user-invocable`, `allowed-tools`, `model` all present
- [x] 2+ phase headings — Phase 1 (Read Intent), Phase 2 (Collect Artifact Status), Phase 3 (Stage-Aware Report)
- [x] Verdict keyword present — "BLOCKING" appears explicitly for the Release-stage missing LQA case; OVERDUE / MISSING serve as verdict signals throughout the report
- [x] If Write/Edit in allowed-tools: "May I write" language present — NOT APPLICABLE: allowed-tools are Read, Glob, Grep, Bash only; skill states "Read-only — never writes files"
- [x] Next-step handoff present — "NEXT STEPS" section in the Phase 3 report template, plus explicit next-skill recommendations in the stop branches (e.g., "Run /start", "run /l10n-check again", "/l10n-qa [locale]")

---

## Director Gate Checks

N/A — the skill contains no director review trigger, no spawned subagent, and no gate verdict that routes to a director agent. It reports status and stops; the user decides which skill to run next.

---

## Test Cases

**Case 1: Happy Path — intent YES, all artifacts present, stage = Release**

Fixture:
- `production/localization/intent.md` exists; Status: YES; Target locales: en, fr, de; Stage at declaration: Pre-Production
- `production/stage.txt` = Release
- `assets/data/strings/strings-en.json` exists with 47 keys
- `production/localization/i18n-audit-2026-03-01.md` exists
- `production/localization/cultural-review-2026-04-01.md` exists
- `production/localization/translator-brief-2026-04-15.md` exists
- `production/localization/screenshot-checklist-2026-05-01.md` exists
- `production/localization/freeze-status.md` Status: ACTIVE
- `production/localization/lqa-fr-2026-05-20.md` and `production/localization/lqa-de-2026-05-21.md` exist
- No RTL locales declared

Expected behavior: Skill reads all artifacts without error. Emits the Phase 3 report with all rows marked ✅. OVERDUE section is empty or absent. NEXT STEPS notes release readiness. No BLOCKING flag raised.

Assertions:
- All artifact rows show ✅ DONE
- No OVERDUE items listed
- LQA rows show PASS (or present) for fr and de
- RTL row not shown (no RTL locales)
- Report ends with a NEXT STEPS list

Verdict: PASS

---

**Case 2: Failure / Blocked — intent YES, stage = Release, LQA missing for one locale**

Fixture:
- `production/localization/intent.md` Status: YES; Target locales: en, fr, de
- `production/stage.txt` = Release
- All earlier artifacts present
- `production/localization/lqa-fr-2026-05-20.md` exists; no lqa-de-* file exists

Expected behavior: Skill detects missing LQA for `de`. Per the Collaborative Protocol: "If a locale in the intent list has no LQA report and stage is Release: mark as BLOCKING."

Assertions:
- LQA row for `de` marked ⚠️ MISSING
- OVERDUE section lists the missing LQA for `de`
- BLOCKING label appears for the `de` LQA item
- Skill stops after report; does not auto-launch /l10n-qa
- NEXT STEPS includes `/l10n-qa de`

Verdict: BLOCKED

---

**Case 3: Mode Variant — intent file missing entirely**

Fixture:
- `production/localization/intent.md` does not exist

Expected behavior: Phase 1 early-exit branch fires. Skill emits the prescribed message:
```
Localization intent not declared.
Run /start or answer the l10n question there to capture intent.
All /l10n-* skills are available immediately if you want to begin — minimum
requirement is source code in src/ for /l10n-i18n and /l10n-prepare.
```
Then stops. Does not proceed to Phase 2 or Phase 3.

Assertions:
- Output matches the exact prescribed message (or is substantively identical)
- No artifact checks performed
- No file writes attempted
- Skill halts after the message

Verdict: PASS (early exit is expected behavior)

---

**Case 4: Edge Case — intent YES, stage = Production, several artifacts legitimately absent**

Fixture:
- `production/localization/intent.md` Status: YES; Target locales: en, ja
- `production/stage.txt` = Production
- `assets/data/strings/strings-en.json` exists with 12 keys
- `production/localization/i18n-audit-2026-02-01.md` exists
- No cultural-review, no translator-brief, no screenshot-checklist, no freeze-status, no LQA files
- `ja` is not an RTL locale

Expected behavior: Skill applies stage expectations from the table. At Production stage, required artifacts are "string table has entries, strings wrapped." LQA, translator brief, screenshot checklist, and freeze are NOT YET required. Skill marks absent post-Production items as ➡️ NOT YET (UPCOMING), not as OVERDUE.

Assertions:
- String table row shows ✅ (12 keys present)
- i18n audit row shows ✅
- cultural-review, translator-brief, screenshot-checklist, freeze rows show ➡️ NOT YET
- LQA rows show ➡️ NOT YET
- No BLOCKING flag raised
- OVERDUE section is empty or absent
- UPCOMING section lists the absent future artifacts

Verdict: PASS

---

**Case 5: Most Relevant Variant — intent Status: LATER**

Fixture:
- `production/localization/intent.md` exists; Status: LATER
- `production/stage.txt` = Pre-Production (stage file exists but should not be read per flow)

Expected behavior: Phase 1 LATER branch fires. Skill emits the prescribed message:
```
Localization intent: LATER — deferred decision.
Reminder: entering Production without strings extracted means retrofitting mid-sprint.
When ready to commit: edit production/localization/intent.md Status to YES and
run /l10n-check again to see what's needed.
```
Then stops. Does not proceed to Phase 2 or Phase 3.

Assertions:
- Output matches the prescribed LATER message (or is substantively identical)
- No artifact glob/read operations performed after intent is read
- No file writes attempted
- Skill halts after the message

Verdict: PASS (early exit is expected behavior)

---

## Protocol Compliance

- [x] "May I write" before file writes — NOT APPLICABLE: allowed-tools exclude Write and Edit; skill explicitly states "Read-only — never writes files"
- [x] Presents findings before approval — NOT APPLICABLE: no approval gate exists; the full report IS the output and is presented directly to the user
- [x] Ends with next step — YES: all execution paths end with a next-step reference, either an explicit NEXT STEPS block (Phase 3) or a prescribed message naming the next skill to run (Phase 1 stop branches)
- [x] No auto-create without approval — SATISFIED by design: the skill has no create capability; Collaborative Protocol section explicitly states "Does not launch any l10n skill — reports and stops; user runs the recommended skill"

---

## Coverage Notes

**LC1** — PARTIAL PASS. The skill operates on translation file artifacts (strings-en.json, lqa-[locale]-*.md, etc.) and on pipeline metadata files (intent.md, audit reports). It does not explicitly state "this skill operates on source strings" vs "translation files" in a single declaration, but the artifact table in Phase 2 makes the scope unambiguous by enumeration. No written statement distinguishes source strings from translated strings as explicit categories.

**LC2** — SATISFIED. The skill's allowed-tools are Read, Glob, Grep, Bash only. Write and Edit are absent. The Collaborative Protocol section states "Read-only — never writes files." No modifications to strings-*.json or locale files are possible.

**LC3** — NOT ADDRESSED. The skill contains no mechanism for locale exclusions, key omissions, or scope reductions. It reads the target locale list from intent.md as-is and reports on all declared locales. There is no written instruction covering what happens if the user wants to exclude a locale mid-check; that decision path is not described.

**LC4** — SATISFIED. Every execution path ends with a next-step reference. The Phase 3 template includes an explicit "NEXT STEPS" section with an ordered list. All Phase 1 early-exit branches name the specific action or skill to run next. The stage expectations table in Phase 3 maps each stage to the recommended next l10n skill.