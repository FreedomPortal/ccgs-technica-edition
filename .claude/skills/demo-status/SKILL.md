---
name: demo-status
description: "Detect the current sub-stage of one or all active demo campaigns. Advisory only — reads state.txt and cross-checks artifacts. Use when you need to know 'where is the demo at?'. Run /demo-gate to formally advance."
argument-hint: "[demo-id — omit to list all active campaigns]"
user-invocable: true
allowed-tools: Read, Glob, Grep
model: haiku
---

# Demo Track Status Detection

Advisory scan of active demo campaigns. Never writes state.txt — that is `/demo-gate`'s responsibility.

---

## Demo Sub-Stages

| # | Sub-Stage | Purpose |
|---|-----------|---------|
| 1 | **Planning** | Goals, target event, timeline, risk register defined |
| 2 | **Scoping** | Exact content list locked; content gates identified |
| 3 | **Building** | Demo build in progress; content gates implemented |
| 4 | **Playtesting** | First impression and conversion tested |
| 5 | **Evaluating** | Playtest findings synthesized; blockers identified |
| 6 | **Iterating** | Conversion blockers addressed |
| 7 | **Polishing** | Final polish pass; smoke check |
| 8 | **Released** | Demo live on target platform |
| 9 | **Publishing** | *(Early Access only)* EA store page live, pricing set, roadmap communicated |
| 10 | **Live** | *(Early Access only)* EA launched, players active |

---

## Workflow

### 1. Resolve Target Campaign(s)

If `$ARGUMENTS[0]` is provided:
- Look for `production/demo/[demo-id]/state.txt`
- If not found: report "No demo campaign found with ID '[demo-id]'. Run `/demo-plan` to create one."
- Stop.

If no argument:
- Glob `production/demo/*/state.txt`
- If no files found:
  > No active demo campaigns found. Run `/demo-plan` to start a new demo campaign.
  - Stop.
- List all found campaigns. Process each one.

---

### 2. For Each Campaign: Read State

For each campaign at `production/demo/[id]/`:

1. **Read state.txt** — current sub-stage value
   - If file exists → confidence = HIGH
   - If file missing → infer from artifacts (confidence = MEDIUM)

2. **Check for Early Access mode:**
   - Read `production/demo/[id]/demo-plan.md` if it exists
   - Look for `--early-access` flag or `Early Access: true` in plan header
   - If EA mode active: include sub-stages 9 (Publishing) and 10 (Live) in the stage table

---

### 3. Artifact Cross-Check

For the detected sub-stage, verify expected artifacts exist:

| Sub-Stage | Expected Artifacts |
|-----------|-------------------|
| Planning | `production/demo/[id]/demo-plan.md` or `design/demo/demo-plan.md` |
| Scoping | `design/demo/demo-scope.md` or `production/demo/[id]/demo-scope.md` |
| Building | Any build report or build log in `production/demo/[id]/` |
| Playtesting | ≥1 playtest file in `production/playtests/` or `production/demo/[id]/playtests/` referencing this demo |
| Evaluating | Evaluation or feedback synthesis doc in `production/demo/[id]/` |
| Iterating | Iteration task list or sprint stories referencing this demo |
| Polishing | Polish pass sign-off or smoke check in `production/demo/[id]/` |
| Released | Release record or go-live confirmation in `production/demo/[id]/` |
| Publishing | Store page live confirmation; EA roadmap doc |
| Live | Launch announcement record |

If artifacts are consistent with state.txt → note as **confirmed**.
If artifacts are missing for the reported sub-stage → flag as **discrepancy** and lower confidence to LOW.

---

### 4. Report Output

For each campaign:

```
## Demo Campaign: [demo-id]
**Sub-Stage**: [current sub-stage]
**Confidence**: [HIGH | MEDIUM | LOW]
**Early Access**: [Yes | No]

### Artifacts
- [x] demo-plan.md — found
- [ ] demo-scope.md — MISSING (expected at Scoping+)
...

### Status Verdict
[COMPLIANT — artifacts match sub-stage]
[NON-COMPLIANT — state.txt says X but artifact Y is missing]

### Blockers for Next Advance
1. [Specific artifact or action blocking advance to next sub-stage]
2. ...

### Next Step
Run `/demo-gate [demo-id] [next-sub-stage]` to formally advance.
```

If multiple campaigns exist, show a summary table first, then detailed reports per campaign.

---

## Protocol Compliance

- Never writes state.txt or any file
- Always reports confidence level (HIGH / MEDIUM / LOW)
- Cross-checks state.txt against artifacts; flags discrepancies
- Ends with a next-step recommendation (`/demo-gate` to formally advance)
