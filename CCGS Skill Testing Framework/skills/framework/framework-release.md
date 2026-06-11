# Skill Spec: /framework-release
> **Category**: framework
> **Priority**: low
> **Spec written**: 2026-06-11

## Skill Summary

`/framework-release` cuts a versioned semver release of the CCGS:TE framework. It reads the current version from `.claude/FRAMEWORK-VERSION`, diffs the working tree against the commit that last touched that file, buckets changes by type (skills, agents, pipeline, docs, rules, hooks, config), runs automated breaking-change detection across four signal sources (deleted/renamed skills, changed `id:` fields, deleted agents, pipeline phase ID changes), proposes a MAJOR/MINOR/PATCH bump with justification, drafts structured release notes from the bucketed diff, and — on explicit user approval — prepends an entry to `.claude/docs/FRAMEWORK-CHANGELOG.md` and overwrites `.claude/FRAMEWORK-VERSION`. A `--dry-run` flag prints what would be written without touching any files. Intended for framework maintainers only; not for use during game development.

---

## Static Assertions

- [ ] Frontmatter has all required fields (`name`, `description`, `argument-hint`, `user-invocable`, `allowed-tools`)
- [ ] 2+ phase headings (Phase 1 through Phase 6 present — 6 phases)
- [ ] Verdict keyword present (`Verdict: COMPLETE` in Phase 6 output block)
- [ ] If Write/Edit in allowed-tools: "May I write" language present (Phase 5: "May I write this release to FRAMEWORK-CHANGELOG.md and update FRAMEWORK-VERSION to [VERSION]?")
- [ ] Next-step handoff present (Phase 6 "Recommended Next Steps" block with commit and tag instructions)

---

## Director Gate Checks

N/A — skill contains no director review steps and does not explicitly trigger any director agent.

---

## Test Cases

### Case 1: Happy Path — Standard MINOR Release

**Fixture:**
- `.claude/FRAMEWORK-VERSION` exists containing `1.2.0`
- `git log -1` returns a valid BASE_REF commit SHA
- Diff shows: 2 new `SKILL.md` files (status `A`), 3 modified `SKILL.md` files (status `M`), 1 modified doc file — no deletions, no `id:` field changes
- User selects option 1 (Confirm MINOR bump → `1.3.0`) in Phase 4
- User selects option 1 (Yes — write both files) in Phase 5

**Expected behavior:**
- Phase 1: reads version `1.2.0`, resolves BASE_REF from `git log`
- Phase 2: buckets 2 additions into Skills, 3 modifications into Skills, 1 into Docs; exclusion list paths are skipped
- Phase 3: no breaking changes detected
- Phase 4: proposes MINOR (`1.3.0`), presents summary with 2 new skills + 3 updates + 1 doc change
- Phase 5: drafts release notes with "New Skills" and "Updated Skills" sections; shows full draft; asks "May I write this release to FRAMEWORK-CHANGELOG.md and update FRAMEWORK-VERSION to 1.3.0?"
- Phase 6: prepends new entry to `.claude/docs/FRAMEWORK-CHANGELOG.md`; overwrites `.claude/FRAMEWORK-VERSION` with `1.3.0`; prints "Framework version bumped: 1.2.0 → 1.3.0"; does NOT commit or tag

**Assertions:**
- `.claude/FRAMEWORK-VERSION` contains exactly `1.3.0` (no trailing whitespace beyond single newline)
- New changelog entry is prepended (not appended); existing entries intact
- Exclusion list files absent from release notes
- "Breaking Changes" section omitted from release notes
- Commit/tag suggested but not executed

**Verdict:** PASS

---

### Case 2: Failure / Blocked — User Cancels at Version Confirmation

**Fixture:**
- `.claude/FRAMEWORK-VERSION` exists containing `2.0.0`
- Diff shows 1 deleted `SKILL.md` (BREAKING) and 2 modified docs
- Phase 4 user selects option 4 (Cancel)

**Expected behavior:**
- Phases 1–3 complete normally; MAJOR bump (`3.0.0`) proposed with breaking changes listed
- Phase 4: AskUserQuestion presents 4 options; user selects Cancel
- Skill stops; no files written; no Phase 5 or Phase 6 executed

**Assertions:**
- `.claude/FRAMEWORK-VERSION` unchanged (still `2.0.0`)
- `.claude/docs/FRAMEWORK-CHANGELOG.md` unchanged
- No write tools invoked after cancel

**Verdict:** PASS (skill correctly gates on user confirmation)

---

### Case 3: Mode Variant — `--dry-run` Flag

**Fixture:**
- `.claude/FRAMEWORK-VERSION` exists containing `1.0.0`
- `--dry-run` argument passed
- Diff shows 1 new agent (MINOR bump → `1.1.0`)
- User confirms version in Phase 4 (option 1)
- User approves in Phase 5 (option 1)

**Expected behavior:**
- Phases 1–5 execute normally including version confirmation and approval gate
- Phase 6: prints "DRY RUN — no files written. Would have written:" followed by the would-be changelog entry and new version string
- No Write tool calls executed

**Assertions:**
- No files written to disk
- Output contains "DRY RUN" marker
- Would-be changelog entry and version string are printed
- Skill stops after dry-run output (does not proceed to actual write)

**Verdict:** PASS

---

### Case 4: Edge Case — First Release (FRAMEWORK-VERSION Missing)

**Fixture:**
- `.claude/FRAMEWORK-VERSION` does not exist (or is empty)
- Working tree has 10 skill files, 3 agent files, full docs directory — all new
- User confirms MINOR bump (all additions, no breaking changes) → `1.0.0`

**Expected behavior:**
- Phase 1: file missing or empty → sets current version to `1.0.0`; runs `git hash-object -t tree /dev/null` to get empty tree SHA as BASE_REF
- Phase 2: all framework files appear as `A` (added) against empty tree
- Phase 3: no deletions or renames — no breaking changes
- Phase 4: MINOR bump proposed (new skills/agents); current version shown as `1.0.0`, proposed as `1.1.0`

  Wait — on first release the starting version IS `1.0.0`. The proposed bump of MINOR would yield `1.1.0`. The skill sets current to `1.0.0` then applies bump rules; if any skills are added it proposes MINOR → `1.1.0`. (If truly nothing existed before, `1.0.0` is the starting point per Phase 1 instructions; MINOR bump yields `1.1.0`.)

- Phase 5: drafts release notes; shows "New Skills" / "New Agents" sections with all additions
- Phase 6 on approval: creates `.claude/FRAMEWORK-VERSION` with new version; creates or overwrites `.claude/docs/FRAMEWORK-CHANGELOG.md` with header + first entry

**Assertions:**
- `git hash-object -t tree /dev/null` used as BASE_REF (not `git log`)
- All skills/agents listed under "New Skills" / "New Agents" in notes
- No "Breaking Changes" section
- `.claude/FRAMEWORK-VERSION` file created (did not previously exist)

**Verdict:** PASS

---

### Case 5: Most Relevant Variant — Exclusion List Enforcement

**Fixture:**
- `.claude/FRAMEWORK-VERSION` exists containing `1.5.0`
- Diff includes changes to ALL four excluded files:
  - `.claude/FRAMEWORK-VERSION` (M)
  - `.claude/docs/FRAMEWORK-CHANGELOG.md` (M)
  - `.claude/docs/framework-maintenance.md` (M)
  - `.claude/skills/framework-release/SKILL.md` (M)
- Diff also includes 1 modified non-excluded skill (`SKILL.md` in a different skill directory)

**Expected behavior:**
- Phase 2: all four excluded paths are skipped when parsing diff output; only the non-excluded skill modification is bucketed
- Phase 3: no breaking changes (modification only, and `id:` field unchanged in the non-excluded skill)
- Phase 4: PATCH bump proposed (`1.5.1`) — only 1 skill update, no additions
- Release notes contain only the 1 non-excluded skill under "Updated Skills"
- None of the four excluded files appear in release notes under any section

**Assertions:**
- Exclusion list files absent from all bucketed output
- Summary count reflects only non-excluded changes (1 skill update)
- FRAMEWORK-CHANGELOG.md and FRAMEWORK-VERSION changes do not appear as "Other changes"
- `framework-release/SKILL.md` does not appear as an "Updated Skills" entry

**Verdict:** PASS

---

## Protocol Compliance

- [ ] "May I write" before file writes — Phase 5 explicitly asks "May I write this release to FRAMEWORK-CHANGELOG.md and update FRAMEWORK-VERSION to [VERSION]?" via AskUserQuestion before any Write in Phase 6
- [ ] Presents findings before approval — Phase 4 presents full change summary before version confirmation; Phase 5 shows full release notes draft before write approval
- [ ] Ends with next step — Phase 6 output block includes "Recommended Next Steps" with commit and tag instructions
- [ ] No auto-create without approval — Phase 6 write is gated on Phase 5 AskUserQuestion option 1; `--dry-run` bypasses write entirely

---

## Coverage Notes

- **FR1**: Satisfied — skill only reads/writes `.claude/FRAMEWORK-VERSION`, `.claude/docs/FRAMEWORK-CHANGELOG.md`, and reads `.claude/skills/*/SKILL.md` and `.claude/agents/*.md`. No game source paths (`src/`, `assets/`, `design/`) are referenced or modified.
- **FR2**: Not applicable — this skill does not change any skill's test state and makes no reference to `catalog.yaml`.
- **FR3**: Not applicable — skill overwrites `FRAMEWORK-VERSION` but does not overwrite any `SKILL.md`. The changelog is prepended (not overwritten in full). No revert offer is documented.
- **FR4**: Not applicable — skill does not emit a `<!-- SKILL: ... | verdict: ... -->` block. It is a framework tooling skill, not a skill-test runner.
- **FR5**: Not applicable — skill has no static check phase and does not invoke any static checker. It is a release-cutting tool, not a test/lint tool.