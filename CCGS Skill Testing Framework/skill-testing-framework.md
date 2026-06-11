# CCGS Skill Testing Framework — User Guide

Quality assurance infrastructure for Claude Code Game Studios skills and agents.
Tests the framework itself — not any game built with it.

---

## Overview

The framework validates `.claude/skills/*/SKILL.md` files and agent definitions across
three independent layers. Each layer targets a different kind of defect:

| Layer | Tool | What it checks |
|---|---|---|
| **Static** | `/skill-test static` | Structural compliance — frontmatter, phases, verdict keywords, protocol language |
| **Category Rubric** | `/skill-test category` | Behavioral correctness — does the skill fulfill its job contract for its category? |
| **Behavioral Spec** | `/skill-test spec` | Scenario correctness — does the skill produce correct output given specific fixtures? |

All three layers are combined in `/skill-test full [name]`. The catalog (`catalog.yaml`)
is the connective tissue that links skills to their category and spec file.

---

## Layer 1 — Static Linter

Seven universal checks applied to every skill, regardless of category.

| Check | Criteria | Failure level |
|---|---|---|
| **1 — Frontmatter fields** | `name`, `description`, `argument-hint`, `user-invocable`, `allowed-tools` all present | FAIL |
| **2 — Multiple phases** | ≥2 numbered phase headings (`## Phase N` or equivalent) | FAIL |
| **3 — Verdict keywords** | At least one of: `PASS`, `FAIL`, `CONCERNS`, `APPROVED`, `BLOCKED`, `COMPLETE`, `READY`, `COMPLIANT`, `NON-COMPLIANT` | FAIL |
| **4 — Collaborative protocol** | "May I write" language present; **FAIL** (not WARN) if `Write` or `Edit` is in `allowed-tools` but no ask-before-write language is found | FAIL / WARN |
| **5 — Next-step handoff** | Skill ends with a recommended next action or follow-up path | WARN |
| **6 — Fork context complexity** | If `context: fork` is set, ≥5 phase headings must be present | WARN |
| **7 — Argument hint plausibility** | `argument-hint` is non-empty and reflects the documented modes | WARN |

Run structural checks with:

```
/skill-test static [skill-name]     # Single skill
/skill-test static all              # All skills in .claude/skills/
```

---

## Layer 2 — Category Rubric

`quality-rubric.md` defines what a skill of each type **must do** to be considered
behaviorally correct. Each category's invariants are derived from the skill's job
contract within the CCGS collaborative architecture.

A metric is **PASS** when the skill's written instructions clearly satisfy the criterion.
A metric is **FAIL** when instructions are absent, ambiguous, or contradictory.
A metric is **WARN** when instructions partially address the criterion.

### Category Definitions

#### `gate`
**Skills**: `gate-check`

Gate skills control phase transitions. They must enforce correctness without
auto-advancing stage and must respect all three review modes.

| Metric | PASS criteria |
|---|---|
| **G1 — Review mode read** | Skill reads `production/session-state/review-mode.txt` before deciding which directors to spawn |
| **G2 — Full mode: all 4 directors** | In `full` mode, all 4 Tier-1 directors (CD, TD, PR, AD) PHASE-GATE prompts are invoked in parallel |
| **G3 — Lean mode: PHASE-GATE only** | In `lean` mode, only `*-PHASE-GATE` gates run; inline gates are skipped |
| **G4 — Solo mode: no directors** | In `solo` mode, no director gates spawn; each is noted as "skipped — Solo mode" |
| **G5 — No auto-advance** | Skill never writes `production/stage.txt` without explicit user confirmation via "May I write" |

---

#### `review`
**Skills**: `design-review`, `architecture-review`, `review-all-gdds`

Review skills read documents and produce structured verdicts. They must not trigger
director gates during the analysis phase.

| Metric | PASS criteria |
|---|---|
| **R1 — Read-only enforcement** | Reviewed document is never modified without explicit user approval |
| **R2 — 8-section check** | All 8 required GDD sections (or equivalent architectural sections) are evaluated explicitly |
| **R3 — Correct verdict vocabulary** | Verdict is exactly one of: APPROVED / NEEDS REVISION / MAJOR REVISION NEEDED (design) or PASS / CONCERNS / FAIL (architecture) |
| **R4 — No director gates during analysis** | Director gates do not spawn during analysis phases; post-analysis gates are acceptable for high-stakes skills |
| **R5 — Structured findings** | Output contains a per-section status table or checklist before the final verdict |

---

#### `authoring`
**Skills**: `design-system`, `quick-design`, `architecture-decision`, `ux-design`, `ux-review`, `art-bible`, `create-architecture`

Authoring skills create or update design documents collaboratively. Full authoring skills
use a section-by-section cycle; lightweight authoring skills use a single-draft pattern.

| Metric | PASS criteria |
|---|---|
| **A1 — Section-by-section cycle** | Full skills author one section at a time. Lightweight skills (quick-design, architecture-decision, create-architecture) may draft the complete document and ask once |
| **A2 — May-I-write per section** | Full skills ask before each section write. Lightweight skills ask once for the complete document |
| **A3 — Retrofit mode** | Skill detects if target file already exists and offers to update specific sections rather than overwriting. New-file-only skills exempt |
| **A4 — Director gate at correct tier** | Director gates run at the correct mode threshold (full/lean) — not in solo |
| **A5 — Skeleton-first** | Full skills create a file skeleton before filling content. Lightweight skills exempt |

---

#### `readiness`
**Skills**: `story-readiness`, `story-done`

Readiness skills validate stories before or after implementation.

| Metric | PASS criteria |
|---|---|
| **RD1 — Multi-dimensional check** | Skill checks ≥3 independent dimensions and reports each separately |
| **RD2 — Three verdict levels** | READY/COMPLETE > NEEDS WORK/COMPLETE WITH NOTES > BLOCKED |
| **RD3 — BLOCKED requires external action** | BLOCKED is reserved for issues that cannot be fixed by the story author alone |
| **RD4 — Director gate at correct mode** | QL-STORY-READY or LP-CODE-REVIEW gate spawns in `full`, skips in `lean`/`solo` with a noted skip message |
| **RD5 — Next-story handoff** | After completion, skill surfaces the next READY story from the active sprint |

---

#### `pipeline`
**Skills**: `create-epics`, `create-stories`, `dev-story`, `create-control-manifest`, `propagate-design-change`, `map-systems`

Pipeline skills produce artifacts that other skills consume.

| Metric | PASS criteria |
|---|---|
| **P1 — Correct output schema** | Each produced file follows the project template; skill references the template path |
| **P2 — Layer/priority ordering** | Epics and stories respect layer ordering (core → extended → meta) and priority fields |
| **P3 — May-I-write before each artifact** | Skill asks before creating each output file individually, not batch-approving all files at once |
| **P4 — Director gate at correct tier** | In-scope gates run in `full`, skip in `lean`/`solo` with noted skip |
| **P5 — Reads before writes** | Skill reads the relevant GDD/ADR/manifest before producing artifacts |

---

#### `analysis`
**Skills**: `consistency-check`, `balance-check`, `content-audit`, `code-review`, `tech-debt`, `scope-check`, `estimate`, `perf-profile`, `asset-audit`, `security-audit`, `test-evidence-review`, `test-flakiness`

Analysis skills scan the project and surface findings. They are read-only during
analysis and must ask before recommending any file writes.

| Metric | PASS criteria |
|---|---|
| **AN1 — Read-only scan** | Analysis phase uses only Read/Glob/Grep; no Write or Edit during the scan |
| **AN2 — Structured findings table** | Output includes a findings table or checklist with severity/priority per finding |
| **AN3 — No auto-write** | Suggested file writes are gated behind "May I write" |
| **AN4 — No director gates during analysis** | Analysis skills produce findings for human review; they do not spawn director gates |

---

#### `team`
**Skills**: `team-combat`, `team-narrative`, `team-audio`, `team-level`, `team-ui`, `team-qa`, `team-release`, `team-polish`, `team-live-ops`

Team skills orchestrate multiple specialist agents for a department.

| Metric | PASS criteria |
|---|---|
| **T1 — Named agent list** | Skill explicitly names which agents it spawns and in what order |
| **T2 — Parallel where independent** | Agents whose inputs are independent are spawned in parallel (single message, multiple Task calls) |
| **T3 — BLOCKED surfacing** | If any spawned agent returns BLOCKED or fails, skill surfaces it immediately and halts dependent work |
| **T4 — Collect all verdicts before proceeding** | Dependent phases wait for all parallel agents to complete |
| **T5 — Usage error on no argument** | Missing required argument outputs usage hint and stops without spawning agents |

---

#### `sprint`
**Skills**: `sprint-plan`, `sprint-status`, `milestone-review`, `retrospective`, `changelog`, `patch-notes`

Sprint skills read production state and produce reports or planning artifacts.

| Metric | PASS criteria |
|---|---|
| **SP1 — Reads sprint/milestone state** | Skill reads `production/sprints/` or `production/milestones/` before producing output |
| **SP2 — Correct sprint gate** | PR-SPRINT (planning) or PR-MILESTONE (milestone review) gate runs in `full`, skips in `lean`/`solo` |
| **SP3 — Structured output** | Output uses a consistent structure (velocity table, risk list, action items) rather than free prose |
| **SP4 — No auto-commit** | Sprint files and milestone records never written without "May I write" |

---

#### `demo`
**Skills**: `demo-build`, `demo-feedback`, `demo-gate`, `demo-integrate`, `demo-iterate`, `demo-plan`, `demo-playtest`, `demo-polish`, `demo-scope`, `demo-status`

Demo skills manage the isolated vertical slice pipeline.

| Metric | PASS criteria |
|---|---|
| **D1 — State tracking** | Skill reads/updates `production/demo/[id]/state.txt` to track sub-stage progression |
| **D2 — Content verification** | Artifact checks verify meaningful content, not just file existence, before PASS |
| **D3 — Manual check handling** | Unverifiable quality checks marked as `MANUAL CHECK NEEDED`, never assumed PASS |
| **D4 — Draft-first verdict** | Verdict written to `production/session-state/drafts/` before requesting approval |
| **D5 — Demo-track handoff** | Recommends the correct subsequent demo skill in the Next-Step section |

---

#### `qa`
**Skills**: `bug-report`, `bug-triage`, `qa-plan`, `regression-suite`, `smoke-check`, `soak-test`, `test-helpers`, `playtest-report`

QA skills produce test artifacts, coverage reports, and defect documentation.

| Metric | PASS criteria |
|---|---|
| **QS1 — Artifacts not implementation** | Primary output is test plans, bug reports, or coverage reports — not game code or bug fixes |
| **QS2 — Structured findings** | Output uses consistent schema with severity/priority fields per entry |
| **QS3 — No scope creep** | Skill flags gaps and defects; does not propose new features or design changes |
| **QS4 — May-I-write before artifacts** | All test plans, bug reports, and QA reports gated behind "May I write" |

---

#### `publish`
**Skills**: `export-build`, `publish-crowdfunding`, `publish-devlog`, `publish-pitch`, `publish-review`, `publish-social`, `publish-steam-page`, `community-plan`, `day-one-patch`, `dlc-design`, `launch-checklist`, `live-ops-plan`, `marketing-plan`, `press-outreach`, `publish-check`, `refine-copy`, `release-checklist`

Publish skills compile project materials into external-facing artifacts or manage the
publishing roadmap.

| Metric | PASS criteria |
|---|---|
| **PB1 — Source aggregation** | Skill reads from project sources (GDDs, `publishing-roadmap.md`, design docs) before producing output |
| **PB2 — May-I-write before output** | All generated artifacts gated behind "May I write" |
| **PB3 — No auto-publish** | Skill never pushes content to external platforms without explicit user confirmation |
| **PB4 — Retrofit detection** | If target file or roadmap already exists, skill offers to update rather than recreate |
| **PB5 — Destination-appropriate format** | Output format matches intended destination (store page, social post, press kit, checklist, etc.) |

---

#### `workflow`
**Skills**: `start`, `onboard`, `setup-engine`, `adopt`, `continue`, `next`, `checkpoint`, `autosave-mode`, `project-stage-detect`, `log-lesson`, `memory-prune`, `memory-shard`

Workflow skills manage session state, project setup, and meta-operations.

| Metric | PASS criteria |
|---|---|
| **WF1 — Session-state aware** | Skill reads `production/session-state/active.md` or relevant config before acting |
| **WF2 — No unilateral design decisions** | Skill surfaces options for the user; does not make binding design, architecture, or scope decisions |
| **WF3 — Config writes gated** | Writes to `CLAUDE.md`, settings files, or agent memory gated behind "May I write" |
| **WF4 — Idempotent handling** | Skill detects existing config or state and offers to update rather than silently overwrite |

---

#### `localization`
**Skills**: `l10n-cultural-review`, `l10n-integrate`, `l10n-prepare`, `l10n-qa`, `l10n-rtl`, `l10n-sync`, `l10n-vo`, `l10n-i18n`, `l10n-check`

Localization skills manage the string pipeline from source to translated delivery.

| Metric | PASS criteria |
|---|---|
| **LC1 — Scope declaration** | Skill explicitly states whether it operates on source strings, translation files, or both |
| **LC2 — May-I-write for string tables** | Modifications to `strings-*.json` or locale files gated behind "May I write" |
| **LC3 — No silent exclusions** | Locale exclusions, key omissions, or scope reductions are explicit user decisions |
| **LC4 — Pipeline handoff** | Skill ends with a clear reference to the next step in the localization pipeline |

---

#### `utility`
**Skills**: All skills not assigned to a named category above.

Utility skills are evaluated against the 7 static checks only. If the skill spawns
director gates, gate-mode logic must also be correct.

| Metric | PASS criteria |
|---|---|
| **U1 — Passes all 7 static checks** | `/skill-test static [name]` returns COMPLIANT with 0 FAILs |
| **U2 — Gate mode correct (if applicable)** | If the skill spawns any director gate, it reads review-mode and applies full/lean/solo logic correctly |

---

## Layer 3 — Behavioral Spec

Each skill and agent has a spec file containing 5 test cases with explicit fixture
descriptions and assertion checklists. Claude evaluates each assertion by reasoning
over the skill's written instructions — not code execution.

**Spec file locations:**
- Skills: `CCGS Skill Testing Framework/skills/[category]/[name].md`
- Agents: `CCGS Skill Testing Framework/agents/[tier]/[name].md`

**Protocol compliance assertions** are present in every spec:
- Skill uses "May I write" before file writes
- Skill presents findings before requesting approval
- Skill ends with a recommended next step
- Skill does not auto-create files without approval

Run behavioral spec tests with:

```
/skill-test spec [skill-name]
```

---

## Agent Rubric

Agent specs are validated against category-specific metrics. Each agent category
enforces the coordination rules defined in `.claude/docs/coordination-rules.md`.

| Category | Agents | Key metrics |
|---|---|---|
| `director` | creative-director, technical-director, producer, art-director | Correct verdict vocabulary; domain boundary respected; conflict escalation path; Opus model tier |
| `lead` | lead-programmer, narrative-director, audio-director, ux-designer, qa-lead, level-designer, systems-designer | Domain verdict; escalates out-of-domain conflicts; Sonnet model tier |
| `specialist` | gameplay-programmer, ai-programmer, engine-programmer, ui-programmer, sound-designer, ux-designer, writer, world-builder, and others | Stays in domain; no binding cross-domain decisions; defers correctly |
| `engine` | All Godot, Unity, and Unreal specialists | Version-aware (reads `docs/engine-reference/`); correct file-type routing; enforces engine-specific idioms |
| `qa` | qa-tester, qa-lead, security-engineer, accessibility-specialist | Produces artifacts not code; evidence format matches coding-standards.md; no scope creep |
| `operations` | devops-engineer, release-manager, live-ops-designer, community-manager, analytics-engineer, economy-designer, localization-lead | Domain ownership clear; delegates implementation; toolset matches role |

---

## The Catalog

`catalog.yaml` is the master registry for all skills and agents. It is read as
the **first action** in every test mode except `static all`.

Each skill entry tracks:

| Field | Purpose |
|---|---|
| `category` | Selects the rubric section for `/skill-test category` |
| `spec` | Path to the behavioral spec file for `/skill-test spec` |
| `priority` | `critical` / `high` / `medium` / `low` — used by `audit` to surface gaps |
| `last_static` / `last_static_result` | Date and result of last static check |
| `last_category` / `last_category_result` | Date and result of last category check |
| `last_spec` / `last_spec_result` | Date and result of last behavioral spec run |

---

## Commands Reference

| Command | Purpose | Token cost |
|---|---|---|
| `/skill-test static [name]` | 7 structural checks on one skill | Low (~1k) |
| `/skill-test static all` | Structural check across all skills | Low (~1k/skill) |
| `/skill-test category [name]` | Category rubric check on one skill | Low (~2k) |
| `/skill-test category all` | Category rubric across all categorized skills | Low (~2k/skill) |
| `/skill-test spec [name]` | Behavioral spec evaluation for one skill | Medium (~5k) |
| `/skill-test full [name]` | All three layers on one skill | Medium (~8k) |
| `/skill-test audit` | Coverage report: skills, agents, last test dates, gaps | Low (~3k total) |
| `/skill-test suite` | Git-aware batch run: test changed/untested only, write report | High (~8k × stale count) |
| `/skill-improve [name]` | Test → diagnose → fix → retest → keep or revert loop | Medium |
| `/skill-improve from-report [path]` | Human-gated batch fix from a suite report | Medium per skill |

---

## Automated Quality Workflow

The suite mode and from-report mode form a complete quality cycle:

```
/skill-test suite
  → git log detects changed/untested skills
  → runs full tests on stale skills only
  → writes results/skill-test-suite-YYYY-MM-DD.md
  → updates catalog.yaml

/skill-improve from-report results/skill-test-suite-YYYY-MM-DD.md
  → reads all FAIL / WARN blocks from report
  → processes one skill at a time (human gate between each)
  → each skill: diagnose → propose fix → ask approval → rewrite → retest → keep/revert
  → updates report blocks: FIXED / UNCHANGED / SKIPPED-BY-USER
  → on stop: writes QUEUE-POSITION marker for session resumption

/skill-test suite  (repeat)
  → only retests skills changed since last run
  → provides clean baseline after fixes
```

**Session crash recovery**: if `/skill-improve from-report` is interrupted, the report
retains a `<!-- QUEUE-POSITION: N -->` marker. Restarting with the same report path
resumes from that position.

**Token cost management**: suite mode skips CURRENT skills (unchanged since last test).
On a codebase where most skills are stable, only the modified subset is tested. The first
run after a long gap will be expensive; subsequent runs after targeted edits are cheap.

---

## Writing a New Spec

1. Copy `templates/skill-test-spec.md` to `skills/[category]/[skill-name].md`
2. Set the `spec:` field in `catalog.yaml` to the new path
3. Run `/skill-test spec [skill-name]` to validate

For agent specs, use `templates/agent-test-spec.md` and place the file under
`agents/[tier]/[agent-name].md`.

---

## What Keeps the Standard

Nothing in this framework is automatically enforced by CI. The standard is maintained
through two mechanisms:

1. **The rubric is declarative.** Assigning a skill to a category commits it to
   that category's invariants. The invariants are derived from the skill's job
   contract in the CCGS architecture, not from arbitrary style preferences.

2. **Coverage is visible.** `/skill-test audit` surfaces every skill and agent with
   its last-tested date and result. Skills that have never been tested, or whose
   category and spec fields are unset, appear as explicit gaps rather than silent
   unknowns.

When a spec test fails, treat it as a signal that requires investigation — the spec
may encode a pre-existing bug. Correct the skill first, then update the spec to
reflect the fixed behavior.
