# Skill Spec: /analytics-setup

> **Category**: utility
> **Priority**: low
> **Spec written**: 2026-05-26

## Skill Summary

`/analytics-setup` designs the analytics and telemetry plan for the game. It reads the game concept, technical preferences, any existing analytics plan, and the publishing roadmap to determine mode. It walks the developer through primary analytics goal selection and platform choice (GameAnalytics, Steam Stats, PostHog, custom log-to-file, or skip). It then spawns an `analytics-engineer` agent via Task to produce a full event taxonomy with priority tiers, key funnels, session metrics, and privacy notes. Engine integration guidance is included after cross-referencing engine version docs. Output is `docs/analytics/analytics-plan.md`. The skill requires explicit approval before writing and concludes with a COMPLETE verdict.

---

## Static Assertions

- [ ] Frontmatter has all required fields (`name`, `description`, `argument-hint`, `user-invocable`, `allowed-tools`)
- [ ] 2+ phase headings found
- [ ] At least one verdict keyword present (`PASS`, `FAIL`, `CONCERNS`, `APPROVED`, `BLOCKED`, `COMPLETE`, `READY`)
- [ ] If `allowed-tools` includes Write/Edit: `"May I write"` language present
- [ ] Next-step handoff section present at end

---

## Director Gate Checks

- **N/A**: `/analytics-setup` does not invoke a director gate check. It spawns an `analytics-engineer` subagent but this is a specialist agent, not a gate. The skill itself acts as the orchestrator and presents taxonomy output for user review rather than triggering a verdicted gate phase.

---

## Test Cases

### Case 1: Happy Path — Full Analytics Plan Creation
**Fixture**:
- `design/gdd/game-concept.md` exists with title, genre, core mechanics, target audience, platforms
- `.claude/docs/technical-preferences.md` exists with engine configured
- `docs/engine-reference/[ENGINE]/` exists with version notes
- No `docs/analytics/analytics-plan.md` exists
- No `production/publishing/publishing-roadmap.md` (optional — skill proceeds without it)

**Expected behavior**:
1. Reads all available source files
2. Skips update-vs-start-fresh question (no existing plan)
3. Asks primary analytics goal (balance tuning / retention / onboarding / launch health / all)
4. Presents platform options with honest tradeoffs; asks which to use
5. Reads `game-concept.md` again to extract taxonomy inputs
6. Spawns `analytics-engineer` agent via Task with fully substituted prompt
7. Presents event taxonomy, funnels, session metrics, and privacy notes to user before writing
8. Checks `docs/engine-reference/[ENGINE]/` for breaking changes before including integration code
9. Asks `"May I write the analytics plan to docs/analytics/analytics-plan.md?"`
10. Writes plan with all required sections; creates `docs/analytics/` directory if absent
11. Outputs structured summary with event counts, funnel count, and COMPLETE verdict

**Assertions**:
- [ ] No update-vs-start-fresh question fired
- [ ] Goal question and platform question both issued before agent spawn
- [ ] Task tool used to spawn `analytics-engineer` agent
- [ ] Taxonomy presented to user before any write
- [ ] Engine version docs checked before integration snippet included
- [ ] `"May I write"` approval gate fires
- [ ] Output plan contains: Platform Decision, Event Taxonomy, Key Funnels, Session Metrics, Privacy Compliance, Implementation Checklist sections
- [ ] COMPLETE verdict in summary output

**Case Verdict**: PASS

---

### Case 2: Failure — Missing Game Concept
**Fixture**:
- `design/gdd/game-concept.md` does not exist
- No other files relevant to analytics present

**Expected behavior**:
1. Phase 1 read finds no game concept
2. Skill halts with: `"No game concept found. Run /brainstorm first — analytics design depends on knowing your core game loop, monetization model, and target audience."`
3. No questions asked, no agent spawned, no files written

**Assertions**:
- [ ] Failure message references `/brainstorm`
- [ ] Failure message explains why (game loop, monetization, audience needed)
- [ ] No AskUserQuestion calls issued
- [ ] No Task agent spawned
- [ ] No files written

**Case Verdict**: PASS

---

### Case 3: Mode Variant — "Skip for Now" Platform Choice
**Fixture**:
- `design/gdd/game-concept.md` exists
- No existing analytics plan
- User selects "Skip for now" at platform choice question

**Expected behavior**:
1. Records goal and "skip" platform decision
2. Does NOT spawn `analytics-engineer` agent (no taxonomy to design)
3. Still asks approval before writing the plan
4. Writes a plan that documents the deferred decision with reason and revisit milestone
5. Plan body states: "Analytics deferred. Reason: [user's reason]. Revisit at: [milestone]."
6. Outputs COMPLETE verdict

**Assertions**:
- [ ] `analytics-engineer` agent NOT spawned in skip path
- [ ] Plan written despite skip (deferred decision documented)
- [ ] Plan contains deferral language with reason and revisit milestone
- [ ] Approval gate fires before write
- [ ] COMPLETE verdict present

**Case Verdict**: PASS

---

### Case 4: Edge Case — Update Existing Plan ("Just Add New Events")
**Fixture**:
- `design/gdd/game-concept.md` exists
- `docs/analytics/analytics-plan.md` already exists with a taxonomy
- User selects "Just add new events" at update mode question

**Expected behavior**:
1. Detects existing plan; presents three-option mode question (review/update, start fresh, add events)
2. User selects "Just add new events"
3. Existing event list loaded; agent spawned with instruction to extend, not replace
4. New events presented for review before any write
5. Approval gate fires before merging new events into existing plan
6. Existing sections (funnels, privacy, integration) preserved

**Assertions**:
- [ ] Three-option mode question fires (not just two)
- [ ] Existing plan content loaded and presented as baseline
- [ ] New events only are presented for approval (not full plan rewrite)
- [ ] Approval gate fires before write
- [ ] Existing funnels and privacy section not discarded

**Case Verdict**: PASS

---

### Case 5: Protocol — Approval Gate Before File Writes
**Fixture**:
- `design/gdd/game-concept.md` exists, no existing analytics plan
- `analytics-engineer` agent has returned taxonomy output
- Taxonomy has been presented to user

**Expected behavior**:
1. After taxonomy review, skill asks `"May I write the analytics plan to docs/analytics/analytics-plan.md?"`
2. Waits for explicit confirmation before any Write call
3. Does not write on agent completion alone
4. Does not write during the taxonomy presentation step

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

- The `analytics-engineer` agent prompt uses `[PLACEHOLDER]` substitution from `game-concept.md` at runtime — correctness of substitution is runtime-only and not statically verifiable.
- WebSearch is listed in `allowed-tools` for verifying engine API calls; whether it is invoked depends on engine version and content of `docs/engine-reference/` — this is a conditional runtime behavior.
- The privacy compliance section (GDPR opt-out toggle, anonymous UUID) is produced by the subagent; static analysis can only confirm the output plan template includes a Privacy Compliance section heading.
- The "unusual genre or platform" fallback (Phase 4 note) is an open-ended branch that produces non-templated output — runtime-only.
- Directory creation (`docs/analytics/`) is an implicit prerequisite; static checks cannot confirm it is created before the Write call without runtime execution.
