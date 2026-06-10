---
name: framework-release
description: "Cut a CCGS:TE framework release: detect changes since the last version, auto-detect breaking changes, propose a semver bump (MAJOR/MINOR/PATCH), draft release notes, and write FRAMEWORK-CHANGELOG.md + FRAMEWORK-VERSION on approval. For framework maintainers only — not for game project work."
argument-hint: "[--dry-run]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Bash, Write, AskUserQuestion
---

# Framework Release Skill

Cuts a versioned release of the CCGS:TE framework. Compares the current working
tree against the commit that last bumped `.claude/FRAMEWORK-VERSION`, detects what
changed (new skills, removed agents, doc updates, breaking API changes), and
proposes the appropriate semver level. Writes to disk only after user approval.

**Audience:** Framework maintainers. Do not run this during game development work.

---

## Files excluded from change detection

The following files are self-referential and must never appear as changes:

- `.claude/FRAMEWORK-VERSION`
- `.claude/docs/FRAMEWORK-CHANGELOG.md`
- `.claude/docs/framework-maintenance.md`
- `.claude/skills/framework-release/SKILL.md`

---

## Phase 1: Bootstrap

Check whether `.claude/FRAMEWORK-VERSION` exists:

```bash
cat .claude/FRAMEWORK-VERSION 2>/dev/null
```

**If the file is missing or empty:** This is the first release. Set current version
to `1.0.0`. Set BASE_REF to the empty tree SHA:

```bash
git hash-object -t tree /dev/null
```

**If the file exists:** Read the version string (e.g., `1.0.0`). Locate the commit
that last touched the file — this is the base ref for all diffs:

```bash
git log -1 --format=%H -- .claude/FRAMEWORK-VERSION
```

Store as `BASE_REF`. If `git log` returns nothing (file untracked), treat as first
release and use the empty tree SHA.

If `--dry-run` argument was passed, note it — Phase 6 will print what would be
written but will not write any files.

---

## Phase 2: Collect changes

Run the diff with rename detection enabled (`-M`):

```bash
git diff --name-status -M "$BASE_REF" HEAD -- .claude/ tools/hooks/ CLAUDE.md
```

Parse the output line by line. Skip any line whose path matches the exclusion list
above. Bucket every remaining change by pattern:

| Pattern | Bucket |
|---------|--------|
| `.claude/skills/*/SKILL.md` | Skills |
| `.claude/agents/*.md` | Agents |
| `.claude/docs/workflow-catalog.yaml` | Pipeline |
| `.claude/docs/` (other) | Docs |
| `.claude/rules/` | Rules |
| `tools/hooks/` | Hooks |
| `CLAUDE.md` | Framework Config |

For each changed file, record:
- Status: `A` (added), `D` (deleted), `M` (modified), `R` (renamed — format: `R\tOLD\tNEW`)

---

## Phase 3: Breaking change detection

Scan for breaking changes across three signal sources:

### 3a. Deleted or renamed skills

For every `D` status on `.claude/skills/*/SKILL.md`: **BREAKING** — skill removed.

For every `R` status on `.claude/skills/*/SKILL.md` (rename detected by `-M`):
Read both the old and new SKILL.md and compare their `id:` frontmatter field.
If `id:` changed → **BREAKING** (skill contract changed).
If `id:` unchanged → not breaking (directory renamed, skill identity preserved).

### 3b. Changed skill `id:` fields

For every `M` status on `.claude/skills/*/SKILL.md`:
Use `git show "$BASE_REF:$path"` to read the old version, then compare the
`id:` and `name:` frontmatter fields to the current version.
If either changed → **BREAKING**.

### 3c. Deleted agents

For every `D` or `R` (with identity change) status on `.claude/agents/*.md`:
**BREAKING** — agent removed or contract changed.

### 3d. Pipeline phase ID changes

If `workflow-catalog.yaml` is in the diff:
Read the old version from git (`git show "$BASE_REF:.claude/docs/workflow-catalog.yaml"`).
Compare phase IDs between old and new. Removed or renamed phase IDs → **BREAKING**.

---

## Phase 4: Propose semver

Apply the highest-level rule that matches:

| Condition | Bump |
|-----------|------|
| Any breaking change found in Phase 3 | **MAJOR** (X.0.0) |
| New skills added (`A` in Skills bucket) | **MINOR** (x.Y.0) |
| New agents added (`A` in Agents bucket) | **MINOR** (x.Y.0) |
| New pipeline phases added | **MINOR** (x.Y.0) |
| Only doc/rule/hook/config changes | **PATCH** (x.y.Z) |

Compute the proposed new version from the current version:
- MAJOR: increment first digit, reset others to 0
- MINOR: increment second digit, reset patch to 0
- PATCH: increment third digit

Present a summary to the user before asking for confirmation:

```
Current version:  1.2.0
Proposed version: 2.0.0  (MAJOR — breaking changes detected)

Breaking changes:
  - Skill removed: /old-skill-name (.claude/skills/old-skill-name/SKILL.md)
  - Agent removed: writer (.claude/agents/writer.md)

New additions:
  - 3 new skills

Other changes:
  - 5 skill updates
  - 2 doc updates
```

Then ask:

```
Proposed version: 2.0.0 (MAJOR)
Confirm bump level, or override?
Options:
  1. Confirm 2.0.0 (MAJOR) — proceed
  2. Override to MINOR (1.3.0) — I know these removals are non-breaking
  3. Override to PATCH (1.2.1) — only docs changed, ignore detection
  4. Cancel
```

Use AskUserQuestion for this prompt. Record the user's chosen version.

---

## Phase 5: Draft release notes

Compose release notes using the confirmed version and bucketed changes.

Template:

```markdown
## [VERSION] — YYYY-MM-DD

### Breaking Changes
<!-- Only if MAJOR; omit section entirely if none -->
- **Skill removed:** `/skill-name` — [one-line description from old SKILL.md]
- **Agent removed:** `agent-name` — [one-line description from old .md]
- **Pipeline:** Phase `ID` removed from workflow-catalog

### New Skills
<!-- Only if any added -->
- `/skill-name` — [description from new SKILL.md]

### New Agents
<!-- Only if any added -->
- `agent-name` — [description from new .md]

### Updated Skills
<!-- Only if ≥1 modified; list only if ≤10; otherwise summarize count -->
- `/skill-name` — [brief description of what changed]

### Docs & Rules
<!-- Only if any doc/rule changes -->
- [Description of doc change]

### Hooks
<!-- Only if any hook changes -->
- [Description of hook change]
```

Fill each section from the bucketed diff. For descriptions:
- Use the `description:` frontmatter field for skill/agent entries.
- For modified skills without obvious description changes, read the git diff and write a one-line summary.
- Omit sections that have no content.

Show the full draft to the user in the conversation before proceeding.

Ask: "May I write this release to FRAMEWORK-CHANGELOG.md and update FRAMEWORK-VERSION to [VERSION]?"

Use AskUserQuestion with options:
1. Yes — write both files
2. Edit release notes first — I'll paste the revised version
3. Cancel

---

## Phase 6: Write

**If --dry-run:** Print "DRY RUN — no files written. Would have written:" and
show what would be prepended to FRAMEWORK-CHANGELOG.md and the new version string.
Stop here.

**On approval:**

Prepend the new release entry to `.claude/docs/FRAMEWORK-CHANGELOG.md`.
Preserve the existing header comment; insert the new entry immediately after it:

```
# CCGS:TE Framework Changelog

<!-- Generated by /framework-release. Run the skill to add a new entry. -->

## [NEW ENTRY HERE]

## [PREVIOUS ENTRY]
```

Overwrite `.claude/FRAMEWORK-VERSION` with the new version string (one line, no
trailing whitespace beyond a single newline).

Do NOT commit or tag. Print:

```
Framework version bumped: 1.2.0 → 2.0.0
Files written:
  .claude/FRAMEWORK-VERSION
  .claude/docs/FRAMEWORK-CHANGELOG.md

Commit these two files together with the framework changes that prompted this release.
Suggested commit message:
  chore: framework release v2.0.0
```
