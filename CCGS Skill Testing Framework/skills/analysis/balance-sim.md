# Skill Spec: /balance-sim
> **Category**: analysis
> **Priority**: low
> **Spec written**: 2026-06-11

## Skill Summary

`/balance-sim` is a multi-agent combat simulation skill that models rule-based matchups as documented in GDDs. It spawns parallel Haiku player agents in batched Task calls to simulate N fights (default 200, range 50–500), then a single Sonnet referee agent to aggregate statistics and produce a four-section balance report. The skill reads combat rules from the GDD, surfaces ambiguous rules explicitly, discards un-simulatable (VOID) fights from statistics, classifies balance by win-rate thresholds, and writes the final report to `production/balance/sim-[scenario]-[date].md` behind a "May I write" approval gate.

---

## Static Assertions

- [ ] Frontmatter has all required fields
  - name, description, model, argument-hint, user-invocable, allowed-tools — all present
- [ ] 2+ phase headings
  - Phase 1 through Phase 5 present (5 total)
- [ ] Verdict keyword present
  - "Verdict: COMPLETE — simulation report written." present in Recommended Next Steps section
- [ ] If Write/Edit in allowed-tools: "May I write" language present
  - Write is in allowed-tools; Phase 5 opens with: "Ask: 'May I write `production/balance/sim-[scenario]-[date].md`? [Y/N]'"
- [ ] Next-step handoff present
  - "Recommended Next Steps" section lists `/balance-check`, `/consistency-check`, and re-run instruction

---

## Director Gate Checks

N/A — skill contains no director gate invocations. The Referee in Phase 4 is an internal subagent Task, not a director gate skill call.

---

## Test Cases

### Case 1: Happy Path

**Fixture:** Project has `design/gdd/combat.md` with full stat tables (HP, ATK, SPD, specials, win condition). User invokes `/balance-sim base-vs-heavy --iterations 200`.

**Expected behavior:**
- Phase 1: GDD is found and loaded; matchup parameters extracted without ambiguity; matchup defined for both sides.
- Phase 2: 4 batches of 50 spawned simultaneously via Task; all return valid JSON arrays.
- Phase 3: 200 fights merged; statistics computed; win rate classified against balance thresholds.
- Phase 4: Single Sonnet referee Task spawned; four-section report produced.
- Phase 5: "May I write" prompt shown; on Y, `production/balance/sim-base-vs-heavy-[date].md` written.

**Assertions:**
- All 5 phases execute in documented order.
- Batches are issued simultaneously (all 4 at once), not sequentially.
- Statistics table includes all 9 metrics from Phase 3.
- Report header includes confidence level.
- Referee output covers all four sections: Game Flow Reconstruction, Strategic Observations, Balance Assessment, Design Recommendations.
- File is not written without approval.

**Verdict:** COMPLETE

---

### Case 2: Failure / Blocked — No Combat GDD

**Fixture:** Project has no file matching `design/gdd/*combat*.md` or `design/gdd/*battle*.md`.

**Expected behavior:**
- Phase 1 GDD load fails at the Glob step.
- Skill STOPs with message: "No combat design document found. Create one at `design/gdd/combat.md` before running balance-sim."
- No Tasks are spawned. No report is written.

**Assertions:**
- STOP message is surfaced verbatim (as documented).
- Skill does not proceed to Phase 2.
- No file writes occur.
- No AskUserQuestion is issued about the GDD — the STOP is unconditional when no GDD is found.

**Verdict:** BLOCKED

---

### Case 3: Mode Variant — High VOID Rate

**Fixture:** Combat GDD exists but is sparse; many rules are missing. Player agents return a mix of valid fights and VOID fights, resulting in a VOID rate above 10%.

**Expected behavior:**
- Phase 3 computes VOID rate > 10% and classifies confidence as LOW.
- Statistics are computed over valid fights only; VOID count reported separately.
- Phase 4 referee receives VOID rate in prompt.
- Report header appends: "⚠️ LOW CONFIDENCE — resolve GDD gaps before acting on these recommendations."
- "GDD Gaps (VOID causes)" section in report lists each voided rule gap.
- Phase 5 "May I write" gate still fires normally.

**Assertions:**
- LOW confidence flag appears in report header.
- VOID rate triggers "GDD coverage gap" flag in Phase 3.
- Recommendations section in referee output flags ambiguous rules as gaps needing clarification.
- File is still written on approval (LOW confidence does not STOP the skill).

**Verdict:** COMPLETE (with LOW confidence warning)

---

### Case 4: Edge Case — 3+ Ambiguous Rules

**Fixture:** Combat GDD exists and has stat values, but has 3 or more rules that the skill identifies as ambiguous during Phase 1 rule extraction.

**Expected behavior:**
- Phase 1 lists all ambiguous rules in the documented format: "⚠️ Ambiguous rule: [text]. Interpretation used: [interpretation]. Alternative: [other reading]."
- Because 3+ rules are ambiguous, skill pauses and uses `AskUserQuestion` to resolve the critical ones before proceeding.
- If user resolves them: simulation proceeds with updated interpretations; confidence may be MEDIUM or HIGH depending on VOID rate.
- If user leaves 3+ unresolved: simulation runs with conservative interpretations; report marked LOW confidence.

**Assertions:**
- AskUserQuestion fires on 3+ ambiguities (not on 1–2, which are silently resolved conservatively).
- Conservative interpretation is applied and noted for any unresolved ambiguity.
- Ambiguities passed into player agent prompt under "Ambiguity Notes" section.
- Referee receives the ambiguity list in its prompt.
- "Ambiguous Rules Encountered" section in written report is populated.

**Verdict:** COMPLETE or BLOCKED depending on user resolution

---

### Case 5: Most Relevant Variant — All Fights VOID

**Fixture:** Combat GDD exists but is fundamentally incomplete for the requested matchup (e.g., no win condition defined, or no damage rules). Every fight returned by player agents is marked VOID.

**Expected behavior:**
- Phase 3: all fights are VOID; valid_fights = 0.
- Graceful Degradation table: "All fights VOID" → STOP — "GDD rules insufficient to simulate this matchup. Specify: [list missing rules]."
- Skill does not proceed to Phase 4 or Phase 5.
- No report is written.
- Missing rules are enumerated in the STOP message.

**Assertions:**
- Skill STOPs rather than writing an empty or nonsensical report.
- STOP message enumerates the specific rule categories that are missing (not a generic error).
- No "May I write" prompt is issued.
- No referee Task is spawned.

**Verdict:** BLOCKED

---

## Protocol Compliance

- [ ] "May I write" before file writes — Phase 5 explicitly gates the write behind "May I write `production/balance/sim-[scenario]-[date].md`? [Y/N]"
- [ ] Presents findings before approval — Phase 3 statistics and Phase 4 referee analysis are completed before the Phase 5 write gate
- [ ] Ends with next step — "Recommended Next Steps" section concludes with `/balance-check`, `/consistency-check`, and re-run instructions
- [ ] No auto-create without approval — `production/balance/` directory creation and file write both conditional on user Y response in Phase 5

---

## Coverage Notes

- **AN1**: Phases 1 through 4 use only Read, Glob, Grep (scan), and Task (subagents). Write is deferred to Phase 5 and gated. No Write or Edit during analysis scan phases.
- **AN2**: Phase 3 produces a statistics table with 9 metrics and a balance classification (Balanced / Slight / Moderate / Severe imbalance) with explicit thresholds. Design Recommendations in the referee output include per-recommendation priority (High/Medium/Low). Confidence level (HIGH/MEDIUM/LOW) provides a meta-severity indicator.
- **AN3**: The single Write call (report file) is gated behind an explicit "May I write" prompt in Phase 5.
- **AN4**: No director gate invocations anywhere in the skill. The Phase 4 "referee" is a Task-spawned subagent, not a director gate skill.