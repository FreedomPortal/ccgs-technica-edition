# Skill Spec: /live-ops-plan

> **Category**: utility
> **Priority**: low
> **Spec written**: 2026-05-26

## Skill Summary

`/live-ops-plan` designs the post-launch live service strategy for a game. It reads the game concept, existing publishing roadmap, and monetization plan, then uses `AskUserQuestion` to determine the live service model (seasonal, monthly, event-driven, or maintenance) and the primary retention problem to solve. A `live-ops-designer` subagent is spawned via Task to produce a full strategy document covering content cadence calendar, seasonal events, retention mechanics, engagement metrics, economy health monitoring, and a solo-dev minimum viable slice. Output is presented for review before being written to `production/publishing/live-ops-strategy.md`.

---

## Static Assertions

- [ ] Frontmatter has all required fields (`name`, `description`, `argument-hint`, `user-invocable`, `allowed-tools`)
- [ ] 2+ phase headings found
- [ ] At least one verdict keyword present (`PASS`, `FAIL`, `CONCERNS`, `APPROVED`, `BLOCKED`, `COMPLETE`, `READY`)
- [ ] If `allowed-tools` includes Write/Edit: `"May I write"` language present
- [ ] Next-step handoff section present at end

---

## Director Gate Checks

- **N/A**: `/live-ops-plan` does not route through a director gate. It is a standalone design skill that spawns a `live-ops-designer` subagent. The skill itself acts as the orchestrator and presents agent output for human review before writing.

---

## Test Cases

### Case 1: Happy Path — First-time seasonal strategy
**Fixture**:
- `design/gdd/game-concept.md` exists with title, genre, core loop, and monetization model
- `production/publishing/publishing-roadmap.md` exists
- `design/monetization/monetization-plan.md` exists
- No `production/publishing/live-ops-strategy.md` exists yet

**Expected behavior**:
1. Phase 1 reads game concept, roadmap, and monetization plan — no stop triggered
2. Phase 2 detects no existing strategy — proceeds directly to Phase 3
3. Phase 3 asks live service model → user selects "Seasonal updates"
4. Phase 3 asks primary retention problem → user selects "Day-30 retention"
5. Phase 4 spawns `live-ops-designer` with extracted game values substituted
6. Agent produces strategy with all 6 required sections
7. Strategy is presented to user before any write
8. Phase 5 shows `/live-event` relationship note
9. Phase 6 asks "May I write the live ops strategy to `production/publishing/live-ops-strategy.md`?"
10. After approval, file is written with all 7 sections
11. Phase 7 outputs summary block with `Verdict: COMPLETE`

**Assertions**:
- [ ] Game concept values extracted and substituted into agent prompt (no placeholders left)
- [ ] Strategy presented before write gate
- [ ] Write confirmation requested with exact path
- [ ] Output file contains all 7 template sections
- [ ] Summary block includes model, retention goal, event count, and output path

**Case Verdict**: PASS

---

### Case 2: Failure — No game concept
**Fixture**:
- `design/gdd/game-concept.md` does not exist
- All other files absent

**Expected behavior**:
1. Phase 1 reads game-concept.md — file not found
2. Skill stops and outputs: "No game concept found. Run `/brainstorm` first…"
3. No AskUserQuestion calls made, no subagent spawned, no files written

**Assertions**:
- [ ] Stop message references `/brainstorm`
- [ ] No subagent spawned
- [ ] No file write attempted

**Case Verdict**: PASS

---

### Case 3: Mode Variant — Existing strategy update
**Fixture**:
- `design/gdd/game-concept.md` exists
- `production/publishing/live-ops-strategy.md` already exists with prior strategy content

**Expected behavior**:
1. Phase 1 detects existing strategy file
2. Phase 2 asks "What would you like to do?" with three options: Review and update, Add new content, Start fresh
3. User selects "Review and update existing"
4. Skill loads existing file and proceeds into Phase 3 for updates
5. Agent incorporates existing plan context

**Assertions**:
- [ ] Phase 2 mode prompt shown when existing file detected
- [ ] Existing file read before spawning agent
- [ ] Agent prompt includes existing strategy context (not empty)

**Case Verdict**: PASS

---

### Case 4: Edge Case — Maintenance mode selection
**Fixture**:
- `design/gdd/game-concept.md` exists
- No prior strategy file

**Expected behavior**:
1. Phase 3 asks live service model → user selects "Maintenance mode"
2. Phase 4 spawns agent with maintenance mode noted
3. Agent produces a minimal strategy acknowledging no planned live service
4. Strategy document is still written — records the deliberate decision
5. Document notes what metric threshold would trigger reconsideration

**Assertions**:
- [ ] Strategy document still produced and written (not skipped)
- [ ] Document includes rationale for maintenance mode decision
- [ ] Document notes trigger condition for revisiting the decision

**Case Verdict**: PASS

---

### Case 5: Protocol — Write approval gate
**Fixture**:
- Full happy-path state (game concept, roadmap, monetization plan present)
- User has reviewed agent output

**Expected behavior**:
1. Phase 6 asks "May I write the live ops strategy to `production/publishing/live-ops-strategy.md`?" before writing
2. Strategy content is presented to user in Phase 4 before the write gate in Phase 6
3. No file is written until user confirms

**Assertions**:
- [ ] Uses "May I write" before file writes
- [ ] Presents content before approval
- [ ] No auto-write

**Case Verdict**: PASS

---

## Protocol Compliance

- [ ] Uses `"May I write"` before any file writes (or is read-only and skips this)
- [ ] Presents findings/draft to user before requesting approval
- [ ] Ends with a recommended next step or follow-up action
- [ ] Does not auto-create files without user approval

---

## Coverage Notes

- The `live-ops-designer` agent prompt substitution is runtime-only — static analysis can verify that substitution placeholders exist in the prompt template but cannot verify correct values are inserted at execution time.
- Economy health monitoring thresholds are game-specific and require runtime validation against actual game data.
- The "solo developer scope filter" in Phase 4 is agent-generated; static tests cannot verify the quality of the scope recommendations.
- `/live-event` integration is documented but cross-skill behavior requires a multi-skill integration test to verify.
