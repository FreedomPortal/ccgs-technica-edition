# Skill Spec: /ccgs-merge

> **Category**: utility
> **Priority**: medium
> **Spec written**: 2026-06-05

## Skill Summary

Merges upstream CCGS framework updates into a CCGS:TE folder. Operates repo-to-repo: resolves source path, verifies both folders are clean, diffs every file, lets the user decide per-diverged-file (take-ccgs / keep-te / hunk-review / skip), then executes the approved plan mechanically in Phase 5 and writes a report. All decisions happen in Phase 4 — Phase 5 is silent execution with no prompts.

---

## Static Assertions

- [x] Frontmatter has all required fields (`name`, `description`, `argument-hint`, `user-invocable`, `allowed-tools`)
- [x] 2+ phase headings found (Phases 1–6)
- [x] At least one verdict keyword present (`ABORTED`, `MERGE COMPLETE`)
- [x] `allowed-tools` includes Write and Edit — approval gated behind Phase 4d "Approve and execute?" prompt before any writes occur
- [x] Next-step handoff present (Phase 6 closes with report path and ⚠️ if unresolved files)

---

## Director Gate Checks

**N/A** — ccgs-merge is a framework maintenance tool, not a game-design or code-quality gate. It operates between two CCGS repos, not within a game project. No director agents are involved.

---

## Test Cases

### Case 1: Happy Path — Clean merge, plan approved, report written

**Fixture**:
- `.claude/ccgs-merge-paths.txt` exists with `ccgs=/path/to/ccgs-source`
- TE folder: clean git working tree, `TE_IS_GAME=false` (no files in src/ or design/gdd/)
- CCGS source: clean, not CCGS:TE
- Scan result: 3 NEW files, 2 DIVERGED files, 5 IDENTICAL files
- User selects `take-ccgs` for both diverged files
- User approves full plan in Phase 4d

**Expected behavior**:
1. Phase 1: reads path from ccgs-merge-paths.txt — no prompt needed
2. Phase 2: displays pre-flight table, user confirms
3. Phase 3: scans and reports `NEW=3 DIVERGED=2 TE-ONLY=0 IDENTICAL=5`
4. Phase 4a: lists 3 NEW files, user accepts all
5. Phase 4b: shows each diverged file with diff, user selects take-ccgs for both
6. Phase 4d: shows full merge plan, user approves
7. Phase 5: copies 3 NEW files, replaces 2 DIVERGED files — no prompts
8. Phase 6: writes report to `docs/export/ccgs-merge-report-[timestamp].md`
9. Verdict: **MERGE COMPLETE**

**Assertions**:
- [ ] Phase 1 reads path from config file without prompting user
- [ ] Phase 2 pre-flight table shows both repos' branch, commit, dirty status, skill count
- [ ] Phase 5 runs silently — no AskUserQuestion calls after Phase 4d approval
- [ ] Report written to `docs/export/` with timestamp in filename
- [ ] Verdict MERGE COMPLETE shown

**Case Verdict**: PASS

---

### Case 2: Hard Stop — Target is a game project

**Fixture**:
- TE folder has files in `src/` (game code present)
- `TE_IS_GAME=true`

**Expected behavior**:
1. Phase 2 evaluates `TE_IS_GAME`
2. Detects game project — displays ⛔ stop message with 3 alternative approaches
3. Verdict: **ABORTED — target is a game project**
4. No diff scan, no file changes

**Assertions**:
- [ ] Guard runs during Phase 2, before any diff scan
- [ ] ⛔ message displayed with all 3 alternatives (TE clone approach, cherry-pick, git subtree)
- [ ] Verdict ABORTED shown
- [ ] No writes occur

**Case Verdict**: PASS

---

### Case 3: Hard Stop — Source is CCGS:TE

**Fixture**:
- CCGS source path contains `.claude/skills/ccgs-merge/SKILL.md`
- `CCGS_IS_TE=true`

**Expected behavior**:
1. Phase 2 evaluates `CCGS_IS_TE`
2. Detects TE-as-source — displays ⛔ stop message
3. Verdict: **ABORTED — source is CCGS:TE**
4. No merge proceeds

**Assertions**:
- [ ] Guard checks for `ccgs-merge/SKILL.md` in source folder
- [ ] ⛔ message instructs user to point source at clean CCGS base
- [ ] Verdict ABORTED shown
- [ ] No file changes

**Case Verdict**: PASS

---

### Case 4: Hunk-Review Mode — User applies selective hunks

**Fixture**:
- 1 DIVERGED file: `.claude/docs/coordination-rules.md`
- Diff has 3 hunks: hunk 1 (CCGS added new section), hunk 2 (minor wording), hunk 3 (TE-specific content removed in CCGS)
- User selects hunk-review for this file
- User approves hunk 1 (yes), approves hunk 2 via rewrite (custom text), skips hunk 3 (no)

**Expected behavior**:
1. Phase 4b shows file diff with recommendation
2. User selects hunk-review
3. Each hunk shown individually with AskUserQuestion
4. Hunk 1: yes → added to patch file
5. Hunk 2: rewrite → user provides custom text; stored as Edit op `{old_string, new_string}`
6. Hunk 3: no → discarded
7. Plan records `hunk-review: 1 yes / 1 rewrite / 1 skipped of 3 total`
8. Phase 5 applies patch for hunk 1, applies Edit op for hunk 2, skips hunk 3

**Assertions**:
- [ ] Each hunk shown with `@@ ... @@` header and +/- lines before prompting
- [ ] `rewrite` option triggers display of TE lines and free-text input prompt
- [ ] Rewrite stored as `{old_string, new_string}` Edit operation, not patch line
- [ ] Plan summary correctly shows `1 yes / 1 rewrite / 1 skipped of 3 total`
- [ ] Phase 5 applies patch for yes-hunks and Edit for rewrite-hunks independently

**Case Verdict**: PASS

---

### Case 5: No Config File — User provides path, saved for future use

**Fixture**:
- `.claude/ccgs-merge-paths.txt` does not exist
- No argument passed to `/ccgs-merge`

**Expected behavior**:
1. Phase 1 finds no config file and no argument
2. AskUserQuestion: "No CCGS source path configured. Enter the absolute path..."
3. User provides path
4. Skill writes path to `.claude/ccgs-merge-paths.txt` and adds file to `.gitignore`
5. Continues to Phase 2

**Assertions**:
- [ ] Missing config + no argument triggers AskUserQuestion (not an error)
- [ ] User-provided path written to `.claude/ccgs-merge-paths.txt`
- [ ] `.gitignore` entry added if not already present
- [ ] Skill continues to Phase 2 after path is saved

**Case Verdict**: PASS

---

## Protocol Compliance

- [x] All writes gated behind Phase 4d "Approve and execute?" — no writes happen before approval
- [x] Phase 4d presents complete merge plan before asking for approval
- [x] Report written to `docs/export/` after execution (not before)
- [x] Phase 5 is explicitly no-prompt — enforces mechanical execution
- [x] Verdict ABORTED shown clearly on any hard stop; MERGE COMPLETE on success

---

## Coverage Notes

- Expected-to-differ files (`CLAUDE.md`, `README.md`, `.gitignore`, etc.) are labeled `[expected]` and default to `keep-te`. This behavior is not independently tested — the spec assumes correct labeling from Phase 3.
- Patch apply failure (`PATCH-FAILED`) path is defined in Phase 5 but not covered by a test case — it requires a fixture where the context lines no longer match due to prior hunks.
- REWRITE-MISMATCH (old_string not found after patching) is similarly untested — requires chained hunk dependencies.
- Report format (Phase 6) is not fully validated by these test cases — only that it is written to the correct path.
