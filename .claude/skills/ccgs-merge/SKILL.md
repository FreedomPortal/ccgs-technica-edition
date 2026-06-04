---
name: ccgs-merge
description: "Merge upstream CCGS framework updates into this CCGS:TE folder. Analyzes every DIVERGED file during planning so execute is fully mechanical. Repo-to-repo, machine-agnostic."
argument-hint: "[ccgs-path]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit, Bash, AskUserQuestion
model: sonnet
---

> **Explicit invocation only.** Run only when user calls `/ccgs-merge`.
> **Precondition**: Current working dir must be a clean CCGS:TE folder. The CCGS source must be a separate folder on disk.
>
> **Design principle**: ALL merge decisions happen in the Planning phase. Execute is purely mechanical — no surprises, no prompts.

---

## Config File: `.claude/ccgs-merge-paths.txt`

Machine-specific. Gitignored. Format:
```
ccgs=/absolute/path/to/ccgs-source-folder
```

---

## Phase 1 — Resolve CCGS Path

1. If argument passed to `/ccgs-merge [path]`, use it as `CCGS_PATH`.
2. Else check `.claude/ccgs-merge-paths.txt` for `ccgs=` line. Extract as `CCGS_PATH`.
3. Else ask:

```
AskUserQuestion:
  prompt: "No CCGS source path configured. Enter the absolute path to your clean CCGS base folder:"
```

Save to `.claude/ccgs-merge-paths.txt`:
```bash
echo "ccgs=/path/from/user" > .claude/ccgs-merge-paths.txt
grep -qF ".claude/ccgs-merge-paths.txt" .gitignore 2>/dev/null \
  || echo ".claude/ccgs-merge-paths.txt" >> .gitignore
```

---

## Phase 2 — Pre-flight Verification

```bash
TE_PATH="$(pwd)"
CCGS_PATH="${CCGS_PATH%/}"
TE_PATH="${TE_PATH%/}"

TE_BRANCH=$(git -C "$TE_PATH" rev-parse --abbrev-ref HEAD 2>/dev/null || echo "not a git repo")
TE_COMMIT=$(git -C "$TE_PATH" log -1 --format="%h — %s (%ci)" 2>/dev/null || echo "n/a")
TE_DIRTY=$(git -C "$TE_PATH" status --porcelain 2>/dev/null | wc -l | tr -d ' ')
TE_SKILLS=$(find "$TE_PATH/.claude/skills" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | wc -l | tr -d ' ')

CCGS_BRANCH=$(git -C "$CCGS_PATH" rev-parse --abbrev-ref HEAD 2>/dev/null || echo "not a git repo")
CCGS_COMMIT=$(git -C "$CCGS_PATH" log -1 --format="%h — %s (%ci)" 2>/dev/null || echo "n/a")
CCGS_DIRTY=$(git -C "$CCGS_PATH" status --porcelain 2>/dev/null | wc -l | tr -d ' ')
CCGS_SKILLS=$(find "$CCGS_PATH/.claude/skills" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | wc -l | tr -d ' ')
```

Display:

```
Pre-flight Check
══════════════════════════════════════════════════════
                        TE (target)       CCGS (source)
Branch:                 [TE_BRANCH]       [CCGS_BRANCH]
Last commit:            [TE_COMMIT]
                        [CCGS_COMMIT]
Uncommitted changes:    [TE_DIRTY]        [CCGS_DIRTY]
Skill count:            [TE_SKILLS]       [CCGS_SKILLS]
══════════════════════════════════════════════════════
```

Warn if either folder has uncommitted changes (`> 0`).

```
AskUserQuestion:
  prompt: "Pre-flight results above. Both folders at correct state? (yes/no)"
  options:
    - "yes — proceed"
    - "no — abort"
```

If no → Verdict: **ABORTED**

---

## Phase 3 — Full Diff Scan

Build file lists and categorize. This phase is silent (no user prompts) — just computation.

```bash
find "$CCGS_PATH" -not -path "$CCGS_PATH/.git/*" -not -path "$CCGS_PATH/.git" -type f \
  | sed "s|^$CCGS_PATH/||" | sort > /tmp/ccgs-merge-ccgs-files.txt

find "$TE_PATH" -not -path "$TE_PATH/.git/*" -not -path "$TE_PATH/.git" -type f \
  | sed "s|^$TE_PATH/||" | sort > /tmp/ccgs-merge-te-files.txt

comm -23 /tmp/ccgs-merge-ccgs-files.txt /tmp/ccgs-merge-te-files.txt > /tmp/ccgs-merge-new.txt
comm -13 /tmp/ccgs-merge-ccgs-files.txt /tmp/ccgs-merge-te-files.txt > /tmp/ccgs-merge-te-only.txt
comm -12 /tmp/ccgs-merge-ccgs-files.txt /tmp/ccgs-merge-te-files.txt > /tmp/ccgs-merge-both.txt

> /tmp/ccgs-merge-identical.txt
> /tmp/ccgs-merge-diverged.txt
while IFS= read -r file; do
  if diff -q "$CCGS_PATH/$file" "$TE_PATH/$file" > /dev/null 2>&1; then
    echo "$file" >> /tmp/ccgs-merge-identical.txt
  else
    echo "$file" >> /tmp/ccgs-merge-diverged.txt
  fi
done < /tmp/ccgs-merge-both.txt
```

These files are known to diverge intentionally between CCGS base and TE. Label them `[expected]` in all displays:
- `CLAUDE.md`
- `README.md`
- `.gitignore`
- `.claude/docs/technical-preferences.md`
- `.claude/docs/coordination-rules.md`
- `.claude/settings.json`
- `.claude/settings.local.json`

Display scan counts only — details come in Phase 4:

```
Scan complete:  NEW=[n]  DIVERGED=[n]  TE-ONLY=[n]  IDENTICAL=[n]
```

---

## Phase 4 — Analysis & Decision (Planning)

This is the core of the skill. Every file requiring a decision is analyzed here. No decisions are deferred to execute.

### 4a: NEW files

List all NEW files grouped by directory prefix. Show full list.

```
AskUserQuestion:
  prompt: "NEW files ([n] total) — listed above. Default action: copy all to TE.
           Override? Enter filenames to exclude (comma-separated), or press Enter to accept all:"
```

Store: list of NEW files to copy (full list minus any exclusions).

### 4b: DIVERGED files — per-file analysis and decision

For each file in `/tmp/ccgs-merge-diverged.txt`, in turn:

**Step 1: Compute diff**
```bash
diff -u "$TE_PATH/$file" "$CCGS_PATH/$file" > /tmp/ccgs-merge-file.diff
LINES_ADDED=$(grep -c '^+[^+]' /tmp/ccgs-merge-file.diff 2>/dev/null || echo 0)
LINES_REMOVED=$(grep -c '^-[^-]' /tmp/ccgs-merge-file.diff 2>/dev/null || echo 0)
HUNK_COUNT=$(grep -c '^@@' /tmp/ccgs-merge-file.diff 2>/dev/null || echo 0)
```

**Step 2: Analyze change character**

Interpret diff direction (`diff -u TE CCGS` means: `-` = in TE, `+` = in CCGS):
- If `LINES_ADDED > LINES_REMOVED * 2`: CCGS added significant new content → suggest `take-ccgs`
- If `LINES_REMOVED > LINES_ADDED * 2`: CCGS removed content TE has (TE may have expanded) → suggest `keep-te` or `hunk-review`
- If `LINES_ADDED ≈ LINES_REMOVED` and `LINES_ADDED < 10`: small mutual changes → suggest `hunk-review`
- If `LINES_ADDED ≈ LINES_REMOVED` and `LINES_ADDED >= 10`: significant mutual changes → suggest `hunk-review`
- If file is in expected-to-differ list: prefix recommendation with `[expected to differ]` and default to `keep-te`

Also note file type context:
- `.claude/skills/*/SKILL.md` — skill update (CCGS may have improved a shared skill)
- `.claude/hooks/*.sh` — hook script change (caution — TE hooks may have TE-specific additions)
- `.claude/docs/*.md` — documentation update
- `.claude/rules/*.md` — rule change
- Root files (`CLAUDE.md`, `README.md`) — top-level config, almost always keep-te

**Step 3: Display and ask**

Show:
```
──────────────────────────────────────────────────────────────────
DIVERGED [n/total]: [file]  [expected? ⚠️]
Type: [file type context]
Change: +[LINES_ADDED] lines from CCGS / -[LINES_REMOVED] lines from TE / [HUNK_COUNT] hunk(s)
Recommendation: [recommendation with one-line rationale]

[full diff output]
──────────────────────────────────────────────────────────────────
```

```
AskUserQuestion:
  prompt: "Decision for [file]:"
  options:
    - "take-ccgs — replace TE file with CCGS version"
    - "keep-te — leave TE file unchanged"
    - "hunk-review — select individual hunks to apply (next prompt)"
    - "skip — leave unchanged, flag as unresolved in report"
```

**If hunk-review chosen:**

Parse `/tmp/ccgs-merge-file.diff` into individual hunks (each `@@ ... @@` block plus its lines). For each hunk:

Show:
```
  Hunk [n/total] in [file]:
  [hunk header @@ ... @@]
  [hunk lines with +/- prefix and context]
```

```
  AskUserQuestion:
    prompt: "Apply this hunk?"
    options:
      - "yes — apply CCGS version of this hunk"
      - "no — skip this hunk (keep TE as-is)"
      - "rewrite — provide custom replacement text for this section"
      - "stop — skip remaining hunks, apply only what was decided so far"
```

**If `rewrite` chosen for a hunk:**

Show the hunk's TE lines (the `-` lines, stripped of the `-` prefix) — this is the text currently in the TE file that will be replaced.

```
  AskUserQuestion:
    prompt: "Rewriting hunk [n] in [file].
             Current TE content (will be replaced):
             [te_lines_of_hunk]

             Enter your replacement text (exactly as it should appear in the file):"
    (free text)
```

Store the rewrite as a planned Edit operation:
```
REWRITE_OPS[file].append({
  old_string: <exact TE lines from hunk, preserving whitespace>,
  new_string: <user-provided text>
})
```

**Collect all hunk decisions.** For `yes` hunks: add to the patch file. For `rewrite` hunks: store as Edit operations (not patch). For `no` hunks: discard.

Store as planned patch for `yes` hunks:
```
/tmp/ccgs-merge-approved-[safe-filename].patch
```

The patch file must include the `---`/`+++` header lines followed by only the `yes`-approved `@@ ... @@` blocks.

Record the planned action for this file as: `hunk-review: N yes / R rewrite / S skipped of M total`

**Store every decision** in an in-memory plan:

```
PLAN[file] = {
  action: take-ccgs | keep-te | hunk-review | skip,
  hunks_yes: N       (hunk-review only),
  hunks_rewrite: R   (hunk-review only),
  patch_file: path   (hunk-review only, null if no yes-hunks),
  rewrite_ops: [     (hunk-review only, empty if no rewrites)
    { old_string: "...", new_string: "..." },
    ...
  ]
}
```

### 4c: TE-ONLY files

List them grouped by directory. No decision needed — these are protected. Display only.

### 4d: Plan Summary & Final Approval

Print the complete merge plan:

```
══════════════════════════════════════════════════════════════════
MERGE PLAN — FINAL REVIEW
══════════════════════════════════════════════════════════════════

NEW → COPY ([n] files):
  [grouped file list]

DIVERGED — take-ccgs ([n] files):
  [file list]

DIVERGED — keep-te ([n] files):
  [file list]

DIVERGED — hunk-review ([n] files):
  [file] — [N] of [M] hunks approved
  ...

DIVERGED — skip/unresolved ([n] files):
  [file list]

TE-ONLY → protected ([n] files): [not listed in detail]
IDENTICAL → skipped ([n] files): [not listed in detail]
══════════════════════════════════════════════════════════════════
```

```
AskUserQuestion:
  prompt: "Plan complete. Approve and execute? (yes/no — no returns to beginning)"
  options:
    - "yes — execute this plan now"
    - "no — abort, do not execute"
```

If no → Verdict: **ABORTED** — plan was not executed.

---

## Phase 5 — Execute Approved Plan

No user prompts in this phase. Apply every decision from the plan mechanically.

### 5a: Copy NEW files

```bash
for file in <approved NEW list>; do
  mkdir -p "$TE_PATH/$(dirname "$file")"
  cp "$CCGS_PATH/$file" "$TE_PATH/$file"
  echo "COPIED: $file"
done
```

### 5b: Apply DIVERGED decisions

**take-ccgs:**
```bash
cp "$CCGS_PATH/$file" "$TE_PATH/$file"
echo "UPDATED (full): $file"
```

**keep-te:**
No file change. Log silently.

**hunk-review:**

Apply `yes`-hunks via patch (if any):
```bash
if [ -n "$patch_file" ]; then
  patch "$TE_PATH/$file" "$patch_file"
  EXIT_CODE=$?
  if [ $EXIT_CODE -ne 0 ]; then
    echo "PATCH-FAILED: $file"
    # Still attempt rewrite ops below — partial state is better than none
  fi
fi
```

Apply `rewrite` ops via Edit tool (if any) — one Edit call per rewrite op, using the stored `old_string` / `new_string` pairs. Each Edit replaces the exact TE content with the user's custom text.

If a rewrite op's `old_string` is not found in the current file (e.g., a prior patch changed the context), log as REWRITE-MISMATCH and record in report.

If patch exits non-zero, record as PATCH-FAILED. Do not abort — continue with remaining files.

**skip:**
No file change. Record as UNRESOLVED.

---

## Phase 6 — Write Report

```bash
mkdir -p "$TE_PATH/docs/export"
TIMESTAMP=$(date +"%Y%m%d-%H%M%S")
REPORT_PATH="$TE_PATH/docs/export/ccgs-merge-report-$TIMESTAMP.md"
```

Write report:

```markdown
# CCGS Upstream Merge Report

**Date**: [timestamp]
**Operator**: [git config user.name or "unknown"]

## Folders

| | Path | Branch | Last Commit |
|---|---|---|---|
| **TE (target)** | [TE_PATH] | [TE_BRANCH] | [TE_COMMIT] |
| **CCGS (source)** | [CCGS_PATH] | [CCGS_BRANCH] | [CCGS_COMMIT] |

## Summary

| Result | Count |
|---|---|
| Files copied (NEW) | [n] |
| Files replaced (take-ccgs) | [n] |
| Files patched via hunks (yes-hunks only) | [n] |
| Files with custom rewrites applied | [n] |
| Patch failures (manual review needed) | [n] |
| Rewrite mismatches (old_string not found) | [n] |
| Files kept as TE (keep-te) | [n] |
| Files skipped / unresolved | [n] |
| TE-ONLY files (protected) | [n] |
| Identical files (skipped) | [n] |

## Files Copied (NEW)

[list]

## Files Replaced with CCGS Version

[list]

## Files Patched (Hunks Applied)

[file — N hunks applied]
...

## Patch Failures — Manual Review Required

[list]

## Skipped / Unresolved

[list]

---
*Generated by /ccgs-merge*
```

Verdict: **MERGE COMPLETE** — report at `docs/export/ccgs-merge-report-[timestamp].md`

If patch failures or unresolved files:
> ⚠️  [n] file(s) need attention. See report.
