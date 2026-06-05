# Skill Spec: /diagnose

> **Category**: analysis
> **Priority**: high
> **Spec written**: 2026-06-05

## Skill Summary

Structured 6-phase debugging workflow for game code. Phase 1 builds a feedback loop (test, repro script, isolated scene, or print-trace) before any hypothesis. Phase 2 confirms reproduction. Phase 3 generates ranked hypotheses. Phase 4 instruments and tests. Phase 5 removes instrumentation, writes a regression test first, then delegates the fix to an engine specialist via Task. Phase 6 sweeps for leftover debug prints and optionally writes a post-mortem.

---

## Static Assertions

- [x] Frontmatter has all required fields (`name`, `description`, `argument-hint`, `user-invocable`, `allowed-tools`)
- [x] 2+ phase headings found (Phases 1–6)
- [x] Verdict keyword present: Phase 6 header `## Diagnosis Complete` contains "Complete"; Phase 5 uses "PASS" for regression test result
- [x] `allowed-tools` includes Write — Phase 5 Step 2 asks `"May I write the regression test to tests/..."` before writing
- [x] Next-step handoff present (Phase 6: `/bug-report verify`, `/code-review`)

---

## Director Gate Checks

**N/A** — diagnose is a debugging workflow that spawns a coding specialist (via Task) rather than director agents. The specialist is chosen by file type (gameplay-programmer, engine-programmer, ui-programmer, ai-programmer), not by review mode.

---

## Test Cases

### Case 1: Happy Path — Root cause confirmed on first hypothesis

**Fixture**:
- Bug: player health goes negative when damaged while at 1 HP (logic bug)
- GDUnit4 test framework available
- Root cause: `apply_damage()` uses `<` instead of `<=` in clamping check

**Expected behavior**:
1. Phase 1: skill establishes GDUnit4 test as feedback loop; states why
2. Phase 2: test fails (reproduces) — deterministic bug, 1 run
3. Phase 3: generates ≤5 hypotheses; top hypothesis: off-by-one in clamp check (HIGH confidence)
4. Phase 4: adds `print_debug()` to `apply_damage()`, runs loop — confirms hypothesis 1
5. Phase 5 Step 1: removes all `print_debug()` calls before writing fix
6. Phase 5 Step 2: writes regression test to `tests/unit/combat/health_clamp_test.gd` — runs it, confirms it FAILS before fix
7. Phase 5 Step 3: spawns `gameplay-programmer` via Task with confirmed root cause and test path
8. Phase 5 Step 4: runs regression test — PASS
9. Phase 5 Step 5: runs full combat test suite — no new failures
10. Phase 6: grepping for `print_debug` finds nothing; no post-mortem needed (only 1 hypothesis tried)

**Assertions**:
- [ ] Phase 1 states loop type and rationale before any hypothesis
- [ ] Phase 2 output states "Reproduces: YES"
- [ ] Phase 3 generates hypotheses ranked by confidence × testability
- [ ] Phase 4 uses `print_debug()` not `print()` for instrumentation
- [ ] Phase 5 Step 1 removes instrumentation before writing any fix code
- [ ] Regression test written and confirmed FAILING before fix is applied
- [ ] Fix delegated to specialist via Task, not implemented directly by diagnose
- [ ] Phase 6 grep for `print_debug` runs across all touched files

**Case Verdict**: PASS

---

### Case 2: Failure — No feedback loop can be established

**Fixture**:
- Bug: crash occurs only on a specific player's save file (cannot be reproduced in test harness)
- No test framework, no repro script possible without the exact save data
- User cannot provide save file in this session

**Expected behavior**:
1. Phase 1: skill evaluates all 4 loop types — none viable without save data
2. Phase 1 hard gate: "I cannot establish a feedback loop. Blocking factors: [reason]. What you need to provide: [save file or repro conditions]."
3. Skill stops — does not proceed to Phase 2

**Assertions**:
- [ ] Phase 1 is a hard gate — skill explicitly stops if no loop can be established
- [ ] Blocking message names what specifically is missing
- [ ] No hypotheses generated without a working feedback loop
- [ ] No code changes made

**Case Verdict**: PASS

---

### Case 3: Non-Deterministic Bug — Flaky reproduction

**Fixture**:
- Bug: enemy AI occasionally pathfinds through walls (physics/timing issue)
- Engine: Godot 4.6 with Jolt physics (default)

**Expected behavior**:
1. Phase 1: skill selects print-trace loop (non-deterministic, timing/physics)
2. Phase 2: runs loop 3 times — fails 2/3 runs → "Reproduces: FLAKY (2/3 runs)"
3. Phase 2: Godot-specific checks noted — Jolt physics default flagged as possible factor
4. Phase 3: hypotheses include Jolt-specific collision edge case and `_physics_process` timing
5. Phase 4: instruments with `print_debug()`, tests hypothesis about Jolt behavior
6. If confirmed: Phase 5 Step 2 regression test designed to trigger the timing condition

**Assertions**:
- [ ] Phase 2 runs loop 3 times for non-deterministic bug
- [ ] Phase 2 output: "Reproduces: FLAKY (2/3 runs)" with trigger conditions noted
- [ ] Godot 4.6 Jolt default mentioned as candidate factor when physics suspected
- [ ] `_physics_process` vs `_process` ordering listed as Godot-specific check
- [ ] Hypotheses include engine-version-specific candidates

**Case Verdict**: PASS

---

### Case 4: Edge Case — All 5 hypotheses refuted

**Fixture**:
- Bug: UI text renders incorrectly only on second screen in multi-monitor setup
- 5 hypotheses generated and tested in Phase 4 — all refuted by instrumentation

**Expected behavior**:
1. Phase 3: generates 5 hypotheses
2. Phase 4: instruments hypothesis 1 — refuted (marked WRONG)
3. Phases 4 iter: tests 2, 3, 4, 5 — all refuted
4. After all 5 refuted: returns to Phase 3 with new information from instrumentation
5. Phase 3 (second pass): generates new hypotheses informed by what was ruled out

**Assertions**:
- [ ] Skill does not stop or error when all 5 hypotheses are refuted
- [ ] Returns to Phase 3 after all hypotheses exhausted
- [ ] Second-pass Phase 3 explicitly uses information gathered from instrumentation
- [ ] Cap of 5 hypotheses per pass respected (new 5 generated, not unbounded list)

**Case Verdict**: PASS

---

### Case 5: Instrumentation Cleanup — Debug prints left behind

**Fixture**:
- Bug resolved; fix applied and regression test passes
- Phase 6 sweep: grep finds 2 `print_debug` calls remaining in `src/combat/hitbox.gd`

**Expected behavior**:
1. Phase 6 runs `grep -r "print_debug" src/`
2. Finds 2 leftover calls in hitbox.gd
3. Removes them (Edit tool)
4. Notes regression test at `tests/unit/combat/hitbox_test.gd` stays — it is not instrumentation
5. Bug required 2 hypotheses → post-mortem not required (threshold is >2)
6. Outputs diagnosis summary with all fields populated

**Assertions**:
- [ ] Phase 6 grep covers all files touched during session
- [ ] Leftover `print_debug` calls removed via Edit
- [ ] Regression test file NOT removed (lives in `tests/` permanently)
- [ ] Post-mortem not required when ≤2 hypotheses needed
- [ ] Diagnosis summary output includes: Bug, Root cause, Fix, Hypotheses count, Regression test path, Post-mortem status

**Case Verdict**: PASS

---

## Protocol Compliance

- [x] Phase 1 is a hard gate — no hypothesis before feedback loop exists
- [x] Regression test written and confirmed FAILING before fix is delegated
- [x] Phase 5 Step 2 asks `"May I write the regression test to tests/...?"` before writing
- [x] Fix delegated to specialist — skill itself does not write fix code
- [x] Ends with `/bug-report verify` and `/code-review` next-step recommendations

---

## Coverage Notes

- Phase 5 specialist routing covers gameplay, engine, UI, and AI programmers. The routing table doesn't cover network-programmer — network bugs are an untested gap.
- The `call_deferred` Godot-specific check (Phase 2) is noted in the skill but not independently tested.
- Post-mortem required threshold is ">2 hypotheses" — the boundary case (exactly 2) is ambiguous in the skill text ("more than 2 failed attempts" in the skill header, "more than 2 hypotheses to find" in Phase 6). Verify intended behavior.
- The `--file` argument hint variant is defined in frontmatter but not exercised in test cases.
