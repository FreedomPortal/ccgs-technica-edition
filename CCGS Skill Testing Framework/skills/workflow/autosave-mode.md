# Skill Spec: /autosave-mode

> **Category**: utility
> **Priority**: medium
> **Spec written**: 2026-05-26

## Skill Summary

`/autosave-mode` configures the draft-first protocol enforcement level for the project by writing a single value (`off`, `remind`, or `enforce`) to `production/autosave-mode.txt`. With an argument, it validates and writes immediately. Without an argument, it reads the current value, shows a table of options, and uses AskUserQuestion to select. Verdict: COMPLETE.

---

## Static Assertions

- [x] Frontmatter has all required fields (`name`, `description`, `argument-hint`, `user-invocable`, `allowed-tools`)
- [x] 2+ phase headings found (4 phases)
- [x] At least one verdict keyword present (COMPLETE)
- [x] `allowed-tools` includes Write: user selection via AskUserQuestion constitutes approval before write
- [x] Next-step handoff present ("run any long-running skill — `/code-review`, `/sprint-plan`, `/gate-check`")

---

## Director Gate Checks

- **N/A**: Configuration utility. No director gates.

---

## Test Cases

### Case 1: Happy Path — Argument provided (enforce)

**Fixture**:
- `/autosave-mode enforce` invoked with argument
- `production/autosave-mode.txt` may or may not exist

**Expected behavior**:
1. Phase 1 reads current setting (if file exists)
2. Phase 2 validates argument `enforce` — valid value, skip Phase 3
3. Phase 4 writes `enforce` to `production/autosave-mode.txt` (creates `production/` if needed)
4. Confirms: "Autosave mode set to `enforce`." + one sentence on what will now happen at approval gates

**Assertions**:
- [ ] Valid argument skips Phase 3 (no AskUserQuestion)
- [ ] Value written to `production/autosave-mode.txt`
- [ ] Confirmation includes mode name and behavioral description
- [ ] Verdict: COMPLETE

**Case Verdict**: PASS

---

### Case 2: No argument — Shows current mode, asks user

**Fixture**:
- `/autosave-mode` invoked with no argument
- `production/autosave-mode.txt` contains `remind`

**Expected behavior**:
1. Phase 1 reads current setting: `remind`
2. Phase 2 detects no argument; proceeds to Phase 3
3. Phase 3 displays table of all 3 modes; AskUserQuestion: "Current autosave mode: `remind`. Change it?"
   Options: enforce, remind, off, Keep current (remind)
4. User selects `enforce`
5. Phase 4 writes `enforce` to file; confirms

**Assertions**:
- [ ] Current mode shown in AskUserQuestion prompt
- [ ] All 3 modes listed with behavioral descriptions
- [ ] "Keep current" option includes current value in label
- [ ] Phase 4 only runs after user selection
- [ ] Write happens after selection, not before

**Case Verdict**: PASS

---

### Case 3: Failure — Invalid argument

**Fixture**:
- `/autosave-mode strict` invoked (not a valid value)

**Expected behavior**:
1. Phase 2 validates argument `strict` — not one of `off`, `remind`, `enforce`
2. Responds: "Valid values: `off`, `remind`, `enforce`"
3. Skill stops — does not proceed to Phase 3 or 4

**Assertions**:
- [ ] Validation error shown with valid options listed
- [ ] No file written
- [ ] No AskUserQuestion triggered
- [ ] Skill stops cleanly

**Case Verdict**: PASS

---

### Case 4: Edge Case — No existing file (fresh project)

**Fixture**:
- `production/autosave-mode.txt` does not exist
- `/autosave-mode` invoked with no argument

**Expected behavior**:
1. Phase 1 notes file missing; effective default is `remind`
2. Phase 3 AskUserQuestion shows "Current autosave mode: `remind` (default — file not found)"
3. If user selects a value: Phase 4 creates `production/` directory if needed, writes file
4. Confirms new mode

**Assertions**:
- [ ] Missing file handled gracefully (default = `remind`)
- [ ] Default state noted in AskUserQuestion prompt
- [ ] `production/` directory created if it doesn't exist
- [ ] File created successfully on first write

**Case Verdict**: PASS

---

### Case 5: Mode Variant — enforce mode behavioral description accurate

**Fixture**:
- User selects `enforce`

**Expected behavior**:
1. Phase 4 writes `enforce`
2. Confirmation sentence accurately describes: "Claude cannot call AskUserQuestion with approval language unless a file was written to `production/session-state/drafts/` within the last 3 minutes."

**Assertions**:
- [ ] Confirmation sentence accurately describes the enforce behavior
- [ ] Description matches `pre-approval-check.sh` hook behavior documented in skill body
- [ ] Distinct description for each of the 3 modes

**Case Verdict**: PASS

---

## Protocol Compliance

- [x] User selection via AskUserQuestion constitutes approval before write — write always follows user choice
- [x] Current mode and options presented before any change is made
- [x] Ends with recommended next step (run a long-running skill to verify protection)
- [x] Does not write without user input (either explicit argument = user intent, or AskUserQuestion = user selection)

---

## Coverage Notes

- Actual hook enforcement (`pre-approval-check.sh`) is a runtime behavior not testable here — spec covers only the configuration write
- `production/` directory creation not explicitly stated in skill body but implied by "Create `production/` directory if it does not exist"
- No explicit "May I write" language in skill body — approval is implicit via AskUserQuestion selection; this is the one valid exception pattern for simple config writes
