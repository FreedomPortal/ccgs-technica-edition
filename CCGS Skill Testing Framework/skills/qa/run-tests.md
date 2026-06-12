# Skill Spec: /run-tests

> **Category**: qa
> **Priority**: high
> **Spec written**: 2026-06-12

## Skill Summary

`/run-tests` loads the engine type from `.claude/docs/technical-preferences.md`, routes to the appropriate test runner (Godot/GUT, Unity/NUnit, or Unreal automation), runs the suite headlessly via Bash, parses the output, and prints a structured pass/fail verdict to chat. It accepts an optional argument to scope the run to `unit` tests, `integration` tests, or a single test file/class; with no argument it runs the full suite. It does not write files.

---

## Static Assertions

These should pass before any behavioral testing:

- [x] Frontmatter has all required fields (`name`, `description`, `argument-hint`, `user-invocable`, `allowed-tools`)
- [x] 6 phase headings found
- [x] At least one verdict keyword present (`PASS`, `FAIL` in Phase 5)
- [ ] WARN: `allowed-tools` includes `Write` but no `"May I write"` language is present. Skill never writes files — Write is declared but unused. Known gap; not a protocol violation given actual behavior.
- [x] Next-step handoff present (Phase 6)
- [x] Reads `.claude/docs/technical-preferences.md` before executing (Phase 1)

---

## Director Gate Checks

**N/A** — mechanical runner; no review workflow, no director agents consulted.

- **Full mode**: N/A — no gates
- **Lean mode**: N/A — no gates
- **Solo mode**: N/A — no gates

---

## Test Cases

### Case 1: Happy Path — Godot, all tests pass

**Fixture** (assumed project state):
- `.claude/docs/technical-preferences.md` contains:
  ```
  Engine: Godot 4.6.2
  Testing > Executable: C:\...\godot.windows.opt.tools.64.exe
  ```
- `/run-tests` invoked with no argument
- GUT output:
  ```
  Tests: 42  Passed: 42  Failed: 0  Errors: 0  Warnings: 2  Skipped: 1
  Gut is done.
  ```
- Process exits 0

**Expected behavior**:
1. Phase 1: Reads `Engine: Godot 4.6.2` and `Executable:` path from config
2. Phase 2: No argument → all-tests scope
3. Phase 3: Godot branch — constructs `[executable] --headless --path "." -s addons/gut/gut_cmdln.gd -gconfig=res://.gutconfig.json -gexit`; omits `-gdir`
4. Phase 4: GUT parser — extracts `passed=42`, `failed=0`, `errors=0`, `skipped=1`; finds `Gut is done`
5. Phase 5: Reports `Engine: Godot 4.6.2`, verdict `✓ PASS`
6. Phase 6: PASS hint referencing `/story-done` or `/smoke-check sprint`

**Assertions**:
- [ ] `Executable:` from config used in command (not bare `godot`)
- [ ] Command omits `-gdir` flag
- [ ] Command includes `-gconfig=res://.gutconfig.json`
- [ ] Parsed counts: passed=42, failed=0, errors=0, skipped=1
- [ ] Report includes `Engine:` line
- [ ] Verdict block shows `✓ PASS`
- [ ] Phase 6 PASS hint present

**Case Verdict**: PASS

---

### Case 2: Failure — Godot, tests fail with named failures

**Fixture**:
- Engine: Godot 4.x (config present)
- `/run-tests unit` invoked
- GUT output:
  ```
  Tests: 10  Passed: 8  Failed: 2  Errors: 0  Warnings: 0  Skipped: 0
  FAILED: test_damage_formula_returns_zero_when_no_attack
  FAILED: test_synergy_bonus_additive_only
  Gut is done.
  ```

**Expected behavior**:
1. Phase 1: Reads engine from config
2. Phase 2: `unit` argument → unit scope
3. Phase 3: Godot branch — command uses `-gdir=res://tests/unit`
4. Phase 4: Parses `passed=8`, `failed=2`, `errors=0`; extracts two `FAILED:` lines
5. Phase 5: `failed > 0` → verdict `✗ FAIL`; both failing test names listed
6. Phase 6: FAIL hint referencing re-run

**Assertions**:
- [ ] Command includes `-gdir=res://tests/unit`
- [ ] Parsed counts: passed=8, failed=2, errors=0
- [ ] Verdict `✗ FAIL`
- [ ] Both failing test names in output
- [ ] Phase 6 FAIL hint present

**Case Verdict**: PASS

---

### Case 3: Engine Routing — Unity variant

**Fixture**:
- `.claude/docs/technical-preferences.md` contains `Engine: Unity`
- `/run-tests integration` invoked
- `dotnet test` output:
  ```
  Passed: 20, Failed: 0, Skipped: 3, Total: 23
  ```

**Expected behavior**:
1. Phase 1: Reads `Engine: Unity`
2. Phase 2: `integration` argument → integration scope
3. Phase 3: Unity branch — command is `dotnet test --filter Category=integration`; GUT command NOT used
4. Phase 4: Unity/NUnit parser — extracts `passed=20`, `failed=0`, `skipped=3`
5. Phase 5: Reports `Engine: Unity`, verdict `✓ PASS`
6. Phase 6: PASS hint

**Assertions**:
- [ ] Command uses `dotnet test --filter Category=integration`, NOT Godot CLI flags
- [ ] No `--headless`, `-s addons/gut/`, or `res://` prefixes in command
- [ ] Parsed counts: passed=20, failed=0, skipped=3
- [ ] Report includes `Engine: Unity`
- [ ] Verdict `✓ PASS`

**Case Verdict**: PASS

---

### Case 4: Unknown Engine — Stop with error

**Fixture**:
- `.claude/docs/technical-preferences.md` contains `Engine: Defold`
- `/run-tests` invoked

**Expected behavior**:
1. Phase 1: Reads `Engine: Defold` successfully (field is present)
2. Phase 2: Parses argument (no arg)
3. Phase 3: `Defold` not in routing table → stop with error message
4. No Bash command executed; no Phase 4/5/6 output

**Assertions**:
- [ ] Error message contains "Unknown engine 'Defold'"
- [ ] Error message lists supported engines (Godot 4.x, Unity, Unreal Engine)
- [ ] Error message references updating `Engine:` in `technical-preferences.md`
- [ ] No test command is run (Bash not called)

**Case Verdict**: PASS

---

### Case 5: No Summary Produced — ERROR verdict

**Fixture**:
- Engine: Godot 4.x (config present)
- `/run-tests` invoked with no argument
- Process exits non-zero
- stdout/stderr contains engine startup messages but no `Tests: N  Passed: N ...` summary line
- Last 20 lines are engine error messages

**Expected behavior**:
1. Phase 1–3: Normal config load and command construction
2. Phase 4: Scans output — no summary line found; no `Gut is done` or `All tests passed`; counts unresolvable
3. Phase 5: Non-zero exit + no summary → `Verdict: ✗ ERROR — Test runner did not produce a summary.` + last 20 raw lines
4. Phase 6: ERROR hint

**Assertions**:
- [ ] Verdict uses `✗ ERROR` form, not `✗ FAIL`
- [ ] Raw tail (last 20 lines) printed verbatim
- [ ] No fabricated pass/fail counts in output
- [ ] Phase 6 ERROR hint present

**Case Verdict**: PASS

---

## Protocol Compliance

- [ ] WARN: `allowed-tools` lists `Write` but no `"May I write"` gate in skill body. All output goes to chat. Gap noted — not a protocol violation given actual behavior.
- [x] Reads config before executing (Phase 1 gate)
- [x] Presents verdict block before any next-step action
- [x] Ends with conditional next-step hint (Phase 6)
- [x] Does not auto-create files

---

## Coverage Notes

- **Write tool unused**: If a future revision saves test logs to `production/qa/`, a `"May I write"` gate must be added.
- **`Engine:` missing case not tested**: Phase 1 stops if `Engine:` absent. Not a dedicated test case — straightforward early-exit; noted as gap.
- **Godot `Executable:` fallback**: If `Executable:` absent from config, skill falls back to bare `godot`. Machine-specific path issues (non-standard install) fall into this gap; not tested explicitly.
- **Single-file routing**: Phase 3 `-gtest=res://[path]` path (Godot) and `FullyQualifiedName~` path (Unity) not covered by a dedicated case. Detection rule (argument contains `/` or `.`) is tested implicitly by Case 3 using a directory arg.
- **Godot parse errors**: Phase 4 explicit `res://...gd:N:` listing not covered after engine-agnostic rewrite. Previously Case 4 — now noted as a gap since the case was repurposed for engine routing.
- **Argument validation gap**: Unrecognized string (not `unit`, `integration`, or file path) silently treated as a directory name for Godot or filter value for Unity — no explicit error branch.
- **Timeout behavior unspecified**: 120s timeout not covered; assumed to fall into Case 5 (no summary).
- **Live verification required**: All verdict paths require a running engine + test framework to fully validate.
