---
name: run-tests
description: "Run the project test suite and report pass/fail. Accepts: no args (all tests), 'unit', 'integration', or a specific test file path."
argument-hint: "[unit | integration | path/to/test_file]"
user-invocable: true
allowed-tools: Read, Bash, Write
model: haiku
---

# Run Tests

Runs the project's test suite headlessly and reports results.

**Reads configuration from** `.claude/docs/technical-preferences.md` — engine type and optional executable path.

**Project root**: current working directory (must be run from repo root).

---

## Phase 1: Load Config

Read `.claude/docs/technical-preferences.md`. Extract:
- `Engine:` — selects which test runner to use (required)
- In the `Testing` section: `Executable:` — optional absolute path to the engine/test binary

If `Engine:` is absent, stop:
> "Engine not configured. Add `Engine: [Godot 4.x | Unity | Unreal Engine]` to `.claude/docs/technical-preferences.md`."

---

## Phase 2: Parse Arguments

| Argument | Behaviour |
|---|---|
| _(none)_ | Run all tests |
| `unit` | Run unit tests only |
| `integration` | Run integration tests only |
| `path/to/file` | Run single file or test class |

If the argument contains `/` or `.`, treat it as a single-file/class run.

---

## Phase 3: Build and Run Command

Route by `Engine:` value. Run via Bash. Capture stdout + stderr combined (`2>&1`). Timeout: 120 seconds.

### Godot 4.x (GUT)

Executable: use `Executable:` from config if set, otherwise `godot`.

**All tests (no arg):** omit `-gdir` — let `.gutconfig.json` drive directories.
```
[executable] --headless --path "." -s addons/gut/gut_cmdln.gd -gconfig=res://.gutconfig.json -gexit
```

**Directory (unit or integration):**
```
[executable] --headless --path "." -s addons/gut/gut_cmdln.gd -gconfig=res://.gutconfig.json -gdir=res://tests/[unit|integration] -gexit
```

**Single file:**
```
[executable] --headless --path "." -s addons/gut/gut_cmdln.gd -gtest=res://[file_path] -gexit
```

### Unity (NUnit)

**All tests:**
```
dotnet test
```

**Filtered (unit or integration):**
```
dotnet test --filter Category=[unit|integration]
```

**Single class:**
```
dotnet test --filter FullyQualifiedName~[file_path]
```

### Unreal Engine

**All tests:**
```
[UE Editor exe] [project.uproject] -ExecCmds="Automation RunAll" -NullRHI -log -unattended -ExitOnError
```

**Filtered:**
Replace `RunAll` with `RunFilter [unit|integration]`.

### Unknown engine

Stop:
> "Unknown engine '[value]'. Supported: Godot 4.x, Unity, Unreal Engine. Update `Engine:` in `.claude/docs/technical-preferences.md`."

---

## Phase 4: Parse Results

Route by engine:

### Godot (GUT 9.x)

GUT summary line:
```
Tests: N  Passed: N  Failed: N  Errors: N  Warnings: N  Skipped: N
```
Success markers: `Gut is done`, `All tests passed`
Failure lines: contain `FAILED:` or `[FAILED]`
Parse error lines: `Parse Error:` or `res://...gd:N:` — indicate broken test files, not test logic failures; list explicitly

### Unity (NUnit)

Summary line pattern:
```
Passed: N, Failed: N, Skipped: N, Total: N
```
Failure lines: contain `Failed` test names in results output.

### Unreal Engine

Look for `LogAutomationController: Test Passed` / `Test Failed` lines. Extract counts from the automation summary section.

Extract regardless of engine:
- `passed` count
- `failed` count
- `errors` count (parse errors / missing files — distinct from test failures)
- `skipped` count

---

## Phase 5: Report

```
## Test Run — [scope] — [date]

Engine:  [engine]
Passed:  N
Failed:  N
Errors:  N
Skipped: N

Verdict: ✓ PASS  or  ✗ FAIL
```

**PASS**: `failed == 0` AND `errors == 0`
**FAIL**: `failed > 0` OR `errors > 0`

If FAIL, list failing test names from Phase 4 output.

If Godot parse errors found, list them separately — broken test files, not logic failures.

If the process exits non-zero but no summary line is found, report:
```
Verdict: ✗ ERROR — Test runner did not produce a summary.
Raw tail (last 20 lines):
[paste last 20 lines of output]
```

---

## Phase 6: Next Step Hint

- **PASS**: "Run `/story-done [story-path]` or `/smoke-check sprint` next."
- **FAIL**: "Fix failing tests before proceeding. Re-run `/run-tests` to verify."
- **ERROR**: "Check errors above — broken test file or missing dependency. Fix before re-running."
