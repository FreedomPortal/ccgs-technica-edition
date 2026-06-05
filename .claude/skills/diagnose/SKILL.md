---
name: diagnose
description: "Structured 6-phase debugging workflow for game code. Enforces a fast feedback loop before any hypothesis or code change. Use when root cause is unclear, bug is non-deterministic, or ad-hoc debugging is thrashing. Outputs a regression test and an optional post-mortem."
argument-hint: "[symptom description | --file path/to/suspect-file]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit, Bash, Task, AskUserQuestion
model: sonnet
---

> **When to use:** Root cause is unclear after basic inspection, the bug is non-deterministic, or debugging has already thrashed through more than one failed attempt. For bugs with an obvious cause, fix directly without this workflow.

## Phase 1 — Build the Feedback Loop

**This phase is a hard gate. Do not hypothesize or touch code until the feedback loop exists and works.**

A feedback loop is a command or sequence that: (a) runs in under 30 seconds, (b) produces observable output, (c) shows the bug when present, and (d) shows clean output when fixed.

Choose the loop type for the bug:

| Loop type | When to use | How |
|---|---|---|
| GDUnit4 test | Logic, state machine, formula bugs | `godot --headless --script tests/gdunit4_runner.gd` |
| Repro script | Physics, spawning, visual order bugs | Create `tests/repro_[bug].gd` — runs headless, prints pass/fail |
| Isolated scene | Multi-node interaction bugs | Strip scene to minimum nodes that still reproduce the bug |
| Print-trace | Non-deterministic, timing, signal bugs | `print_debug()` calls + run game normally; observe console |

State which loop you are using and why.

**If you cannot establish any feedback loop:** stop here. Tell the user what is blocking it and what they need to provide (a test harness, a repro script, access to a running build). Do not proceed without a working loop.

---

## Phase 2 — Confirm Reproduction

Using the feedback loop from Phase 1, confirm the bug reproduces.

- **Deterministic bug:** run the loop once, confirm the failure.
- **Non-deterministic bug:** run the loop 3 times. If it fails at least once, note the failure rate and proceed. If it never fails, the loop is not hitting the right code path — return to Phase 1.

**Godot-specific checks for non-deterministic bugs:**
- `_physics_process` vs `_process` ordering — are you asserting frame-order-dependent state?
- Node tree initialization — does `_ready` fire in the order you expect across parent/child nodes?
- `call_deferred` — are calls crossing a frame boundary that affects the assertion?
- Physics engine: Jolt is the default in Godot 4.6. If the bug may be physics-related, check whether it reproduces with Godot Physics as fallback (`ProjectSettings → Physics → 3D → Physics Engine`).
- Signals: is the connection mode deferred or immediate? Does the signal fire before or after `_ready` in the receiver?

**Output:** "Reproduces: YES / NO / FLAKY (N/3 runs)." If FLAKY, note the trigger conditions observed.

---

## Phase 3 — Hypothesize

Generate ranked hypotheses **without touching any code**.

For each hypothesis:
1. State the suspected root cause in one sentence
2. Predict what the feedback loop output will show if this hypothesis is correct
3. Rate confidence: HIGH / MEDIUM / LOW

Rank by confidence × testability. Address the highest-ranked, most testable hypothesis first.

**Cap at 5 hypotheses.** If more than 5 come to mind, collapse the low-confidence ones. Hypothesis generation without bounds is procrastination.

**Output:** Numbered list, each with root cause, predicted observable, and confidence.

---

## Phase 4 — Instrument

Add minimum targeted instrumentation to test the top hypothesis. Change nothing else.

**Rules:**
- Use `print_debug()` over `print()` — includes file and line number automatically
- Use `assert(condition, "descriptive message")` to check invariants — fails loudly with context
- Do NOT add `await` for instrumentation — it changes execution order and may mask the bug
- Do NOT refactor, rename, or "clean up" code you are reading — you are diagnosing, not fixing
- For visual bugs: use `draw_line()` in `_draw()` or `DebugDraw3D` instead of print statements

Run the feedback loop. Read the output.

- **Confirmed:** hypothesis is correct — proceed to Phase 5
- **Refuted:** mark hypothesis WRONG, move to the next ranked hypothesis, re-instrument
- **Inconclusive:** add one additional instrumentation point to the same hypothesis before abandoning it

If all 5 hypotheses are refuted: return to Phase 3 with the new information gathered from instrumentation.

---

## Phase 5 — Fix and Regression Test

Root cause is confirmed. Fix it and lock it with a test.

**Step 1: Remove all Phase 4 instrumentation before writing any fix.** No debug prints in the fix. Start clean.

**Step 2: Write the regression test first.**

The test must:
- Reproduce the original failure condition as it existed before the fix
- Assert the correct expected behavior
- Live in `tests/unit/[system]/` or `tests/integration/[system]/` depending on scope
- Follow CCGS naming: file `[system]_[feature]_test.gd`, function `test_[scenario]_[expected]()`

Run the test. It **must fail** before the fix. This proves the test actually catches the bug. If it passes before the fix, the test is wrong — revise it until it fails, then proceed.

**Step 3: Spawn the appropriate specialist via Task to implement the fix.**

Route by affected file type:

| File type | Specialist |
|---|---|
| `.gd` game logic, gameplay systems | `gameplay-programmer` |
| Engine core, physics, rendering pipeline | `engine-programmer` |
| UI, menus, HUD, dialogue | `ui-programmer` |
| AI, pathfinding, NPC behaviour | `ai-programmer` |

Brief the specialist with: the confirmed root cause, the regression test path, and the acceptance criterion ("the regression test must pass; the behaviour must match [expected description]"). Scope explicitly — no refactoring or cleanup of adjacent code.

**Step 4: Run the regression test.** Must PASS. If it fails, the fix is incomplete — return the failure output to the specialist and iterate.

**Step 5: Run the full test suite for the affected system.** No new failures permitted.

---

## Phase 6 — Cleanup and Post-Mortem

**Instrumentation sweep:** Grep every file touched during this session for leftover debug prints.

```
grep -r "print_debug" src/
```

Remove any `print_debug` calls added during this diagnosis. The regression test is not instrumentation — it stays in `tests/` permanently.

**Documentation:**

- If the root cause was non-obvious (a Godot API quirk, a signal timing edge case, a Jolt physics behaviour, a deferred-call ordering issue): add a single `# NOTE:` comment at the fix site explaining WHY, not what the code does.
- If the bug required more than 2 hypotheses to find: write a post-mortem using `/post-mortem` and save it to `docs/postmortems/pm-[YYYY-MM-DD]-[short-name].md`.

**Output a diagnosis summary:**

```
## Diagnosis Complete

Bug:             [one-line description]
Root cause:      [confirmed cause, one sentence]
Fix:             [what changed, one sentence]
Hypotheses:      [N tried, confirmed on #N]
Regression test: tests/[path]/[test_file].gd
Post-mortem:     [path] | not required
```

**Next steps:**
- If a formal bug report exists: run `/bug-report verify [BUG-ID]` to confirm the fix, then `/bug-report close [BUG-ID]`
- If the fix is non-trivial: run `/code-review [files-changed]` before merging
