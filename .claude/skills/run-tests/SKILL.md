---
name: run-tests
description: "Run the GUT headless test suite and report pass/fail. Accepts: no args (all tests), 'unit', 'integration', or a specific test file path."
argument-hint: "[unit | integration | path/to/test_file.gd]"
user-invocable: true
allowed-tools: Read, Bash, Write
model: haiku
---

# Run Tests

Runs the Godot headless GUT test suite and reports results.

**Godot executable**: `C:\Program Files (x86)\Steam\steamapps\common\Godot Engine\godot.windows.opt.tools.64.exe`

**Project root**: current working directory (must be run from repo root).

---

## Phase 1: Parse Arguments

| Argument | Behaviour |
|---|---|
| _(none)_ | Run all tests — `res://tests/unit` + `res://tests/integration` |
| `unit` | Run `res://tests/unit` only |
| `integration` | Run `res://tests/integration` only |
| `path/to/file_test.gd` | Run single file — pass as `-gtest=res://[path]` |

If the argument looks like a file path (contains `/` or ends in `.gd`), treat it as a single-file run.

---

## Phase 2: Build and Run Command

Construct the GUT headless command. Use the full Godot executable path — bare `godot` does not work on this machine.

**Full suite or directory:**
```
"C:\Program Files (x86)\Steam\steamapps\common\Godot Engine\godot.windows.opt.tools.64.exe" \
  --headless \
  --path "." \
  -s addons/gut/gut_cmdln.gd \
  -gconfig=res://.gutconfig.json \
  -gdir=res://tests/[unit|integration] \
  -gexit
```

**Single file:**
```
"C:\Program Files (x86)\Steam\steamapps\common\Godot Engine\godot.windows.opt.tools.64.exe" \
  --headless \
  --path "." \
  -s addons/gut/gut_cmdln.gd \
  -gtest=res://[file_path] \
  -gexit
```

**All tests (no arg):** omit `-gdir` — let `.gutconfig.json` drive the directories.

Run via Bash. Capture stdout + stderr combined (`2>&1`). Timeout: 120 seconds.

---

## Phase 3: Parse Results

Scan the output for GUT summary lines. GUT 9.x prints a line like:

```
Tests: N  Passed: N  Failed: N  Errors: N  Warnings: N  Skipped: N
```

Also check for:
- `FAILED` — any test failure marker
- `ERROR` — script errors (parse errors, missing preloads)
- `Gut is done` or `All tests passed` — success markers

Extract:
- `passed` count
- `failed` count  
- `errors` count (parse errors / missing files — distinct from test failures)
- `skipped` count

---

## Phase 4: Report

```
## Test Run — [scope] — [date]

Passed:  N
Failed:  N
Errors:  N
Skipped: N

Verdict: ✓ PASS  or  ✗ FAIL
```

**PASS**: `failed == 0` AND `errors == 0`
**FAIL**: `failed > 0` OR `errors > 0`

If FAIL, print the failing test names extracted from GUT output (lines containing `FAILED:` or `[FAILED]`).

If output contains GDScript parse errors (lines with `Parse Error:` or `res://...gd:N:`), list them explicitly — these indicate broken test files, not test logic failures.

If the Godot process exits non-zero but no test summary is found, report:
```
Verdict: ✗ ERROR — GUT did not produce a summary.
Raw tail (last 20 lines):
[paste last 20 lines of output]
```

---

## Phase 5: Next Step Hint

After reporting:

- **PASS**: "Run `/story-done [story-path]` or `/smoke-check sprint` next."
- **FAIL**: "Fix failing tests before proceeding. Re-run `/run-tests` to verify."
- **ERROR**: "Check parse errors above — broken preload or missing file. Fix before re-running."
