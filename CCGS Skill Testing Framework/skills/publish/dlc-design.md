# Skill Spec: /dlc-design

> **Category**: utility
> **Priority**: low
> **Spec written**: 2026-05-26

## Skill Summary

`/dlc-design` designs a single DLC content pack: scope, pricing, market positioning, ethical review, and production notes. It accepts an optional `[dlc-name]` argument and reads the game concept plus monetization plan before proceeding. If no monetization plan exists the skill stops and routes to `/monetization-design`. Two subagents run in parallel — `economy-designer` (content scope, pricing, ethical flags) and `publishing-manager` (market fit, timing, community perception). Both outputs are presented for review before being written to `design/monetization/dlc/[dlc-slug].md`.

---

## Static Assertions

- [ ] Frontmatter has all required fields (`name`, `description`, `argument-hint`, `user-invocable`, `allowed-tools`)
- [ ] 2+ phase headings found
- [ ] At least one verdict keyword present (`PASS`, `FAIL`, `CONCERNS`, `APPROVED`, `BLOCKED`, `COMPLETE`, `READY`)
- [ ] If `allowed-tools` includes Write/Edit: `"May I write"` language present
- [ ] Next-step handoff section present at end

---

## Director Gate Checks

- **N/A**: `/dlc-design` does not pass through a director gate. Ethical guardrails are enforced by the `economy-designer` subagent; any HIGH RISK flags must appear in the output document regardless of the developer's decision. The skill does not escalate to a director — it surfaces flags and defers to the user.

---

## Test Cases

### Case 1: Happy Path — New cosmetic pack with argument
**Fixture**:
- `/dlc-design Founder's Cosmetic Pack` invoked (named mode)
- `design/gdd/game-concept.md` exists with title, genre, platforms, audience
- `design/monetization/monetization-plan.md` exists
- `design/monetization/dlc/` directory is empty

**Expected behavior**:
1. Phase 1 reads concept and monetization plan — no stop triggered
2. Phase 2 uses argument "Founder's Cosmetic Pack" — skips name resolution prompt
3. Phase 3 asks DLC type → user selects "Cosmetic pack"
4. Phase 3 asks release timing → user selects "Day-one / launch window"
5. Phase 3 asks production scope → user selects "Small"
6. Phase 4 spawns both agents simultaneously with game values substituted
7. Both agent outputs presented together for user review
8. Phase 5 asks "May I write the DLC design to `design/monetization/dlc/founders-cosmetic-pack.md`?"
9. File written with all template sections after confirmation
10. Phase 6 outputs summary with `Verdict: COMPLETE`

**Assertions**:
- [ ] Argument used as DLC name without prompting
- [ ] Both agents spawned simultaneously (not sequentially)
- [ ] Slug derived correctly: lowercase, hyphens, no special characters
- [ ] Both agent outputs presented before write gate
- [ ] Write gate uses exact derived path

**Case Verdict**: PASS

---

### Case 2: Failure — No monetization plan
**Fixture**:
- `design/gdd/game-concept.md` exists
- `design/monetization/monetization-plan.md` does NOT exist

**Expected behavior**:
1. Phase 1 reads game concept successfully
2. Phase 1 detects missing monetization plan
3. Skill stops: "No monetization plan found. Run `/monetization-design` first…"
4. No AskUserQuestion, no agents spawned, no file written

**Assertions**:
- [ ] Stop message references `/monetization-design`
- [ ] No subagents spawned
- [ ] No file write attempted

**Case Verdict**: PASS

---

### Case 3: Mode Variant — Updating an existing DLC
**Fixture**:
- No argument passed
- `design/monetization/dlc/expansion-act-2.md` already exists
- `design/gdd/game-concept.md` and `design/monetization/monetization-plan.md` present

**Expected behavior**:
1. Phase 2 detects existing DLC file
2. AskUserQuestion shows: "Update: expansion-act-2" plus "Create a new DLC"
3. User selects "Update: expansion-act-2"
4. Existing file is read; Phase 3 confirms scope changes only
5. Agents spawned with existing file context incorporated

**Assertions**:
- [ ] Existing DLC files listed as options in Phase 2
- [ ] Existing file read before proceeding
- [ ] Phase 3 scoped to confirming changes rather than full re-design

**Case Verdict**: PASS

---

### Case 4: Edge Case — Pay-to-win flag
**Fixture**:
- `design/gdd/game-concept.md` exists (game is competitive multiplayer)
- `design/monetization/monetization-plan.md` exists with F2P + premium currency model
- User selects "Content pack" type with gameplay stat boosts included in described scope

**Expected behavior**:
1. `economy-designer` detects pay-to-win dynamic in the content scope
2. Agent flags the item as HIGH RISK in the Ethical Check section
3. Written document includes the flag even if user proceeds
4. Summary block lists "Risks flagged: 1 (HIGH RISK)"

**Assertions**:
- [ ] HIGH RISK flag surfaced in agent output
- [ ] Flag written into output document's Ethical Review section
- [ ] Flag not silently removed or downgraded

**Case Verdict**: PASS

---

### Case 5: Protocol — Write approval gate
**Fixture**:
- Full happy-path state; both agent outputs received and displayed

**Expected behavior**:
1. Both agent outputs presented to user before any write is requested
2. Phase 5 asks "May I write the DLC design to `design/monetization/dlc/[slug].md`?" before writing
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

- Parallel subagent spawning (Phase 4) is a runtime behavior — static analysis can confirm both Task calls appear in the skill but cannot verify simultaneous execution.
- Slug derivation from DLC name is runtime logic; edge cases (names with apostrophes, numbers, non-ASCII) are not statically testable.
- The ethical flag thresholds (HIGH RISK / MEDIUM RISK) are agent-generated; static tests cannot verify the calibration of risk levels against actual content.
- "Comparable titles" cited by the publishing-manager are hallucination-prone and require human review at runtime.
