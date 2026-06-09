---
name: playtest-report
description: "Generates a structured playtest report template or analyzes existing playtest notes into a structured format. Use this to standardize playtest feedback collection and analysis."
argument-hint: "[new|analyze path-to-notes] [--review full|lean|solo]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Task, AskUserQuestion
model: sonnet
---

## Phase 1: Parse Arguments

Resolve the review mode (once, store for all gate spawns this run):
1. If `--review [full|lean|solo]` was passed → use that
2. Else read `production/review-mode.txt` → use that value
3. Else → default to `lean`

See `.claude/docs/director-gates.md` for the full check pattern.

Determine the mode:

- `new` → generate a blank playtest report template
- `analyze [path]` → read raw notes and fill in the template with structured findings

---

## Phase 2A: New Template Mode

Generate this template and output it to the user:

```markdown
# Playtest Report

## Session Info
- **Date**: [Date]
- **Build**: [Version/Commit]
- **Duration**: [Time played]
- **Tester**: [Name/ID]
- **Platform**: [PC/Console/Mobile]
- **Input Method**: [KB+M / Gamepad / Touch]
- **Session Type**: [First time / Returning / Targeted test]

## Test Focus
[What specific features or flows were being tested]

## First Impressions (First 5 minutes)
- **Understood the goal?** [Yes/No/Partially]
- **Understood the controls?** [Yes/No/Partially]
- **Emotional response**: [Engaged/Confused/Bored/Frustrated/Excited]
- **Notes**: [Observations]

## Game Flow Reconstruction
[Chronological summary: what happened, in what order, at what moments did gameplay diverge from expected patterns. Describe the arc of the session — not just what was observed, but *when* and *in what sequence*.]

- [T+0:00] [event / observation]
- [T+X:XX] [moment of divergence from expected path]

## Strategic Observations
[What strategies worked, what was ignored, what felt dominant, what felt useless. Include what the player *tried* vs what the design *intended*.]

- **Dominant strategies**: [what the player gravitated toward and why]
- **Ignored systems**: [what was skipped or overlooked]
- **Surprising behavior**: [emergent strategies the design did not anticipate]

## Balance Assessment
[Per-system: for each major system (combat, economy, progression, etc.) — what felt over/under-tuned and why. Ground in specific observations, not general impressions.]

### [System 1 — e.g. Combat]
- **Feels**: [Over-powered / Balanced / Under-powered]
- **Evidence**: [specific moment that supports this]
- **Suspected cause**: [formula, value, or rule that drove this]

### [System 2 — e.g. Economy]
...

## Design Recommendations
[Specific, actionable: change X because observed Y. One recommendation per observed problem. No vague suggestions — every entry must name the thing to change and the evidence for changing it.]

1. **[Change X]** — because [observed Y]. Priority: [High/Medium/Low]
2. **[Change X]** — because [observed Y]. Priority: [High/Medium/Low]

## Bugs Encountered
| # | Description | Severity | Reproducible |
|---|-------------|----------|-------------|

## Quantitative Data (if available)
- **Deaths**: [Count and locations]
- **Time per area**: [Breakdown]
- **Items used**: [What and when]
- **Features discovered vs missed**: [List]

## Overall Assessment
- **Would play again?** [Yes/No/Maybe]
- **Difficulty**: [Too Easy / Just Right / Too Hard]
- **Pacing**: [Too Slow / Good / Too Fast]
```

---

## Phase 2B: Analyze Mode

Read the raw notes at the provided path. Cross-reference with existing design documents. Fill in the template above with structured findings. Flag any playtest observations that conflict with design intent.

**Required output for all four analysis sections:**

1. **Game Flow Reconstruction** — reconstruct the session timeline chronologically. Do not describe what the tester *said*, describe what *happened* and *when*.
2. **Strategic Observations** — identify strategies used vs strategies intended. Cross-reference the game's core loop (from `design/gdd/game-concept.md` if available) to identify divergences.
3. **Balance Assessment** — for each system mentioned in the notes, classify as over/balanced/under-tuned. Cite the specific observation. If balance data can be cross-referenced against formulas in the GDD, do so.
4. **Design Recommendations** — one recommendation per observed problem. Each must name: the thing to change, the evidence, the priority. Vague entries ("improve pacing") are not acceptable — rewrite until specific.

---

## Phase 3: Action Routing

Categorize all findings into four buckets:

- **Design changes needed** — fun issues, player confusion, broken mechanics, observations that conflict with the GDD's intended experience
- **Balance adjustments** — numbers feel wrong, difficulty too spiked or too flat
- **Bug reports** — clear implementation defects that are reproducible
- **Polish items** — not blocking progress, but friction or feel issues for later

Present the categorized list, then route:

- **Design changes:** "Run `/propagate-design-change [path]` on the affected design document to find downstream impacts before making changes."
- **Balance adjustments:** "Run `/balance-check [system]` to verify the full balance picture before tuning values."
- **Bugs:** "Use `/bug-report` to formally track these."
- **Polish items:** "Add to the polish backlog in `production/` when the team reaches that phase."

---

## Phase 3b: Creative Director Player Experience Review

**Review mode check** — apply before spawning CD-PLAYTEST:
- `solo` → skip. Note: "CD-PLAYTEST skipped — Solo mode." Proceed to Phase 4 (save the report).
- `lean` → skip (not a PHASE-GATE). Note: "CD-PLAYTEST skipped — Lean mode." Proceed to Phase 4 (save the report).
- `full` → spawn as normal.

After categorising findings, spawn `creative-director` via Task using gate **CD-PLAYTEST** (`.claude/docs/director-gates.md`).

Pass: the structured report content, game pillars and core fantasy (from `design/gdd/game-concept.md`), the specific hypothesis being tested.

Present the creative director's assessment before saving the report. If CONCERNS or REJECT, add a `## Creative Director Assessment` section to the report capturing the verdict and feedback. If APPROVE, note the approval in the report.

---

## Phase 4: Save Report

Ask: "May I write this playtest report to `production/qa/playtests/playtest-[date]-[tester].md`?"

If yes, write the file, creating the directory if needed.

---

## Phase 5: Next Steps

Verdict: **COMPLETE** — playtest report generated.

- Act on the highest-priority finding category first.
- After addressing design changes: re-run `/design-review` on the updated GDD.
- After fixing bugs: re-run `/bug-triage` to update priorities.
