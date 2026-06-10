---
name: ab-test
description: "Design, review, or log A/B tests. Three modes: design (create a test spec), review (statistical significance analysis of results), log (record concluded test outcome). Produces docs/analytics/ab-tests/[slug]-spec.md, docs/analytics/ab-tests/[slug]-review.md, or appends to docs/analytics/ab-test-log.md."
argument-hint: "[design|review|log] [test-slug]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit, Task
---

When this skill is invoked:

## Phase 1: Determine Mode

If the user provided an argument with mode (`design`, `review`, `log`), use it.
Otherwise:

Use `AskUserQuestion`:
- Prompt: "What would you like to do?"
- Options:
  - `Design a new test` — Create an A/B test spec before running the test
  - `Review test results` — Analyze results for statistical significance
  - `Log concluded test` — Record the outcome of a finished test

Route to the appropriate phase based on mode.

---

## DESIGN MODE

### Design Phase 1: Understand the Hypothesis

Ask the user:
- What feature, mechanic, or copy are you testing?
- What do you believe variant B will do differently than control A?
- What is the single primary metric that defines success?

Use `AskUserQuestion`:
- Prompt: "What is the primary metric for this test?"
- Options:
  - `D7 retention rate` — % of players returning on Day 7
  - `Session length` — Average session duration
  - `Feature adoption rate` — % of players using a specific feature
  - `Conversion rate` — % completing a specific action (purchase, tutorial, etc.)
  - `First session completion` — % finishing the first session
  - `Custom metric` — I'll describe it

If "Custom", ask for a precise definition before proceeding.

### Design Phase 2: Design the Test

Spawn the `growth-analyst` agent via Task with this prompt:

```
You are the growth-analyst for [GAME TITLE].

Design an A/B test spec for:
Feature/element being tested: [WHAT IS BEING TESTED]
Hypothesis: [WHAT THE DEVELOPER BELIEVES WILL CHANGE]
Primary metric: [METRIC FROM PHASE 1]
Game genre: [GENRE FROM game-concept.md]
Active playerbase (if known): [ESTIMATE, or "unknown"]

Produce a complete A/B test spec:

1. Test Identity
   - Test name: [descriptive slug]
   - Hypothesis: structured as "We believe [change] will [effect] because [rationale]"
   - Control (A): exact description of current state
   - Variant (B): exact description of the change being tested

2. Metrics
   - Primary metric: [metric] — how measured, what improvement means success
   - Secondary metrics: 2–3 additional indicators to watch (should not improve at
     the expense of these — these are guardrails, not targets)
   - Antigoal metrics: anything that must NOT decline (e.g., "D7 retention must
     not drop even if primary metric improves")

3. Sample Size and Duration
   - Required sample size: calculated minimum per variant for 80% power, α = 0.05
     Use: n ≈ 16σ²/δ² for continuous metrics, or n ≈ 16p(1-p)/δ² for proportions
     where δ is the minimum detectable effect (MDE — specify a realistic MDE)
   - Expected run duration: days needed to reach sample size given estimated DAU
     If DAU is unknown, provide formula: duration = (n × 2) / DAU
   - Minimum run time: at least 2 full weeks to capture weekly behavioral cycles

4. Implementation Notes
   - Player assignment: how players are split (random, geographic, device type)
   - Segmentation exclusions: which player segments should be excluded from this test
   - Interaction risk: any other tests or live ops events that could contaminate results
   - Washout period: time to wait after ending test before acting on results (if relevant)

5. Analysis Plan
   - When to analyze: after minimum run time AND sample size is reached (both, not either)
   - Statistical test to use: two-proportion z-test (for binary outcomes) or
     Welch's t-test (for continuous outcomes)
   - Segmentation breakdown: which player segments to analyze separately in addition
     to the overall result
```

Present the spec to the user for review before writing.

### Design Phase 3: Write Spec

Ask: "May I write the test spec to `docs/analytics/ab-tests/[slug]-spec.md`?"

Wait for confirmation. Create `docs/analytics/ab-tests/` if needed.

```markdown
# A/B Test Spec — [Test Name]
**Created:** [date]
**Status:** Draft

---

## Hypothesis
[structured hypothesis from agent]

## Control vs. Variant
| | Control (A) | Variant (B) |
|-|-------------|-------------|
| Description | [A] | [B] |

## Metrics
**Primary:** [metric + success definition]
**Secondary:** [list]
**Antigoal (must not decline):** [list]

## Sample Size and Duration
- Minimum sample: [N] per variant
- MDE assumed: [%]
- Expected duration: [days] at [DAU estimate] DAU
- Minimum run time: 14 days (weekly cycle coverage)

## Implementation Notes
[from agent output]

## Analysis Plan
[from agent output]
```

Output after writing:
```
A/B Test Spec — [Test Name]
=============================
Primary metric: [metric]
Sample needed:  [N] per variant
Duration est.:  [days]
Output:         docs/analytics/ab-tests/[slug]-spec.md

Next steps:
1. Implement variant B and player assignment logic
2. Start the test — record start date in the spec file
3. Run /ab-test review [slug] after minimum run time is reached

Verdict: COMPLETE — test spec created.
```

---

## REVIEW MODE

### Review Phase 1: Load the Test

If a slug argument was provided, read `docs/analytics/ab-tests/[slug]-spec.md`.
Otherwise, list existing spec files and ask the user which test to review.

Read the spec. Extract: primary metric, secondary metrics, antigoals, minimum sample size,
minimum run time, statistical test type.

### Review Phase 2: Collect Results

Ask the user for the result data:

> "Provide the results in this format:
>
> Control (A): [N_A] players, [metric_value_A]
> Variant (B): [N_B] players, [metric_value_B]
> Run duration: [days]
> Start date: [date]

If results are already in the spec file, use those. Otherwise collect inline.

### Review Phase 3: Statistical Analysis

Spawn the `growth-analyst` agent via Task with this prompt:

```
You are the growth-analyst. Analyze these A/B test results:

Test: [NAME]
Primary metric: [METRIC]
Statistical test: [TEST TYPE FROM SPEC]
Significance threshold: α = 0.05, power target = 80%

Results:
Control (A): n = [N_A], metric = [VALUE_A]
Variant (B): n = [N_B], metric = [VALUE_B]
Run duration: [DAYS] days
Minimum required: [MIN SAMPLE SIZE] per variant, [MIN DAYS] days

Perform the following analysis:

1. Pre-analysis validity check:
   - Was minimum sample size reached? [Y/N]
   - Was minimum run time reached? [Y/N]
   - Any known contaminating events during run period? [from spec]
   If EITHER minimum is not met: flag as UNDERPOWERED — do not interpret results.

2. Statistical test (only if pre-analysis passes):
   - Calculate observed effect size: (B - A) / A as a percentage
   - Calculate p-value for the appropriate test
   - Calculate 95% confidence interval for the effect
   - State clearly: statistically significant (p < 0.05) or not significant

3. Practical significance (only if statistically significant):
   - Is the effect size meaningful for the game? (small effect on a high-volume
     funnel step can still matter; large effect on a rarely-reached event may not)
   - How does this compare to the MDE assumed in the spec?

4. Secondary metrics and antigoals:
   - Report direction (improved / neutral / declined) for each secondary metric
   - Flag any antigoal metric that declined — this is a blocking concern

5. Recommendation:
   - SHIP B: statistically significant improvement, no antigoal violations
   - DO NOT SHIP: not significant, or antigoal violated
   - EXTEND TEST: underpowered — specify additional days needed
   - INVESTIGATE: significant result but secondary metrics raise concerns

6. Segment breakdown notes:
   - If result differs significantly across segments listed in the spec, call it out
   - Do not slice more segments than the spec defined — avoid p-hacking
```

Present results to user.

### Review Phase 4: Write Review

Ask: "May I write the review to `docs/analytics/ab-tests/[slug]-review.md`?"

Wait for confirmation.

```markdown
# A/B Test Review — [Test Name]
**Analyzed:** [date]
**Run duration:** [days]
**Recommendation:** [SHIP B / DO NOT SHIP / EXTEND TEST / INVESTIGATE]

---

## Results

| | Control (A) | Variant (B) |
|-|-------------|-------------|
| n | [N_A] | [N_B] |
| [Primary metric] | [VALUE_A] | [VALUE_B] |
| Effect | — | [+/- X%] |

**p-value:** [value]
**95% CI:** [lower, upper]
**Statistically significant:** [Yes / No]

## Secondary Metrics
[table with direction for each]

## Antigoal Check
[pass or fail for each antigoal]

## Recommendation
**[RECOMMENDATION]**

[1–3 sentence rationale]

## Next Steps
[What to do based on the recommendation]
```

Output after writing:
```
A/B Test Review — [Test Name]
================================
Result:     [significant / not significant]
Verdict:    [SHIP B / DO NOT SHIP / EXTEND TEST / INVESTIGATE]
Output:     docs/analytics/ab-tests/[slug]-review.md

Next steps: [from recommendation]
Run /ab-test log [slug] when the test is formally concluded.
```

---

## LOG MODE

### Log Phase 1: Identify Test

If a slug argument was provided, read spec and review files.
Otherwise, list concluded tests and ask which to log.

### Log Phase 2: Collect Final Outcome

Ask:
- Was variant B shipped? (Yes / No / Modified variant shipped)
- Any notes on the decision (overrides, context)?

### Log Phase 3: Append to Log

Ask: "May I append this test outcome to `docs/analytics/ab-test-log.md`?"

Wait for confirmation. Create the file if it does not exist with header:

```markdown
# A/B Test Log
Tests are logged here when formally concluded. Full specs and reviews in
`docs/analytics/ab-tests/`.

| Date | Test | Result | Decision | Notes |
|------|------|--------|----------|-------|
```

Append a row:
```
| [date] | [test-name] | [significant/not] | [shipped/not shipped] | [notes] |
```

Output: "Logged. `docs/analytics/ab-test-log.md` updated."

---

## Collaborative Protocol

- **Never write files without asking** — each mode has explicit write gates
- Statistical significance (p < 0.05) is required for a SHIP recommendation — never ship on trends
- Both minimum sample AND minimum run time must be met before analysis — not either/or
- Antigoal violations always override a positive primary metric result
- Do not add secondary segments beyond what the spec defined — prevents p-hacking
