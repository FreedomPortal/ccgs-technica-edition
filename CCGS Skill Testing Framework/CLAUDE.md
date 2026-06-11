# CCGS Skill Testing Framework — Claude Instructions

This folder is the quality assurance layer for the Claude Code Game Studios skill/agent
framework. It is self-contained and separate from any game project.

## Key files

| File | Purpose |
|------|---------|
| `catalog.yaml` | Master registry for all 108 skills and 52 agents. Contains category, spec path, and last-test tracking fields. Always read this first when running any test command. |
| `quality-rubric.md` | Category-specific pass/fail metrics. Read the matching `###` section for the skill's category when running `/skill-test category`. |
| `skills/[category]/[name].md` | Behavioral spec for a skill — 5 test cases + protocol compliance assertions. |
| `agents/[tier]/[name].md` | Behavioral spec for an agent — 5 test cases + protocol compliance assertions. |
| `templates/skill-test-spec.md` | Template for writing new skill spec files. |
| `templates/agent-test-spec.md` | Template for writing new agent spec files. |
| `results/` | Written by `/skill-test spec` when results are saved. Gitignored. |

## Path conventions

- Skill specs: `CCGS Skill Testing Framework/skills/[category]/[name].md`
- Agent specs: `CCGS Skill Testing Framework/agents/[tier]/[name].md`
- Catalog: `CCGS Skill Testing Framework/catalog.yaml`
- Rubric: `CCGS Skill Testing Framework/quality-rubric.md`

The `spec:` field in `catalog.yaml` is the authoritative path for each skill/agent spec.
Always read it rather than guessing the path.

## Skill categories

```
gate        → gate-check
review      → design-review, architecture-review, review-all-gdds
authoring   → design-system, quick-design, architecture-decision, art-bible,
              create-architecture, ux-design, ux-review, brainstorm, asset-spec,
              mod-support
readiness   → story-readiness, story-done
pipeline    → create-epics, create-stories, dev-story, create-control-manifest,
              propagate-design-change, map-systems, prototype, reverse-document,
              analytics-setup, test-setup
analysis    → consistency-check, balance-check, content-audit, code-review,
              tech-debt, scope-check, estimate, perf-profile, asset-audit,
              security-audit, test-evidence-review, test-flakiness
qa          → bug-report, bug-triage, qa-plan, regression-suite, smoke-check,
              soak-test, test-helpers, playtest-report
team        → team-combat, team-narrative, team-audio, team-level, team-ui,
              team-qa, team-release, team-polish, team-live-ops
sprint      → sprint-plan, sprint-status, milestone-review, retrospective,
              changelog, patch-notes
demo        → demo-build, demo-feedback, demo-gate, demo-integrate, demo-iterate,
              demo-plan, demo-playtest, demo-polish, demo-scope, demo-status
publish     → export-build, publish-crowdfunding, publish-devlog, publish-pitch,
              publish-review, publish-social, publish-steam-page,
              community-plan, day-one-patch, dlc-design, launch-checklist,
              live-ops-plan, marketing-plan, press-outreach, publish-check,
              refine-copy, release-checklist
localization → l10n-i18n, l10n-prepare, l10n-integrate, l10n-qa, l10n-sync,
              l10n-cultural-review, l10n-rtl, l10n-vo, l10n-check
workflow    → start, onboard, setup-engine, adopt, continue, next, checkpoint,
              autosave-mode, project-stage-detect, log-lesson, memory-prune,
              memory-shard
framework   → skill-test, skill-improve, framework-release
analytics   → ab-test, economy-simulation, player-segmentation, retention-analysis,
              telemetry-design
utility     → ccgs-merge, hotfix
```

## Agent tiers

```
directors   → creative-director, technical-director, producer, art-director
leads       → lead-programmer, narrative-director, audio-director, ux-designer,
              qa-lead, release-manager, localization-lead
specialists → gameplay-programmer, engine-programmer, ui-programmer,
              tools-programmer, network-programmer, ai-programmer,
              level-designer, sound-designer, technical-artist
godot       → godot-specialist, godot-gdscript-specialist, godot-csharp-specialist,
              godot-shader-specialist, godot-gdextension-specialist
unity       → unity-specialist, unity-ui-specialist, unity-shader-specialist,
              unity-dots-specialist, unity-addressables-specialist
unreal      → unreal-specialist, ue-gas-specialist, ue-replication-specialist,
              ue-umg-specialist, ue-blueprint-specialist
operations  → devops-engineer, security-engineer, performance-analyst,
              analytics-engineer, community-manager
creative    → writer, world-builder, game-designer, economy-designer,
              systems-designer, prototyper
```

## Workflow for testing a skill

1. Read `catalog.yaml` to get the skill's `spec:` path and `category:`
2. Read the skill at `.claude/skills/[name]/SKILL.md`
3. Read the spec at the `spec:` path
4. Evaluate assertions case by case
5. Offer to write results to `results/` and update `catalog.yaml`

## Workflow for improving a skill

Use `/skill-improve [name]`. It handles the full loop:
test → diagnose → propose fix → rewrite → retest → keep or revert.

## Spec validity note

Specs in this folder describe **current behavior**, not ideal behavior. They were
written by reading the skills, so they may encode bugs. When a skill misbehaves in
practice, correct the skill first, then update the spec to match the fixed behavior.
Treat spec failures as "this needs investigation," not "the skill is definitively wrong."

## This folder is deletable

Nothing in `.claude/` imports from here. Deleting this folder has no effect on the
CCGS skills or agents themselves. `/skill-test` and `/skill-improve` will report that
`catalog.yaml` is missing and guide the user to initialize it.
