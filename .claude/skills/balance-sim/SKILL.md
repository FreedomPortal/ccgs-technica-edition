---
name: balance-sim
description: AI-vs-AI combat simulation for games with rule-based combat systems. Spawns parallel Haiku player agents to run N iterations of a matchup, then a Sonnet referee to aggregate statistics and produce a four-section balance report. Simulates GDD rules, not engine code — discrepancies between GDD and implementation are a signal, not an error. Output: production/balance/sim-[scenario]-YYYY-MM-DD.md
model: sonnet
argument-hint: "[scenario] [--iterations N] — e.g. /balance-sim base-vs-heavy --iterations 200"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Task, AskUserQuestion
---

# /balance-sim

Simulates a combat matchup using the game's rules as documented in the GDD. Produces statistical balance findings and actionable design recommendations.

**What this simulates:** Rules as written in GDDs and ADRs. Not engine code.
**What it is not:** An engine test runner or regression suite — use GUT tests for that.
**Discrepancy signal:** If simulation outcomes diverge from observed in-game behavior, the GDD and implementation disagree — that is the finding worth investigating.

**Output:** `production/balance/sim-[scenario]-[YYYY-MM-DD].md`

---

## Phase 1 — Configuration

**Arguments:**
- `$ARGUMENTS[0]` — scenario name (e.g. `base-vs-heavy`, `synergy-test`, `full-roster`)
- `--iterations N` — number of simulated fights (default: 200; min: 50; max: 500)

If no scenario argument: use `AskUserQuestion`:
- Prompt: "What matchup do you want to simulate?"
- Options: list builds/archetypes from the combat GDD, or `[E] Enter custom matchup`

### Load combat rules

Read the following files (all required):
1. **Combat GDD** — glob `design/gdd/*combat*.md` or `design/gdd/*battle*.md`; if multiple, ask which to use
2. **Balance values** — look for a data file or balance section in the combat GDD (formulas, stat tables, HP values, attack values, speed, modifiers)

If combat GDD not found: STOP — "No combat design document found. Create one at `design/gdd/combat.md` before running balance-sim."

### Identify simulatable parameters

From the GDD, extract:
- HP values per build/archetype
- Attack values (base damage, modifiers)
- Speed / initiative values
- Defense / resistance values
- Special ability rules (triggers, costs, effects)
- Win condition (KO, timeout at N turns, etc.)
- Any probability/RNG rules (note: simulated deterministically via seeded sequences)

List ambiguous rules explicitly:
> "⚠️ Ambiguous rule: [rule text]. Interpretation used: [interpretation]. Alternative: [other reading]."

If 3+ rules are ambiguous: pause and use `AskUserQuestion` to resolve the critical ones before proceeding. Low-stakes ambiguities: choose the more conservative interpretation and note it.

### Define matchup

For each side of the matchup, specify:
- Build/archetype name
- Stat values (from GDD or user input)
- Special ability if any

---

## Phase 2 — Parallel Player Agent Spawn

Spawn **N parallel player agent pairs** via Task. Each pair simulates one fight.

**Iteration batching:** To stay within token limits, batch iterations:
- 50 iterations: 1 batch of 50 (single Task with 50-fight instruction)
- 100 iterations: 2 batches of 50
- 200 iterations: 4 batches of 50
- 500 iterations: 10 batches of 50

Issue all batches **simultaneously** — do not wait for one before starting the next.

### Player agent prompt template

Each player agent Task receives:

```
You are a combat simulator executing a rule-based fight.

## Rules (do not deviate from these)
[Full combat rules extracted in Phase 1]

## Matchup
Side A: [build name] — HP: [N], ATK: [N], SPD: [N], [any specials]
Side B: [build name] — HP: [N], ATK: [N], SPD: [N], [any specials]

## Your Task
Simulate [N] fights using these rules exactly. For each fight:
1. Alternate turns by initiative (higher SPD goes first; ties: Side A goes first)
2. Apply damage, specials, and any modifiers per the rules
3. Record: winner (A/B/draw), number of turns, final HP of winner

If any rule is ambiguous, use the interpretation listed in the "Ambiguity notes" below.
If a rule is missing (situation not covered by the GDD), record the fight as VOID and describe the gap.

## Ambiguity Notes
[List from Phase 1]

## Output Format (REQUIRED — do not deviate)
Return ONLY a JSON array. No explanation, no prose.
[
  {"fight": 1, "winner": "A", "turns": 8, "winner_hp": 45, "void": false, "void_reason": null},
  {"fight": 2, "winner": "B", "turns": 12, "winner_hp": 12, "void": false, "void_reason": null},
  ...
]
```

**Model for player agents:** `haiku` — rule-following execution, no creative judgment needed.

---

## Phase 3 — Aggregate Statistics

Collect all batch results. Merge into a single dataset. Discard VOID fights from statistical calculations; count and report them separately.

Compute:

| Statistic | Formula |
|-----------|---------|
| Win rate A | `wins_A / valid_fights × 100` |
| Win rate B | `wins_B / valid_fights × 100` |
| Draw rate | `draws / valid_fights × 100` |
| Avg fight duration | `mean(turns)` across all valid fights |
| Duration std dev | `std_dev(turns)` |
| Avg winner HP | `mean(winner_hp)` — proxy for dominance margin |
| HP std dev | `std_dev(winner_hp)` |
| KO rate | `fights ending in HP ≤ 0 / valid_fights` — if win condition is timeout, separate |
| Timeout rate | `fights reaching turn limit / valid_fights` |
| VOID rate | `void_fights / total_fights` |

**Balance thresholds:**

| Win rate range | Classification |
|----------------|---------------|
| 48%–52% | Balanced |
| 40%–47% or 53%–60% | Slight imbalance |
| 30%–39% or 61%–70% | Moderate imbalance |
| < 30% or > 70% | Severe imbalance |

If VOID rate > 10%: flag as "GDD coverage gap" — simulation confidence is LOW regardless of other results.

---

## Phase 4 — Referee Analysis

After collecting all batch results, spawn a single **referee** subagent via Task.

**Model for referee:** `sonnet`

**Referee prompt:**

```
You are a game balance referee analyzing combat simulation results.

## Simulation Data
Scenario: [name]
Matchup: [Side A build] vs [Side B build]
Iterations: [N valid] of [N total] ([VOID count] voided)
Rules source: [GDD path]

## Statistics
Win rate A: [N]%
Win rate B: [N]%
Draw rate: [N]%
Avg fight duration: [N] turns (σ=[N])
Avg winner HP: [N] (σ=[N])
KO rate: [N]% | Timeout rate: [N]%
VOID rate: [N]%

## Ambiguities Encountered
[List from Phase 1]

## Your Task
Produce a four-section balance report using this exact structure:

### Game Flow Reconstruction
Describe the typical fight arc: how fights tend to open, what the mid-game looks like,
and how they end. Use the statistical data to characterize the pattern, not a single example.

### Strategic Observations
What does the winning build do that the losing build cannot match?
What mechanics feel dominant? What feels irrelevant or underused?
Identify any degenerate patterns (e.g. "Side A wins on turn 2 before Side B can act").

### Balance Assessment
For each parameter (HP, ATK, SPD, specials): assess its contribution to the outcome.
Classify the matchup using the balance thresholds.
Flag any parameters that are outliers relative to their design intent.

### Design Recommendations
One recommendation per identified imbalance. Format:
- **Change [parameter]** from [current value] to [suggested range] — because [statistical evidence]. Priority: High/Medium/Low.
Do not suggest changes without statistical grounding. Flag ambiguous rules as gaps
that need clarification before further simulation.
```

Collect referee output.

---

## Phase 5 — Write Report

Ask: "May I write `production/balance/sim-[scenario]-[date].md`? [Y/N]"

On approval, create `production/balance/` if needed, then write:

```markdown
# Balance Simulation: [Scenario]
Date: [YYYY-MM-DD] | Iterations: [N valid] / [N total] | Confidence: [HIGH/MEDIUM/LOW]
Rules source: [GDD path]
Side A: [build name] | Side B: [build name]

## Statistics

| Metric | Value |
|--------|-------|
| Win rate A | [N]% |
| Win rate B | [N]% |
| Draw rate | [N]% |
| Balance class | [Balanced / Slight / Moderate / Severe imbalance] |
| Avg fight duration | [N] turns (σ=[N]) |
| Avg winner HP | [N] (σ=[N]) |
| KO rate | [N]% |
| Timeout rate | [N]% |
| VOID rate | [N]% ([N] fights voided — GDD gaps) |

Confidence: HIGH (VOID rate < 5%) / MEDIUM (5–10%) / LOW (> 10% or < 3 iterations per scenario)

---

[Referee four-section output verbatim]

---

## Ambiguous Rules Encountered
[List each ambiguity, interpretation used, and alternative interpretation]
[Or: "None — all rules unambiguous"]

## GDD Gaps (VOID causes)
[List each rule gap that caused a VOID, with the exact situation that triggered it]
[Or: "None"]

## Replication Notes
Rules source: [GDD path] at [date]
Interpretation choices: [list non-obvious ones]
To re-run: `/balance-sim [scenario] --iterations [N]`
```

---

## Confidence Levels

| Condition | Confidence |
|-----------|-----------|
| VOID rate < 5%, N ≥ 100 | HIGH |
| VOID rate 5–10%, or N 50–99 | MEDIUM |
| VOID rate > 10%, or N < 50, or 3+ unresolved ambiguities | LOW |

LOW confidence: always append to report header — "⚠️ LOW CONFIDENCE — resolve GDD gaps before acting on these recommendations."

---

## Graceful Degradation

| Condition | Behavior |
|-----------|----------|
| No combat GDD | STOP with helpful error |
| GDD has no stat values | Ask user to provide them manually; proceed |
| 3+ ambiguous rules unresolved | Run simulation with conservative interpretations; mark LOW confidence |
| All fights VOID | STOP — "GDD rules insufficient to simulate this matchup. Specify: [list missing rules]." |
| Batch agent returns non-JSON | Discard batch; note in VOID count; continue with remaining batches |
