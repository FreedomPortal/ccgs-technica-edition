---
name: post-mortem
description: "Structured retrospective after a milestone or stage transition. Covers what went well, what went wrong, scope creep analysis, time estimate accuracy, and one concrete process change. Output: production/postmortems/[milestone]-[date].md. Kept short — no ceremony for a solo developer."
argument-hint: "[milestone or stage name] (e.g., 'pre-production', 'alpha', 'sprint-3')"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit, Task
---

When this skill is invoked:

## Phase 1: Detect Context

Parse the argument if provided (e.g., `/post-mortem pre-production`). Store as `[MILESTONE]`.

If no argument provided, use `AskUserQuestion`:
- Prompt: "Which milestone or stage are we doing a post-mortem for?"
- Options:
  - `Concept` — design phase complete, gate passed
  - `Systems Design` — all GDDs authored and reviewed
  - `Architecture` — ADRs and control manifest complete
  - `Pre-Production` — prototype validated, epics and stories created
  - `Alpha` — core loop implemented, first playable
  - `Beta` — feature-complete build
  - `Release` — shipped
  - `Sprint [N]` — specific sprint retrospective (I'll type it below)

Read the following to gather evidence before spawning any agents:
- `.claude/docs/technical-preferences.md` — engine name, version, language, team size
- `production/stage.txt` — current stage
- `production/milestones/*.md` — milestone definitions and goals
- `production/sprints/` — sprint files for the period covered (Glob `production/sprints/*.md`)
- `production/gate-checks/` — gate check reports for the milestone (Glob `production/gate-checks/*.md`)
- `production/postmortems/` — prior post-mortems for comparison (Glob `production/postmortems/*.md`)
- `production/session-logs/` — session logs if available (Glob `production/session-logs/*.md`)

Summarize internally what was planned vs. what was delivered before spawning.

---

## Phase 2: Spawn Producer

Spawn the `producer` agent via Task with this prompt, substituting what was read:

```
You are the producer for [GAME TITLE] ([ENGINE] [ENGINE_VERSION], [TEAM_SIZE]).
Milestone under review: [MILESTONE]

Evidence gathered from the project:
- Stage: [CURRENT STAGE]
- Milestone goals (planned): [SUMMARY FROM MILESTONE FILES]
- Sprints completed: [LIST OF SPRINT FILES READ]
- Gate check results: [SUMMARY FROM GATE CHECK FILES]
- Prior post-mortems: [TITLES IF ANY]

Write a post-mortem for this milestone. Keep it under 2 pages total.
It must be actionable, not ceremonial — this is a solo developer.

Structure:

1. What Was Planned
   - Original goals for this milestone (from milestone definition)
   - Scope at the start

2. What Was Delivered
   - What actually shipped or was completed
   - Scope at the end

3. Scope Creep Analysis
   - What was added that wasn't in the original plan?
   - What was cut and why?
   - Net scope delta: bigger, smaller, or roughly on target?

4. What Went Well (3–5 items max)
   - Be specific. "The auto-battle prototype validated the core loop" not "prototyping went well"

5. What Went Wrong (3–5 items max)
   - Be specific. Include root causes, not just symptoms.

6. Time Estimate Accuracy
   - Were estimates close? Where did underestimation happen?
   - Pattern: systemic or one-off?

7. Technical Decisions — Verdict
   - Name 2–3 key technical decisions made this milestone
   - For each: paid off / neutral / cost us time — and why

8. One Concrete Process Change
   - ONE change to implement next milestone that addresses the biggest pain point
   - Must be actionable and testable (you can tell if it worked next post-mortem)

9. Carry-Forward Items
   - What was explicitly deferred to next milestone? (Not failures — deliberate deferrals)

Format as a structured markdown document. Do not write any game code.
```

After the agent completes, present the post-mortem to the user for review before writing.

---

## Phase 3: Write Post-Mortem

Ask: "May I write the post-mortem to `production/postmortems/[MILESTONE]-[DATE].md`?"

Wait for confirmation before writing.

Create `production/postmortems/` if it does not exist.

Filename format: `[milestone-slug]-[YYYY-MM-DD].md`
- `pre-production` → `pre-production-2026-04-12.md`
- `sprint-3` → `sprint-3-2026-04-12.md`

Write the file with this structure:

```markdown
# Post-Mortem — [Milestone]
**Date:** [date]
**Stage at close:** [stage]
**Duration:** [start date] → [end date if known]

---

## What Was Planned

[Section 1 from agent]

---

## What Was Delivered

[Section 2 from agent]

---

## Scope Creep Analysis

[Section 3 from agent]

---

## What Went Well

[Section 4 from agent]

---

## What Went Wrong

[Section 5 from agent]

---

## Time Estimate Accuracy

[Section 6 from agent]

---

## Technical Decisions — Verdict

[Section 7 from agent]

---

## One Concrete Process Change

**[The one concrete change — bolded; this is the most important output]**

[Section 8 from agent]

---

## Carry-Forward Items

[Section 9 from agent]
```

---

## Phase 4: Summary

After writing, output:

```
Post-Mortem — [Milestone]
==========================
Covered:        [milestone name]
Output:         production/postmortems/[filename]
Process change: [the one concrete change — repeat it here]

Next steps:
1. Add the process change to your next sprint plan or milestone definition
2. Review carry-forward items when planning the next milestone
3. Run /milestone-review to track progress against the next milestone's goals

Verdict: COMPLETE — post-mortem written.
```

---

## Collaborative Protocol

- **Never write files without asking** — Phase 3 requires explicit approval before any write
- The producer agent writes the post-mortem content — always present it for review before writing to disk
- **Keep it short**: if the agent output exceeds 2 pages, ask the producer to trim. The value is in the process change and root causes, not length
- The "One Concrete Process Change" is the most important output — if the agent produces a vague or unmeasurable change (e.g., "communicate better"), ask it to make the change specific and testable
- If no milestone data exists (no milestone files, no sprint files, no gate check): proceed with what the user describes verbally — ask them to summarize what was planned and what was delivered before spawning the agent
