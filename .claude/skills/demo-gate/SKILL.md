---
name: demo-gate
description: "Validate readiness to advance a demo campaign to the next sub-stage. Produces a PASS/CONCERNS/FAIL verdict. On PASS, writes production/demo/[id]/state.txt. Use when 'are we ready to move the demo to the next stage' or 'pass the demo gate'."
argument-hint: "[demo-id] [target-sub-stage: scoping | building | playtesting | evaluating | iterating | polishing | released | publishing | live]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, AskUserQuestion
---

# Demo Gate Validation

Validates readiness to advance a demo campaign between sub-stages. Mirrors the `/gate-check` pattern for the main pipeline but scoped to the demo track.

---

## Demo Sub-Stages (in order)

1. **Planning** — Goals, target event, risk register
2. **Scoping** — Content list locked, gates identified
3. **Building** — Demo build in progress, gates implemented
4. **Playtesting** — Playtest sessions run
5. **Evaluating** — Findings synthesized, blockers identified
6. **Iterating** — Conversion blockers addressed
7. **Polishing** — Final polish and smoke check
8. **Released** — Demo live
9. **Publishing** *(Early Access only)* — EA store requirements met
10. **Live** *(Early Access only)* — EA launched

---

## 1. Parse Arguments

**Demo ID:** `$ARGUMENTS[0]` — required. If not provided:
- Glob `production/demo/*/state.txt`
- List active campaigns and ask user which to gate

**Target sub-stage:** `$ARGUMENTS[1]` — if omitted, read current state.txt and confirm the next transition:

Use `AskUserQuestion`:
- Prompt: "Current sub-stage: **[current]**. Running gate for [Current] → [Next]. Is this correct?"
- Options:
  - `[A] Yes — run this gate`
  - `[B] No — pick a different gate` (show full sub-stage list)

**Early Access mode:** Read `production/demo/[id]/demo-plan.md` — check for `--early-access` flag or `Early Access: true`. If EA, sub-stages 9 and 10 are available.

---

## 2. Gate Definitions

### Gate: Planning → Scoping

**Required Artifacts:**
- [ ] Demo plan exists (`production/demo/[id]/demo-plan.md` or `design/demo/demo-plan.md`)
- [ ] Plan contains: target event/window, go-live date or explicit "no deadline", team capacity

**Quality Checks:**
- [ ] Goals are measurable (testable metrics, not "make a great impression")
- [ ] Risk register has at least 2 entries
- [ ] Priority relationship is defined (demo-first / parallel / future milestone)

---

### Gate: Scoping → Building

**Required Artifacts:**
- [ ] Demo scope doc exists (`design/demo/demo-scope.md` or `production/demo/[id]/demo-scope.md`)
- [ ] Scope doc lists: included content, excluded content, expected playthrough duration

**Quality Checks:**
- [ ] Content gates are identified (what code/assets lock out non-demo content)
- [ ] Scope is achievable within the plan's timeline
- [ ] Demo does not require content that doesn't exist in the main build yet

---

### Gate: Building → Playtesting

**Required Artifacts:**
- [ ] At least one internal build has been completed (`/demo-build` run or equivalent)
- [ ] Content gates are implemented (excluded content is locked, not just skipped)
- [ ] Smoke check passed on demo build (check `production/demo/[id]/` or `production/qa/`)

**Quality Checks:**
- [ ] Demo can be played start-to-finish without hitting locked content
- [ ] Demo ends gracefully (not a crash or missing content wall)
- [ ] Platform packaging requirements are understood (store page, build format)

---

### Gate: Playtesting → Evaluating

**Required Artifacts:**
- [ ] At least 3 playtest sessions documented (`production/playtests/` or `production/demo/[id]/playtests/`)
- [ ] At least 1 session included a new player (unfamiliar with the game)

**Quality Checks:**
- [ ] Conversion signal captured: did playtesters want to wishlist or buy?
- [ ] First-impression metric tracked: did player understand what to do within 2 minutes?
- [ ] Any fun-blocker bugs (crash, soft-lock, confusion loop) are logged

---

### Gate: Evaluating → Iterating

**Required Artifacts:**
- [ ] Evaluation or feedback synthesis doc exists in `production/demo/[id]/` or `production/playtests/`
- [ ] Conversion blockers are listed and prioritized

**Quality Checks:**
- [ ] Each blocker is classified: **UX confusion** / **onboarding gap** / **pacing issue** / **technical bug** / **content gap**
- [ ] At least 1 top-priority blocker has a proposed fix
- [ ] Scope of iteration is bounded (not "redo the whole demo")

---

### Gate: Iterating → Polishing

**Required Artifacts:**
- [ ] All P1 (conversion-blocking) issues from evaluation are addressed or explicitly deferred with rationale
- [ ] At least 1 re-playtest session confirms improvements

**Quality Checks:**
- [ ] Re-playtest conversion metric improved vs. baseline
- [ ] No new conversion blockers introduced by iteration changes
- [ ] Deferred items are documented with deferral rationale recorded

---

### Gate: Polishing → Released

**Required Artifacts:**
- [ ] Polish pass complete — sign-off doc or `/demo-polish` output exists
- [ ] Final smoke check passes cleanly on release candidate build
- [ ] Demo submitted or uploaded to target platform (Steam, itch.io, etc.)

**Quality Checks:**
- [ ] Build naming and packaging meets platform requirements
- [ ] Demo duration is within event limits (Steam Next Fest: up to 2h is common)
- [ ] All placeholder/debug UI is removed or gated out
- [ ] Store page accurately describes the demo content

---

### Gate: Released → Publishing *(Early Access only)*

**Required Artifacts:**
- [ ] EA store page is live (not just drafted) with EA-specific description
- [ ] EA pricing is set and published
- [ ] EA roadmap is communicated to players (in-store or via community post)
- [ ] EA roadmap commitments are documented at `production/demo/[id]/ea-roadmap.md`

**Quality Checks:**
- [ ] EA pricing reflects current game completeness (not full 1.0 price for an early build)
- [ ] Refund policy is understood for the target platform
- [ ] `/demo-integrate` has been run — improvements from demo build are backported or tracked as stories
- [ ] `/publish-check` EA requirements satisfied

---

### Gate: Publishing → Live *(Early Access only)*

**Required Artifacts:**
- [ ] EA build is live and purchasable on store
- [ ] Launch announcement is posted to community channels
- [ ] Community support channel is active (Discord, Steam forums, or equivalent)

**Quality Checks:**
- [ ] Player feedback channel is set up and monitored
- [ ] Known issues list is published (transparency builds player trust in EA)
- [ ] Post-launch iteration plan exists (players need to know improvements are coming)

---

## 3. Run the Gate Check

For each item in the target gate:
- Use `Glob` and `Read` to verify artifacts exist and have meaningful content
- Don't just check existence — verify files have real content (not just a template header)
- For quality checks that can't be auto-verified, use `AskUserQuestion`:
  - "I can't auto-verify playtest conversion data. Did at least 3 sessions capture wishlist/buy intent?"
  - "I can't verify the demo is playable end-to-end. Has it been played through internally?"
- **Never assume PASS for unverifiable items.** Mark as MANUAL CHECK NEEDED.

---

## 4. Output the Verdict

```
## Demo Gate: [Campaign ID] — [Current] → [Target]

**Date**: [date]
**Campaign**: [demo-id]
**Early Access**: [Yes | No]

### Required Artifacts: [X/Y present]
- [x] demo-plan.md — found
- [ ] demo-scope.md — MISSING

### Quality Checks: [X/Y passing]
- [x] Goals are measurable
- [?] First internal build complete — MANUAL CHECK NEEDED

### Blockers
1. [Blocker description] — [suggested action]

### Verdict: [PASS | CONCERNS | FAIL]
- PASS: all required artifacts present, all quality checks passing
- CONCERNS: minor gaps that can be addressed during the current sub-stage
- FAIL: critical blockers must be resolved before advancing
```

**Immediately after generating the verdict**, write the draft to:
```
production/session-state/drafts/demo-gate-[id]-[sub-stage]-YYYYMMDD-HHMMSS.md
```
Create `production/session-state/drafts/` if it does not exist.

---

## 5. Update State on PASS

When verdict is **PASS** and user confirms:

Ask: "Gate passed. May I update `production/demo/[demo-id]/state.txt` to '[Target Sub-Stage]'?"

If yes:
1. Create `production/demo/[demo-id]/` directory if it doesn't exist
2. Write the new sub-stage name to `production/demo/[demo-id]/state.txt` (single line, no trailing newline)

---

## 6. Next-Step Widget

After verdict and any state.txt update, close with `AskUserQuestion` tailored to the gate that just ran:

**For PASS on Scoping → Building:**
```
Gate passed. What next?
[A] Run /demo-build — build the demo (recommended)
[B] Stop here for this session
```

**For PASS on Building → Playtesting:**
```
Gate passed. What next?
[A] Run /demo-playtest — coordinate the first playtest sessions (recommended)
[B] Stop here for this session
```

**For PASS on Iterating → Polishing:**
```
Gate passed. What next?
[A] Run /demo-polish — run the final polish pass (recommended)
[B] Stop here for this session
```

**For PASS on Polishing → Released:**
```
Gate passed. What next?
[A] Run /demo-integrate — backport demo improvements to main production (recommended)
[B] Plan the next demo campaign with /demo-plan
[C] Stop here for this session
```

**For PASS on Released → Publishing (EA):**
```
Gate passed. What next?
[A] Run /demo-integrate --early-access — flag EA roadmap commitments as required 1.0 stories
[B] Monitor player feedback and plan first EA patch
[C] Stop here for this session
```

For other gates: offer the most logical next demo skill + "Stop here for this session".

---

## Collaborative Protocol

- Never write state.txt without explicit user confirmation ("May I update...?")
- Never create demo-plan or demo-scope files — use `/demo-plan` and `/demo-scope`
- Mark MANUAL CHECK NEEDED rather than assuming PASS on unverifiable items
- The verdict is advisory — the user makes the final call on whether to advance
- Never auto-fix missing artifacts to manufacture a PASS — report the gap and name the skill to run
