# Skill Spec: /telemetry-design
> **Category**: analytics
> **Priority**: high
> **Spec written**: 2026-06-11

## Skill Summary

`/telemetry-design` produces a focused event taxonomy document for a single business question, generating the minimum set of analytics events needed to answer it. The skill reads existing analytics and game-concept files, identifies coverage gaps, delegates event design to a `growth-analyst` subagent, presents the output for user review and trimming, then writes the document to `docs/analytics/telemetry-[slug].md` only after explicit user approval. It is intentionally narrower than `/analytics-setup` (which designs the full event taxonomy) and complements `/retention-analysis` and `/ab-test` (which consume the resulting data).

---

## Static Assertions

- [x] Frontmatter has all required fields — `name`, `description`, `argument-hint`, `user-invocable`, `allowed-tools` all present
- [x] 2+ phase headings found — 7 phases present (Phase 1 through Phase 7)
- [x] At least one verdict keyword present — `Verdict: COMPLETE` in Phase 7 summary block
- [x] If allowed-tools includes Write/Edit: "May I write" language present — Phase 6 opens with explicit "May I write the telemetry design to..." ask
- [x] Next-step handoff section present — Phase 7 Summary block includes numbered next steps and references `/retention-analysis` and `/ab-test`

---

## Director Gate Checks

N/A — The skill does not invoke any director-tier review agents or gate-check skills. Event design is delegated to the `growth-analyst` subagent (non-director), and approval is handled via inline `AskUserQuestion`.

---

## Test Cases

**Case 1: Happy Path — Full run with analytics plan present**

Fixture:
- `docs/analytics/analytics-plan.md` exists with several events already defined
- `design/gdd/game-concept.md` exists with a complete game concept
- `.claude/docs/technical-preferences.md` exists
- User provides argument: `d7-dropoff`

Expected behavior:
1. Phase 1 reads all three context files silently; no warning emitted (plan exists)
2. Phase 2 skips `AskUserQuestion` and uses the provided argument as the business question
3. Phase 3 identifies overlapping events from the plan and presents them explicitly
4. Phase 4 spawns `growth-analyst` with substituted prompt; agent returns tiered event list
5. Phase 5 presents output and asks how to proceed; user selects `Accept as-is`
6. Phase 6 asks "May I write the telemetry design to `docs/analytics/telemetry-d7-dropoff.md`?"; user confirms
7. Phase 7 emits structured summary with event counts, output path, and 3 next steps; `Verdict: COMPLETE`

Assertions:
- No analytics-plan-missing warning is shown
- Phase 3 output contains "Your analytics plan already tracks:" prefix
- subagent Task prompt contains substituted game title, genre, business question, and existing events
- Written file path matches `docs/analytics/telemetry-d7-dropoff.md`
- File header contains `Business question:` and `Existing events reused:` fields
- Each event entry has `When`, `Properties`, `Why`, and `Priority` fields
- File includes `Integration Checklist` section
- Summary block shows correct event counts broken down by tier
- No file is written before "May I write" confirmation

Verdict: COMPLETE

---

**Case 2: Failure/Blocked — No analytics plan, no game concept**

Fixture:
- `docs/analytics/analytics-plan.md` does not exist
- `design/gdd/game-concept.md` does not exist
- No argument provided

Expected behavior:
1. Phase 1 cannot read analytics plan; emits the prescribed advisory note about running `/analytics-setup` first
2. Skill proceeds regardless (question-first is valid per instruction)
3. Phase 2 invokes `AskUserQuestion` with all 6 listed options since no argument was provided
4. User selects `Custom`; skill asks for a one-sentence question before proceeding
5. Phase 3 skips the existing-events list (no plan) and proceeds directly to Phase 4
6. Phase 4 spawns `growth-analyst` with "none" substituted for existing events; game title/genre sourced from game-concept.md — but that file is also missing

Gap (coverage note): The skill does not define fallback behavior if `game-concept.md` is absent. The subagent prompt requires `[GAME TITLE]`, `[GENRE]`, and `[CORE LOOP]` substitutions. Missing file leaves these fields blank or causes a malformed prompt — behavior is unspecified.

Assertions:
- Advisory note appears verbatim (or functionally equivalent) in Phase 1 output
- Skill does not halt after the warning
- `AskUserQuestion` is invoked in Phase 2 when no argument is supplied
- `Custom` path asks for one sentence before proceeding
- Phase 3 skips the existing-events block

Verdict: BLOCKED — game-concept.md absence is an unhandled state; subagent prompt substitution is undefined

---

**Case 3: Mode Variant — User selects "Trim to MUST TRACK only"**

Fixture:
- All context files present
- No argument provided; user selects `Onboarding funnel` from the Phase 2 menu
- `growth-analyst` returns 2 MUST TRACK, 3 SHOULD TRACK, 2 NICE TO HAVE events
- In Phase 5, user selects `Trim to MUST TRACK only`

Expected behavior:
1. Phase 5 removes SHOULD TRACK and NICE TO HAVE events from the event list before writing
2. Phase 6 asks for write confirmation referencing the trimmed document
3. Written document contains only the 2 MUST TRACK events
4. Phase 7 summary event count reflects trimmed set (e.g., "2 events (2 MUST TRACK, 0 SHOULD TRACK)")

Assertions:
- No SHOULD TRACK or NICE TO HAVE entries appear in the written file
- Summary counts match the trimmed set, not the full agent output
- "May I write" ask occurs after trim, not before
- Slug derives from "onboarding-funnel" topic, producing `telemetry-onboarding-funnel.md`

Verdict: COMPLETE

---

**Case 4: Edge Case — Business question already fully covered by existing events**

Fixture:
- `docs/analytics/analytics-plan.md` exists and tracks events that fully answer the chosen question
- User argument: `economy-health`
- `growth-analyst` is instructed to say so if the question is already answerable

Expected behavior:
1. Phase 3 lists the covering events: "Your analytics plan already tracks: [events]. These partially cover your question..."
2. Phase 4 subagent returns: "The question is already answerable with existing events. Recommend running `/retention-analysis` or `/ab-test` instead of adding more events."
3. Phase 5 presents this finding to the user; the event list is empty or contains no new events
4. If user selects `Accept as-is` with zero new events, Phase 6 still asks "May I write..." — write produces a document with an empty Event Design section and the recommendation noted in Gaps

Gap (coverage note): The skill does not explicitly define Phase 5/6 behavior when the agent recommends no new events. It is unclear whether the skill should offer an `Abort` option or still proceed to write a document with no new events.

Assertions:
- Agent recommendation surfaces to user before any approval gate
- No new events are invented to fill the document
- "May I write" is not skipped even when the event list is empty
- Gaps section in written file references `/retention-analysis` or `/ab-test`

Verdict: COMPLETE (with advisory: empty-event-list path behavior should be specified)

---

**Case 5: Argument Variant — Argument provided at invocation bypasses Phase 2 question**

Fixture:
- All context files present
- Skill invoked as `/telemetry-design match-session-pacing`
- `AskUserQuestion` in Phase 2 is designed to be skipped when an argument is supplied

Expected behavior:
1. Phase 1 reads context files normally
2. Phase 2 uses "match-session-pacing" (or the cleaned slug equivalent) as the business question without showing the menu
3. Phase 4 subagent prompt substitutes the argument as the business question
4. Phase 6 derives slug `match-session-pacing` for the output filename: `telemetry-match-session-pacing.md`

Gap (coverage note): The skill says "If the user provided an argument, use it as the starting question" but does not specify whether the argument is used verbatim as the question text or only as a slug/topic hint. If the user types a topic label rather than a full sentence question, the subagent prompt substitution `[QUESTION FROM PHASE 2]` may receive an incomplete prompt.

Assertions:
- No `AskUserQuestion` call in Phase 2 when argument is present
- Business question field in written file reflects the argument value
- Filename slug derives from the argument, not a generated value
- If argument does not map to one of the 5 predefined options, skill does not error — proceeds as custom question

Verdict: COMPLETE

---

## Protocol Compliance

- [x] "May I write" before file writes — Phase 6 explicitly requires confirmation before `Write`; Collaborative Protocol section reinforces "Never write files without asking"
- [x] Presents findings before approval — Phase 5 presents agent output and offers review/trim before the Phase 6 write gate
- [x] Ends with next step — Phase 7 lists 3 concrete next steps and recommends `/retention-analysis` or `/ab-test`
- [x] No auto-create without approval — Phase 6 waits for confirmation; no write call appears in earlier phases

---

## Coverage Notes

**AL1 — reads data before analysis, never invents numbers**: COVERED. Phase 1 reads three source files before any design begins. Phase 3 explicitly cross-references the existing plan. The subagent prompt provides sourced inputs (game title, genre, core loop) rather than asking the agent to invent them.

**AL2 — benchmarks explicitly sourced**: NOT COVERED. The skill does not reference industry benchmarks for event design (e.g., typical D7 retention rates, funnel drop-off norms). No benchmarks are cited or required in the subagent prompt or output template. This is a coverage gap — acceptable given the skill's scope is event taxonomy design rather than data analysis, but worth noting if the spec category requires benchmark citation.

**AL3 — structured findings table with severity**: PARTIAL. Event priority tiers (MUST TRACK / SHOULD TRACK / NICE TO HAVE) serve as a severity-equivalent structure. However, the output is a list of sections per event, not a structured table. No severity column or tabular format is specified in the document template. A reviewer parsing for a formal findings table would not find one.

**AL4 — output gated behind "May I write"**: COVERED. Explicitly enforced in Phase 6 and reiterated in the Collaborative Protocol section.

**AL5 — explicit follow-on skill recommended**: COVERED. Phase 7 next steps explicitly name `/retention-analysis` and `/ab-test`. The Phase 4 subagent prompt also instructs the agent to recommend these if the question is already answerable.

**Missing phase behavior**: The skill does not define behavior when `design/gdd/game-concept.md` is absent. The subagent prompt contains three substitution tokens (`[GAME TITLE]`, `[GENRE]`, `[CORE LOOP]`) sourced from that file. A missing file leaves the prompt malformed with no fallback — this is the primary unspecified failure mode.

**Slug derivation**: Phase 6 instructs deriving the slug from the business question topic with examples, but provides no normalization rule (lowercase, hyphenation, max length). Edge cases with special characters or long questions are unspecified.