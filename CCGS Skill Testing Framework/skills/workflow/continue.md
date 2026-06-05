# Skill Spec: /continue

> **Category**: utility
> **Priority**: medium
> **Spec written**: 2026-05-26

## Skill Summary

`/continue` is a read-only session recovery skill. It reads `production/session-state/active.md`, the user's project memory MEMORY.md, and agent memory files to produce a concise brief (under 35 lines) of what was completed last session and what was planned next. It then offers an AskUserQuestion to select the next item to work on. Never writes files or proposes changes. Verdict: COMPLETE — session brief delivered.

---

## Static Assertions

- [x] Frontmatter has all required fields (`name`, `description`, `argument-hint`, `user-invocable`, `allowed-tools`)
- [x] 2+ phase headings found (5 phases + edge cases section)
- [x] At least one verdict keyword present (COMPLETE)
- [x] No Write/Edit in `allowed-tools` — read-only skip is valid
- [x] Next-step handoff present (Phase 5 AskUserQuestion offers next actions)

---

## Director Gate Checks

- **N/A**: Read-only orientation skill. No director gates.

---

## Test Cases

### Case 1: Happy Path — active.md with "Next session" section

**Fixture**:
- `production/session-state/active.md` exists with completed work bullets and `### Next session — pick up here` section listing 3 planned items
- User memory MEMORY.md exists with 2 project-type entries, one with open items
- `producer/MEMORY.md` has one "Pending:" forward-looking item

**Expected behavior**:
1. Phase 1 reads active.md; extracts completed work and "Next session" section
2. Phase 2 derives project slug from CWD, reads user memory, extracts open items from project/reference entries
3. Phase 3 reads producer, TD, CD agent memory; extracts only "Next:", "Pending:", "Remaining:", "Open question:" lines
4. Phase 4 outputs brief under 35 lines: Last Session (2–4 bullets), Planned Next Steps (numbered), Open Items (≤5, omit if empty)
5. Phase 5 AskUserQuestion: "Which would you like to tackle first?" — options are the planned steps + "Something else"
6. After selection: one line — either skill command or prompt for description

**Assertions**:
- [ ] Output is under 35 lines total
- [ ] "Next session" section content appears as numbered Planned Next Steps
- [ ] Open items capped at 5; omitted if none
- [ ] Phase 5 offers up to 5 items from planned steps + "Something else"
- [ ] After selection, only one line of response (skill command or prompt)
- [ ] No files written

**Case Verdict**: PASS

---

### Case 2: Failure — active.md missing

**Fixture**:
- `production/session-state/active.md` does not exist

**Expected behavior**:
1. Phase 1 attempts to read active.md
2. Reports: "No session state found. Try `/start` to get oriented."
3. Skill stops — does not proceed to Phases 2–5

**Assertions**:
- [ ] Correct error message displayed
- [ ] Skill stops at Phase 1; no further phases run
- [ ] No files written
- [ ] AskUserQuestion not triggered

**Case Verdict**: PASS

---

### Case 3: Edge Case — active.md found but no "Next session" section

**Fixture**:
- `production/session-state/active.md` exists with completed work but no `### Next session — pick up here` section (session not checkpointed before ending)

**Expected behavior**:
1. Phase 1 reads active.md, finds completed work but no "Next session" section
2. Phase 4 brief notes: "No planned steps recorded — last session may not have ended with a checkpoint."
3. Skill still proceeds to Phase 5 with whatever is available

**Assertions**:
- [ ] Note displayed: "No planned steps recorded — last session may not have ended with a checkpoint."
- [ ] Brief still output with Last Session section (if work found)
- [ ] Phase 5 still offers "Something else — I'll describe it" as fallback option

**Case Verdict**: PASS

---

### Case 4: Edge Case — User memory path not derivable

**Fixture**:
- CWD path uses unexpected format that cannot be converted to project slug
- active.md exists and is valid

**Expected behavior**:
1. Phase 2 cannot derive project slug
2. Skips Phase 2; notes "User memory not found — session state only."
3. Continues with Phase 3 (agent memory) and Phase 4 (brief from active.md only)

**Assertions**:
- [ ] Skill does not crash on memory path derivation failure
- [ ] Note: "User memory not found — session state only."
- [ ] Brief produced from active.md + agent memory alone
- [ ] Phase 5 still runs with available items

**Case Verdict**: PASS

---

### Case 5: Edge Case — Everything empty

**Fixture**:
- `production/session-state/active.md` missing
- No user memory files exist
- No agent memory files exist

**Expected behavior**:
1. Phase 1 reports missing active.md and stops
2. Output: "Nothing to continue — try `/start`."

**Assertions**:
- [ ] Graceful failure with "Nothing to continue — try `/start`."
- [ ] No files written
- [ ] No AskUserQuestion triggered

**Case Verdict**: PASS

---

## Protocol Compliance

- [x] Read-only — no Write or Edit calls; no approval gates needed (explicitly documented)
- [x] Presents brief before offering next action (output → AskUserQuestion)
- [x] Ends with AskUserQuestion offering next steps (Phase 5)
- [x] Does not write files under any condition

---

## Coverage Notes

- Memory path derivation logic (CWD → slug conversion) may behave differently on Windows vs Unix paths — worth testing on both
- Agent memory extraction is a "quick scan" — only forward-looking markers, not full file read; this may miss relevant context
- 35-line output cap is self-imposed; cannot be mechanically verified without live run
