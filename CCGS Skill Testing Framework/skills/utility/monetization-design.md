# Skill Spec: /monetization-design

> **Category**: utility
> **Priority**: low
> **Spec written**: 2026-05-26

## Skill Summary

`/monetization-design` designs the revenue model for a game: pricing strategy, post-launch revenue streams, ethical guardrails, and player trust alignment. It reads the game concept, publishing roadmap, any existing monetization plan, and in-game economy design. The user selects a primary revenue model (buy-once, buy-once+DLC, F2P+cosmetics, or F2P+premium currency). Two subagents run in parallel — `economy-designer` (pricing, revenue streams, ethical flags) and `publishing-manager` (market fit, community perception, recommended messaging). Ethical HIGH RISK flags are non-negotiable and must appear in the output document. Both outputs are presented before being written to `design/monetization/monetization-plan.md`.

---

## Static Assertions

- [ ] Frontmatter has all required fields (`name`, `description`, `argument-hint`, `user-invocable`, `allowed-tools`)
- [ ] 2+ phase headings found
- [ ] At least one verdict keyword present (`PASS`, `FAIL`, `CONCERNS`, `APPROVED`, `BLOCKED`, `COMPLETE`, `READY`)
- [ ] If `allowed-tools` includes Write/Edit: `"May I write"` language present
- [ ] Next-step handoff section present at end

---

## Director Gate Checks

- **N/A**: `/monetization-design` does not route through a director gate. Ethical guardrails are enforced by the `economy-designer` subagent; HIGH RISK flags are mandatory in the output document regardless of the developer's decision to proceed. No gate verdict is issued — the skill defers final decisions to the user while ensuring flags are visible.

---

## Test Cases

### Case 1: Happy Path — Buy-once + DLC model
**Fixture**:
- `design/gdd/game-concept.md` exists with title, genre, target audience, platforms
- `production/publishing/publishing-roadmap.md` exists
- `design/gdd/economy.md` exists
- No `design/monetization/monetization-plan.md` exists yet

**Expected behavior**:
1. Phase 1 reads all four source files — no stop triggered
2. Phase 2 detects no existing plan — proceeds to Phase 3
3. Phase 3 asks primary revenue model → user selects "Buy-once + DLC"
4. Phase 4 spawns both agents simultaneously with game values substituted
5. Both outputs presented together for user review
6. Phase 5 asks "May I write the monetization plan to `design/monetization/monetization-plan.md`?"
7. File written with all 6 template sections after confirmation
8. Phase 6 outputs summary block with `Verdict: COMPLETE`

**Assertions**:
- [ ] Both agents spawned simultaneously
- [ ] Game title, genre, audience, platforms substituted into prompts
- [ ] Both outputs presented before write gate
- [ ] Output file contains Ethical Guardrails section
- [ ] Summary lists revenue streams count and risk count

**Case Verdict**: PASS

---

### Case 2: Failure — No game concept
**Fixture**:
- `design/gdd/game-concept.md` does not exist

**Expected behavior**:
1. Phase 1 reads concept — file not found
2. Skill stops: "No game concept found. Run `/brainstorm` first…"
3. No AskUserQuestion, no agents spawned, no file written

**Assertions**:
- [ ] Stop message references `/brainstorm`
- [ ] No agents spawned
- [ ] No file write attempted

**Case Verdict**: PASS

---

### Case 3: Mode Variant — Existing plan update
**Fixture**:
- `design/monetization/monetization-plan.md` already exists with prior content
- `design/gdd/game-concept.md` exists

**Expected behavior**:
1. Phase 1 reads existing plan
2. Phase 2 detects existing plan and asks "What would you like to do?"
3. Options: "Review and update existing", "Add a new revenue stream", "Start fresh (archive the old one)"
4. User selects "Add a new revenue stream"
5. Skill proceeds with context of existing plan loaded into agent prompts

**Assertions**:
- [ ] Mode prompt shown when existing plan detected
- [ ] Existing plan contents available to agents (not ignored)
- [ ] New stream appended rather than replacing existing content

**Case Verdict**: PASS

---

### Case 4: Edge Case — F2P + loot boxes triggers jurisdiction flags
**Fixture**:
- `design/gdd/game-concept.md` exists (game targets PC + mobile, global audience)
- No prior monetization plan
- User selects "Free-to-play + premium currency" with loot box mechanic in scope

**Expected behavior**:
1. `economy-designer` detects loot box / gacha mechanic in the proposed model
2. Agent flags Belgium and Netherlands bans explicitly
3. Agent flags other markets under active review
4. Flag appears in Ethical Guardrails section of output document
5. Flag is not removed even if developer chooses to proceed
6. Alternative suggested: "pity system with visible odds"

**Assertions**:
- [ ] Jurisdiction-specific risks flagged (Belgium, Netherlands minimum)
- [ ] Flag written into output document's Ethical Guardrails section
- [ ] Alternative recommendation provided alongside flag

**Case Verdict**: PASS

---

### Case 5: Protocol — Write approval gate
**Fixture**:
- Full happy-path state; both agent outputs received and displayed

**Expected behavior**:
1. Both agent outputs presented to user before any write requested
2. Phase 5 asks "May I write the monetization plan to `design/monetization/monetization-plan.md`?"
3. No file written until user confirms

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

- Pricing recommendations ("comparable titles") are agent-generated and subject to hallucination — human review of comparables is required at runtime.
- Jurisdiction legal status for loot boxes changes over time; the skill mandates flagging but cannot verify the flags reflect current law.
- The "no monetization" edge case (jam game, free project) is mentioned in the Collaborative Protocol but has no explicit phase handler — this is a runtime behavior gap worth noting.
- Ethical guardrail enforcement (HIGH RISK flags appearing in the output file) is declared in the skill's Collaborative Protocol but can only be verified by running the skill and inspecting the written file.
