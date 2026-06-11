# Skill Spec: /skill-specs
> **Category**: framework
> **Priority**: low
> **Spec written**: 2026-06-11

## Skill Summary

`/skill-specs` authors behavioral test spec files for skills in the CCGS Skill Testing Framework. It operates in two modes: single mode (given a skill name) reads the target SKILL.md, looks up the skill's category and priority from catalog.yaml, spawns a read-only subagent Task to draft the spec content, presents the draft inline for user review, then writes the spec file and updates catalog.yaml via two separate approval steps; batch/missing mode reads catalog.yaml to build a queue of skills with no spec file, displays the queue and asks for confirmation, spawns parallel Tasks to draft all specs simultaneously, collects results, presents a single consolidated write approval, and writes all spec files and updates catalog.yaml in one pass. Both modes produce output at `CCGS Skill Testing Framework/skills/[category]/[name].md`.

## Static Assertions

- [x] Frontmatter has all required fields (`name`, `description`, `argument-hint`, `user-invocable`, `allowed-tools`, `model`)
- [x] 2+ phase headings (Phase 1, 1B, 2, 3, 4, 5, 6 present)
- [x] Verdict keyword present (Phase 1B Step 6: `Verdict: COMPLETE`)
- [x] Write/Edit in allowed-tools: "May I write" language present (Phase 4 and Phase 5 both contain explicit "May I write" asks)
- [x] Next-step handoff present (Phase 6 lists `/skill-test spec`, `/skill-improve`, `/skill-specs missing`)

## Director Gate Checks

N/A — skill does not trigger any director gate reviews.

## Test Cases

---

**Case 1: Happy Path — Single Mode, New Spec**

Fixture:
- Argument: `gate-check`
- `.claude/skills/gate-check/SKILL.md` exists
- `CCGS Skill Testing Framework/catalog.yaml` has an entry for `gate-check` with `category: framework`, `priority: high`, and `spec: ""`
- `CCGS Skill Testing Framework/templates/skill-test-spec.md` exists
- `CCGS Skill Testing Framework/quality-rubric.md` exists
- No existing spec file on disk

Expected behavior:
1. Phase 1: argument parsed as `gate-check`, single-skill mode selected
2. Phase 1 verification: `.claude/skills/gate-check/SKILL.md` confirmed to exist
3. Phase 2: skill file read; catalog.yaml read for category (`framework`) and priority (`high`); no existing spec found, proceed without prompting
4. Phase 3: template and rubric read; Task spawned with substituted prompt containing skill name, category, priority, template, rubric section, and full SKILL.md content; subagent returns spec as plain text
5. Phase 4: spec presented inline; "May I write this spec to `CCGS Skill Testing Framework/skills/framework/gate-check.md`?" asked; waits for user confirmation
6. Phase 5 (after approval): directory created if needed; spec written to `CCGS Skill Testing Framework/skills/framework/gate-check.md`; second ask: "May I update `CCGS Skill Testing Framework/catalog.yaml` to record the spec path for gate-check?"; waits for confirmation; catalog `spec:` field updated
7. Phase 6: next-steps block displayed

Assertions:
- No files written before Phase 4 approval
- catalog.yaml not updated before Phase 5 catalog approval
- Task prompt contains SKILL.md content verbatim (not summarized)
- Spec output path matches pattern `CCGS Skill Testing Framework/skills/[category]/[name].md`
- Two distinct approval prompts issued (spec file, then catalog)
- Next-steps block references `/skill-test spec gate-check`, `/skill-improve gate-check`, and `/skill-specs missing`

Verdict: PASS if all six phases execute in order with two separate approval gates and no premature file writes.

---

**Case 2: Failure / Blocked — Skill Not Found**

Fixture:
- Argument: `nonexistent-skill`
- `.claude/skills/nonexistent-skill/SKILL.md` does NOT exist

Expected behavior:
1. Phase 1: argument parsed as `nonexistent-skill`
2. Existence check fails
3. Skill outputs: `"Skill 'nonexistent-skill' not found at .claude/skills/nonexistent-skill/SKILL.md."` and stops

Assertions:
- No Tasks spawned
- No files read beyond the existence check
- No approval prompts issued
- Output matches the exact stop message specified in Phase 1

Verdict: PASS if skill halts immediately with the prescribed error message and takes no further action.

---

**Case 3: Mode Variant — Batch (Missing) Mode**

Fixture:
- Argument: `missing`
- `CCGS Skill Testing Framework/catalog.yaml` contains 4 skills:
  - `alpha` (category: gameplay, spec: `""`)
  - `beta` (category: framework, spec: `""`)
  - `gamma` (category: framework, spec: `"CCGS Skill Testing Framework/skills/framework/gamma.md"`) — file EXISTS on disk
  - `delta` (category: production, spec field absent)
- Template and rubric files exist
- User confirms queue at the prompt

Expected behavior:
1. Phase 1: argument parsed as `missing`, batch mode selected (Phase 1B)
2. Step 1: catalog read; gamma skipped (spec path set and file exists); queue built: alpha, beta, delta (3 skills); display:
   ```
   Skills with no spec file: 3
   Skipped (spec path set and file exists on disk): 1
   Queue: 1. alpha (gameplay) priority: [...], 2. beta (framework) priority: [...], 3. delta (production) priority: [...]
   This will author 3 spec files. Proceed? [y/N]
   ```
3. Step 2: template and rubric read once
4. Step 3: 3 Tasks spawned in parallel, each reading its own SKILL.md; Tasks return text only
5. Step 4: results collected; summary displayed listing all 3 output paths; single "May I write all 3 spec files and update catalog.yaml?" prompt
6. Step 5 (after approval): 3 spec files written; catalog.yaml updated in one pass for all 3 skills
7. Step 6: completion summary displayed with counts

Assertions:
- gamma is not re-authored or overwritten
- All three Tasks spawned before any result is awaited (parallel, not sequential)
- Template and rubric loaded once, not per-Task
- Single consolidated write approval (not one per skill)
- catalog.yaml updated in a single edit pass
- Decline at Step 1 prompt results in immediate stop with no file writes

Verdict: PASS if queue correctly excludes gamma, Tasks run in parallel, and write gate is a single consolidated prompt.

---

**Case 4: Edge Case — Existing Spec, Update vs. Overwrite**

Fixture:
- Argument: `sprint-plan`
- `.claude/skills/sprint-plan/SKILL.md` exists
- `CCGS Skill Testing Framework/catalog.yaml` has `spec: "CCGS Skill Testing Framework/skills/production/sprint-plan.md"` for this skill
- `CCGS Skill Testing Framework/skills/production/sprint-plan.md` EXISTS on disk with prior content

Expected behavior:
1. Phase 1: argument parsed as `sprint-plan`
2. Phase 2: catalog read; existing spec path found and file confirmed on disk; prompt displayed:
   "A spec already exists at `CCGS Skill Testing Framework/skills/production/sprint-plan.md`. Overwrite it, or view and update the existing one?"
   Options: `Overwrite` | `Update` | `Cancel`
3a. If `Cancel`: skill stops immediately
3b. If `Overwrite`: proceeds to Phase 3 without reading existing spec (fresh draft)
3c. If `Update`: existing spec file read; Phase 3 proceeds with existing content as starting point

Assertions:
- Skill does not silently overwrite an existing spec; always prompts first
- Cancel path produces no file writes and no Tasks
- Update path reads the existing file before spawning the Task
- Overwrite path does not read the existing file before spawning the Task

Verdict: PASS if skill detects the existing spec and presents exactly the three-option prompt with correct behavior for each branch.

---

**Case 5: Edge Case — Missing Argument**

Fixture:
- `/skill-specs` invoked with no argument

Expected behavior:
1. Phase 1: no argument detected
2. Usage block displayed:
   ```
   Usage: /skill-specs [skill-name]
          /skill-specs missing
   Example: /skill-specs gate-check
   Example: /skill-specs missing
   ```
3. Skill stops

Assertions:
- Usage text matches the exact format specified in Phase 1
- No file reads, no Tasks, no approval prompts
- Skill halts after displaying usage

Verdict: PASS if skill outputs the usage block verbatim and takes no further action.

---

## Protocol Compliance

- [x] "May I write" before file writes — Phase 4 asks before writing spec; Phase 5 asks before updating catalog; Phase 1B Step 4 asks before all batch writes
- [x] Presents findings before approval — Phase 4 presents the authored spec inline before requesting write approval; Phase 1B Step 4 displays all output paths before the consolidated prompt
- [x] Ends with next step — Phase 6 provides explicit next-steps block; Phase 1B Step 6 provides equivalent next-steps block
- [x] No auto-create without approval — Collaborative Protocol section explicitly states "Never write files without asking"; Tasks are read-only (return text only, all writes in parent)

## Coverage Notes

**FR1**: Satisfied. All file writes target `CCGS Skill Testing Framework/skills/[category]/[name].md` and `CCGS Skill Testing Framework/catalog.yaml`. No game source paths referenced anywhere in the skill.

**FR2**: Partially satisfied. catalog.yaml is updated after spec writes, but the skill asks separately ("May I update catalog.yaml…") rather than offering it as a follow-up. The update is not optional in batch mode — it happens as part of the single consolidated approval. In single mode it is a separate explicit ask.

**FR3**: Not addressed. The skill prompts when a spec exists (Overwrite/Update/Cancel) but does not record the original content and does not offer a revert mechanism. This is a gap.

**FR4**: Not addressed. The skill produces spec files but does not emit or require the `<!-- SKILL: [name] | verdict: [PASS/WARN/FAIL] -->` block format in its own output or in the specs it generates. Whether spec files are expected to carry this block is not specified by the skill's written instructions.

**FR5**: Not addressed. The skill does not run a static check (C1–C7) on skills before authoring specs for them. It reads the SKILL.md and delegates to a subagent Task — no static assertion pass is performed first. This is a gap if FR5 is a strict requirement for all framework skills.

**Gap — No argument, wrong argument**: Phase 1 handles both cleanly (usage output + stop).

**Gap — catalog.yaml missing**: The skill does not specify behavior if `catalog.yaml` is absent or malformed. No error path is documented.

**Gap — Task failure in batch mode**: Phase 1B Step 4 notes "list any that returned errors" in the summary display but does not specify how to handle partial failure (e.g., whether to block the write gate or proceed with successful specs only).