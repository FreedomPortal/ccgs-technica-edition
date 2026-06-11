# Skill Spec: /ab-test

> **Category**: analytics
> **Priority**: high
> **Spec written**: 2026-06-11

## Skill Summary

`/ab-test` is a three-mode analytics skill for managing the full lifecycle of A/B tests. In **design** mode, it collects a hypothesis and primary metric from the user, spawns a `growth-analyst` subagent to produce a rigorous test spec (including sample size calculations, implementation notes, and an analysis plan), presents the spec for review, then writes it to `docs/analytics/ab-tests/[slug]-spec.md` upon approval. In **review** mode, it loads an existing spec, collects result data from the user, spawns the `growth-analyst` to perform a full statistical analysis (pre-analysis validity check, p-value, confidence interval, practical significance, antigoal check, and a recommendation from a fixed set: SHIP B / DO NOT SHIP / EXTEND TEST / INVESTIGATE), presents the analysis, then writes a review document upon approval. In **log** mode, it identifies a concluded test, asks for the final decision, then appends a single row to `docs/analytics/ab-test-log.md` upon approval. All three modes gate every file write behind an explicit "May I write" prompt.

---

## Static Assertions
- [x] Frontmatter has all required fields (`name`, `description`, `argument-hint`, `user-invocable`, `allowed-tools`)
- [x] 2+ phase headings found (Design Phase 1–3, Review Phase 1–4, Log Phase 1–3 — nine phase headings total)
- [x] At least one verdict keyword present (`Verdict: COMPLETE — test spec created.` and `Verdict: COMPLETE — A/B test updated.`)
- [x] If `allowed-tools` includes Write/Edit: `"May I write"` language present (Design Phase 3, Review Phase 4, Log Phase 3 all use explicit "May I write" / "May I append" language)
- [x] Next-step handoff section present at end (## Recommended Next Steps section lists `/ab-test review`, `/ab-test log`, and `/retention-analysis`)

---

## Director Gate Checks
- **Full mode**: N/A
- **Lean mode**: N/A
- **Solo mode**: N/A
- **N/A**: This skill does not reference director gate reviews in any mode. No gate-check or approval-tier escalation is triggered.

---

## Test Cases

### Case 1: Happy Path — Design mode end-to-end
**Fixture**: User invokes `/ab-test design` with no pre-existing files. Game concept file exists at `docs/game-concept.md` with genre info. User answers: testing onboarding tutorial skip button; hypothesis is that offering a skip will increase first-session completion; primary metric is "First session completion"; provides realistic DAU estimate.

**Expected behavior**:
- Phase 1 resolves to design mode without prompting (argument provided).
- Design Phase 1 asks about feature, hypothesis, and primary metric via `AskUserQuestion`; user selects "First session completion" from the options list.
- Design Phase 2 spawns `growth-analyst` Task with all collected context populated (game title, what is being tested, hypothesis, metric, genre, DAU). Agent returns a complete spec covering all five numbered sections (Test Identity, Metrics, Sample Size and Duration, Implementation Notes, Analysis Plan). Spec is presented to user before any write.
- Design Phase 3 asks "May I write the test spec to `docs/analytics/ab-tests/[slug]-spec.md`?" and waits for user confirmation before writing.
- After write, outputs the structured summary block with primary metric, sample size, duration estimate, file path, and three next-step lines. Ends with `Verdict: COMPLETE — test spec created.`

**Assertions**:
- AL1: growth-analyst prompt is populated with real values collected from the user; no fabricated numbers appear in the prompt template fields.
- AL2: Sample size formula is explicitly stated in the agent prompt (`n ≈ 16p(1-p)/δ²` for proportions); MDE is required to be specified by the agent, not assumed silently.
- AL3: Output spec contains a structured Control vs. Variant table, a Metrics section with primary/secondary/antigoal, and a Sample Size and Duration section with discrete values.
- AL4: Write is gated — Phase 3 explicitly asks "May I write" before calling Write tool.
- AL5: Summary output names next skill: `/ab-test review [slug]`.

**Case Verdict**: PASS

---

### Case 2: Failure / Blocked — Review mode with underpowered data
**Fixture**: User invokes `/ab-test review tutorial-skip`. Spec file exists at `docs/analytics/ab-tests/tutorial-skip-spec.md` with minimum sample size 1,500 per variant and minimum run time 14 days. User provides results: Control n=600, Variant n=580, run duration=7 days.

**Expected behavior**:
- Review Phase 1 reads the spec file and extracts minimum sample size (1,500), minimum run time (14 days), and statistical test type.
- Review Phase 2 collects the result data from the user (or reads from spec if present there).
- Review Phase 3 spawns `growth-analyst` Task. The agent's pre-analysis validity check (step 1) detects both failures: sample not met (600 < 1,500) and run time not met (7 < 14). Agent flags result as UNDERPOWERED and does not calculate p-values or interpret results.
- Agent recommendation is EXTEND TEST with additional days specified.
- Review Phase 4 asks "May I write the review to `docs/analytics/ab-tests/tutorial-skip-review.md`?" before writing. Review document shows the UNDERPOWERED flag and EXTEND TEST recommendation.

**Assertions**:
- AL1: Analysis is based on the actual result numbers supplied by the user; the underpowered condition is detected from the data, not assumed.
- AL2: The agent prompt explicitly states both minimums from the spec (`[MIN SAMPLE SIZE] per variant, [MIN DAYS] days`) so the check is data-driven.
- AL3: Review document contains a results table with n values, a pre-analysis validity section, and a Recommendation section with EXTEND TEST.
- AL4: Write is gated behind "May I write" in Review Phase 4.
- AL5: Output block ends with "Run `/ab-test log [slug]` when the test is formally concluded."

**Case Verdict**: PASS

---

### Case 3: Mode Variant — Log mode appending to existing log file
**Fixture**: User invokes `/ab-test log tutorial-skip`. Spec and review files exist. `docs/analytics/ab-test-log.md` already exists with the header row and two prior entries. User confirms: variant B was shipped; no override notes.

**Expected behavior**:
- Log Phase 1 reads spec and review files since slug was provided.
- Log Phase 2 asks whether variant B was shipped and collects any decision notes.
- Log Phase 3 asks "May I append this test outcome to `docs/analytics/ab-test-log.md`?" and waits for confirmation.
- Since the file already exists, the skill does not recreate it with a new header — it appends only the new row.
- Output: `"Logged. docs/analytics/ab-test-log.md updated."`

**Assertions**:
- AL1: Logged row data (test name, result, decision) comes from the spec/review files and user input — not invented.
- AL3: The log is a structured table; each concluded test is one row with date, test, result, decision, notes columns.
- AL4: Append is gated behind explicit "May I append" prompt in Log Phase 3.
- AL5: Skill does not specify a follow-on after log output beyond the global Recommended Next Steps section (no dedicated post-log handoff in the Log Mode output block — see Coverage Notes).

**Case Verdict**: PARTIAL

---

### Case 4: Edge Case — Design mode with custom primary metric
**Fixture**: User invokes `/ab-test design`. No argument provided. User selects "Design a new test" when prompted. For primary metric, user selects "Custom metric". User provides a custom definition: "median time to first kill in PvP matches, measured in seconds."

**Expected behavior**:
- Phase 1 prompts the user since no mode argument was given.
- Design Phase 1 prompts for primary metric; user selects "Custom metric".
- Skill asks for a precise definition before proceeding (as written: "If 'Custom', ask for a precise definition before proceeding").
- User provides the custom definition. Skill then uses this definition as the metric value when populating the growth-analyst Task prompt.
- Design proceeds normally through Phases 2 and 3 with the custom metric populated correctly in the agent prompt.

**Assertions**:
- AL1: The custom metric definition entered by the user is passed through to the `growth-analyst` Task prompt; no default or substitute metric is used.
- AL2: The agent prompt still requires the agent to specify the MDE and state the appropriate statistical test (Welch's t-test is suggested for continuous outcomes like time-in-seconds).
- AL3: The resulting spec's Metrics section reflects the custom metric with the user-supplied definition.
- AL4: Write gate in Design Phase 3 still applies regardless of metric type.
- AL5: Summary output still references `/ab-test review [slug]` as the next step.

**Case Verdict**: PASS

---

### Case 5: Edge Case — Review mode antigoal violation overrides positive primary metric
**Fixture**: Spec file specifies primary metric D7 retention with antigoal "session length must not decline." User provides results: Control D7=22%, Variant D7=27% (p=0.03, statistically significant positive). However, session length declined from 8.2 min to 6.9 min (an antigoal metric).

**Expected behavior**:
- Review Phase 3 spawns `growth-analyst`. Pre-analysis validity check passes (sample and time minimums met).
- Statistical test shows significant improvement on primary metric (p=0.03 < 0.05).
- Secondary/antigoal check (step 4 of agent prompt) detects that session length — flagged as an antigoal in the spec — declined.
- Per the Collaborative Protocol: "Antigoal violations always override a positive primary metric result."
- Agent recommendation is DO NOT SHIP (not SHIP B), with rationale citing the antigoal violation.
- Review document Antigoal Check section shows FAIL for session length.

**Assertions**:
- AL1: The antigoal failure is derived from the actual result numbers the user provided, not a hypothetical.
- AL2: The agent prompt explicitly identifies antigoals from the spec and instructs the agent to "flag any antigoal metric that declined — this is a blocking concern."
- AL3: Review document contains a structured Antigoal Check section with pass/fail per antigoal, and the Recommendation section shows DO NOT SHIP.
- AL4: Write gate in Review Phase 4 still applies; review is written to file only after user confirmation.
- AL5: Output block ends with "Run `/ab-test log [slug]` when the test is formally concluded."

**Case Verdict**: PASS

---

## Protocol Compliance
- [x] Uses `"May I write"` before any file writes — all three modes have explicit write gates (Design Phase 3, Review Phase 4, Log Phase 3)
- [x] Presents findings/draft to user before requesting approval — Design Phase 2 states "Present the spec to the user for review before writing"; Review Phase 3 states "Present results to user"
- [x] Ends with a recommended next step — ## Recommended Next Steps section present; design and review mode output blocks each include explicit next-step lines
- [x] Does not auto-create files without user approval — Collaborative Protocol section states "Never write files without asking — each mode has explicit write gates"

---

## Coverage Notes

**AL5 gap in Log mode**: The Log Phase 3 output is a bare confirmation string (`"Logged. docs/analytics/ab-test-log.md updated."`) with no inline next-step recommendation. The global Recommended Next Steps section at the bottom of the skill does reference `/ab-test review` and `/ab-test log`, but these are not relevant post-log handoffs. A post-log handoff (e.g., `/retention-analysis` to validate the shipped variant) appears in the global section but is not surfaced in the Log mode output block itself. Case 3 is therefore PARTIAL on AL5.

**No mode-disambiguation for missing slug in Log mode**: Log Phase 1 says "list concluded tests and ask which to log" but does not specify what "concluded" means or which directory to glob for candidates. The skill does not instruct how to distinguish a spec-only test from a reviewed test.

**`game-concept.md` dependency undocumented**: Design Phase 2 populates the agent prompt with `[GENRE FROM game-concept.md]` but the skill does not include a phase that reads or validates this file. If it is absent, the agent prompt field will be unfilled and the agent must handle the gap on its own — the skill provides no fallback or error path.

**Review Phase 2 ambiguity**: The instruction "If results are already in the spec file, use those" is not actionable without specifying the format in which results would appear in a spec file. Spec files are written in Design mode and contain no result data by default; this clause has no defined trigger condition.

**Director gate**: This skill never triggers any director gate review, which is appropriate for its scope.