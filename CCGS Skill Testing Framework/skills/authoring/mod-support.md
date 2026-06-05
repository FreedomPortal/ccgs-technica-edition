# Skill Spec: /mod-support

> **Category**: utility
> **Priority**: low
> **Spec written**: 2026-05-26

## Skill Summary

`/mod-support` designs the mod support architecture for a game. It reads the game concept, engine version reference, and any existing architecture ADRs, then uses `AskUserQuestion` to determine the desired modding level (data-only, full, or none), distribution method, and whether mod support is MVP or post-launch. Two subagents run in parallel — `technical-director` (runtime loading architecture, security model, engine-specific constraints) and `game-pipeline-developer` (authoring tools, asset pipeline, documentation requirements). Both outputs are presented for review before being written to `design/modding/mod-support.md`. The skill ends with a recommendation to run `/architecture-decision mod-loading-system` and `/security-audit`.

---

## Static Assertions

- [ ] Frontmatter has all required fields (`name`, `description`, `argument-hint`, `user-invocable`, `allowed-tools`)
- [ ] 2+ phase headings found
- [ ] At least one verdict keyword present (`PASS`, `FAIL`, `CONCERNS`, `APPROVED`, `BLOCKED`, `COMPLETE`, `READY`)
- [ ] If `allowed-tools` includes Write/Edit: `"May I write"` language present
- [ ] Next-step handoff section present at end

---

## Director Gate Checks

- **N/A**: `/mod-support` does not route through a director gate. Security implications are surfaced by the `technical-director` subagent; the skill mandates the security analysis is always presented regardless of modding level chosen. No formal gate verdict is issued — the skill produces a design document and defers decisions to the user.

---

## Test Cases

### Case 1: Happy Path — Data-only modding, manual install, post-launch
**Fixture**:
- `design/gdd/game-concept.md` exists with title, genre, core loop, platforms
- `docs/engine-reference/godot/VERSION.md` exists (Godot 4.6)
- `docs/architecture/` directory exists but no mod-related ADRs
- No `design/modding/mod-support.md` exists

**Expected behavior**:
1. Phase 1 reads concept, engine version, architecture — no stop triggered
2. Phase 2 detects no existing design — proceeds to Phase 3
3. Phase 3 asks modding level → user selects "Data / content only"
4. Phase 3 asks distribution → user selects "Manual file install"
5. Phase 3 asks scope → user selects "Post-launch"
6. Phase 4 spawns both agents simultaneously with game and engine values substituted
7. Both outputs presented for user review
8. Phase 5 asks "May I write the mod support design to `design/modding/mod-support.md`?"
9. File written with all 9 template sections
10. Phase 6 displays ADR and security-audit recommendation
11. Phase 7 outputs summary with `Verdict: COMPLETE`

**Assertions**:
- [ ] Engine version substituted in both agent prompts
- [ ] Both agents spawned simultaneously
- [ ] Security model section present in output even for data-only level
- [ ] Post-write recommendation includes `/architecture-decision` and `/security-audit`

**Case Verdict**: PASS

---

### Case 2: Failure — No game concept
**Fixture**:
- `design/gdd/game-concept.md` does not exist

**Expected behavior**:
1. Phase 1 reads concept — file not found
2. Skill stops: "No game concept found. Run `/brainstorm` first…"
3. No AskUserQuestion, no agents, no file write

**Assertions**:
- [ ] Stop message references `/brainstorm`
- [ ] No agents spawned
- [ ] No file write attempted

**Case Verdict**: PASS

---

### Case 3: Mode Variant — Undecided modding level
**Fixture**:
- `design/gdd/game-concept.md` exists
- `docs/engine-reference/godot/VERSION.md` exists
- No prior mod support design

**Expected behavior**:
1. Phase 3 asks modding level → user selects "Undecided — help me think through it"
2. Skill presents trade-off framing block before asking again:
   - Data/content only: low security risk, lower tooling cost
   - Full modding: high ceiling, significant tooling/security investment
   - None: zero scope now, document to avoid lock-out
3. Second AskUserQuestion for level shown after framing
4. User makes selection and proceeds normally

**Assertions**:
- [ ] Trade-off framing block displayed when "Undecided" selected
- [ ] Second level prompt shown after framing
- [ ] Flow continues to distribution and scope questions

**Case Verdict**: PASS

---

### Case 4: Edge Case — "No modding planned" still writes document
**Fixture**:
- `design/gdd/game-concept.md` exists
- No prior design

**Expected behavior**:
1. Phase 3 modding level → user selects "No modding planned"
2. Skill still spawns agents (with no-modding context noted)
3. Design document is still written — records the deliberate decision
4. Document includes architectural constraints to preserve future mod-ability
5. Write gate still triggered before file is written

**Assertions**:
- [ ] Document produced even when "No modding planned" selected
- [ ] Document records deliberate decision with rationale
- [ ] Architectural preservation constraints noted

**Case Verdict**: PASS

---

### Case 5: Protocol — Write approval gate
**Fixture**:
- Full happy-path state; both agent outputs received

**Expected behavior**:
1. Both agent outputs presented to user before any write requested
2. Phase 5 asks "May I write the mod support design to `design/modding/mod-support.md`?"
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

- Engine-specific mod loading capabilities (e.g., Godot resource packs vs. Unity asset bundles) are agent-generated and require human expert review at runtime — the skill cannot statically verify technical accuracy.
- Platform-specific distribution policy terms (Steam Workshop revenue share, mod.io policies) are runtime-only data; the skill mandates noting them but cannot verify the content is current.
- Security model sandboxing recommendations are engine and mod-level dependent — static tests cannot verify completeness of the attack surface analysis.
- The `/security-audit` follow-up recommendation is documented in the skill but cross-skill integration is runtime-only.
