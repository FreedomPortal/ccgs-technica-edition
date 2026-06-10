# Framework Maintenance — Change Impact Directory

When making a framework change, find the change type below and update every file listed.
Each entry answers: **what to touch** and **why**.

---

## Index

| Change Type | Section |
|-------------|---------|
| Add / rename / remove a skill | [Skills](#skills) |
| Add / rename / remove an agent | [Agents](#agents) |
| Add / change / remove a hook | [Hooks](#hooks) |
| Add / change / remove a rule | [Rules](#rules) |
| Add / change / remove a template | [Templates](#templates) |
| Change pipeline phases or steps | [Pipeline](#pipeline) |
| Change a skill's or agent's model tier | [Model Tiers](#model-tiers) |
| Change directory structure | [Directory Structure](#directory-structure) |
| Change agent memory protocol | [Agent Memory Protocol](#agent-memory-protocol) |
| Change sprint / production workflow | [Sprint Workflow](#sprint-workflow) |
| Upgrade engine or update API docs | [Engine Reference](#engine-reference) |
| Change collaboration protocol | [Collaboration Protocol](#collaboration-protocol) |
| Add / update a workflow example | [Examples](#examples) |

---

## Skills

### Add a skill

| File | What to do | Why |
|------|-----------|-----|
| `.claude/skills/[name]/SKILL.md` | Create | Skill definition itself |
| `.claude/docs/skills-reference.md` | Add row to correct section; update count in line 1 | Users browse this for discovery |
| `.claude/docs/workflow-catalog.yaml` | Add step under relevant phase if skill is phase-gated | `/next` reads this to surface the skill |
| `.claude/docs/coordination-rules.md` | Add to model-tier list if non-default (Haiku or Opus only) | Default Sonnet needs no entry |
| `.claude/settings.json` | Add hook if skill needs one | Hooks don't self-register |
| `docs/WORKFLOW-GUIDE.md` | Appendix B: add row; update section skill count; update "X slash commands" in header blockquote | Human-facing count shown to users |

### Rename a skill

All "Add a skill" targets, plus:

| File | What to do | Why |
|------|-----------|-----|
| `grep -r "/old-name" .claude/` | Find and update every reference | Skills call each other; stale references break |
| Session hook scripts (`session-start.sh`, etc.) | Update any references | Hooks may reference skill names in output |

### Remove a skill

| File | What to do | Why |
|------|-----------|-----|
| `.claude/skills/[name]/` | Delete directory | Removed skills should not linger |
| `.claude/docs/skills-reference.md` | Remove row; update count | Count shown to users on line 1 |
| `.claude/docs/workflow-catalog.yaml` | Remove step | `/next` would surface a dead command |
| `.claude/docs/coordination-rules.md` | Remove from model-tier list if present | Stale entries cause confusion |
| `grep -r "/[name]" .claude/` | Remove or replace all cross-references | Skills that call deleted skill will error |
| `docs/WORKFLOW-GUIDE.md` | Appendix B: remove row; update section count; update header total | Human-facing count goes stale |

---

## Agents

### Add an agent

| File | What to do | Why |
|------|-----------|-----|
| `.claude/agents/[name].md` | Create | Agent definition |
| `.claude/docs/agent-roster.md` | Add row to correct tier table | Skills consult roster for routing decisions |
| `.claude/docs/technical-preferences.md` | Add row to file-extension routing table if engine specialist | Coding agents use this table for dispatch |
| `.claude/docs/coordination-rules.md` | No change unless non-Sonnet model | Default Sonnet needs no entry |
| Skills that should delegate to it | Add `subagent_type: [name]` in relevant SKILL.md Task calls | Agent won't be used unless wired in |
| `docs/WORKFLOW-GUIDE.md` | Appendix A: add to lookup table + hierarchy diagram; update "X-agent system" count in header | Human-facing roster and count |

### Rename an agent

| File | What to do | Why |
|------|-----------|-----|
| `.claude/agents/[old-name].md` | Rename file | Definition file must match agent name |
| `.claude/docs/agent-roster.md` | Update name | Roster is authoritative |
| `.claude/docs/technical-preferences.md` | Update if listed in routing table | Broken routing silently falls back to wrong agent |
| `grep -r "subagent_type.*old-name" .claude/skills/` | Update every Task call | Spawning stale name errors at runtime |
| `docs/WORKFLOW-GUIDE.md` | Appendix A: update name in lookup table + diagram | |

### Remove an agent

Same as rename targets, but delete the `.claude/agents/` file and remove all references rather than updating them. Update the `docs/WORKFLOW-GUIDE.md` agent count in the header.

---

## Hooks

### Add a hook

| File | What to do | Why |
|------|-----------|-----|
| `.claude/settings.json` | Add hook entry under correct event key | Hooks are inert without settings registration |
| `tools/hooks/[hook-name].sh` | Create script | The script the hook calls |
| `.claude/docs/hooks-reference.md` | Add row to table | Users read this to understand automation |
| `.claude/docs/hooks-reference/[hook-name].md` | Create detail doc (optional but recommended) | Linked from hooks-reference.md for full spec |
| `.claude/docs/setup-requirements.md` | Add if hook needs external deps (e.g., PowerShell module, npm package) | New contributors need prerequisites |
| `docs/WORKFLOW-GUIDE.md` | Cross-Cutting hooks table: add row; update "X automated hooks" in header | Human-facing count |

### Remove a hook

| File | What to do | Why |
|------|-----------|-----|
| `.claude/settings.json` | Remove hook entry | Dangling entry will error on missing script |
| `tools/hooks/[hook-name].sh` | Delete | Dead code |
| `.claude/docs/hooks-reference.md` | Remove row | Users should not rely on removed automation |
| `.claude/docs/hooks-reference/[hook-name].md` | Delete if exists | |
| `docs/WORKFLOW-GUIDE.md` | Cross-Cutting hooks table: remove row; update header count | |

---

## Rules

### Add a rule

| File | What to do | Why |
|------|-----------|-----|
| `.claude/rules/[name].md` | Create | Rule definition |
| `.claude/docs/rules-reference.md` | Add row with path pattern and what it enforces | Agents consult this for context-appropriate rules |
| `CLAUDE.md` | Add `@.claude/rules/[name].md` only if rule should load globally | Global rules bloat every context; use path-scope instead |
| Skills/agents that should inject this rule | Pass rule content or path in Task prompt | Rules aren't auto-injected into subagents |

### Remove a rule

| File | What to do | Why |
|------|-----------|-----|
| `.claude/rules/[name].md` | Delete | |
| `.claude/docs/rules-reference.md` | Remove row | |
| `CLAUDE.md` | Remove `@` import if present | Broken `@` import causes load error |
| `grep -r "[name].md" .claude/` | Remove any Task-prompt injections | Dead path references cause silent skips |

---

## Templates

### Add a template

| File | What to do | Why |
|------|-----------|-----|
| `.claude/docs/templates/[name].md` | Create | Template file |
| Skills that use it | Reference path in SKILL.md output section | Template won't be used unless wired in |

### Change a template's structure

| File | What to do | Why |
|------|-----------|-----|
| `.claude/docs/templates/[name].md` | Edit | Primary change |
| `grep -r "[name].md" .claude/skills/` | Find skills that read and parse the template | If skill validates sections by name, changed headers break it |
| Existing files created from this template | No automatic update needed — templates are one-time scaffolds | Already-written docs are not regenerated |

---

## Pipeline

Changes to `.claude/docs/workflow-catalog.yaml` — phase names, step IDs, or step commands.

| File | What to do | Why |
|------|-----------|-----|
| `.claude/docs/workflow-catalog.yaml` | Primary edit | |
| `.claude/docs/skills-reference.md` | Update section headers if phase names change | Section headers mirror phase names |
| `.claude/docs/director-gates.md` | Update gate names if phase names change | Gate verdicts reference phase labels |
| `design/stages/stage.txt` | Update valid values if stage identifiers change | Stage file gates advancement checks |
| `/gate-check`, `/next`, `/project-stage-detect` SKILL.md | Verify hardcoded phase names match | These skills parse the catalog but may also hardcode phase IDs |
| `docs/WORKFLOW-GUIDE.md` | Table of Contents: add/rename phase; update phase section body; update gate-check phase list | Human-facing pipeline guide |

---

## Model Tiers

When changing which model a skill or agent uses:

| File | What to do | Why |
|------|-----------|-----|
| `.claude/skills/[name]/SKILL.md` | Update `model:` frontmatter | Actual runtime tier |
| `.claude/docs/coordination-rules.md` | Add / move / remove from Haiku or Opus lists | Reference list used by contributors creating new skills |
| `.claude/docs/agent-roster.md` | Update Model column if an agent's tier changes | Agents spawned without explicit model inherit from roster |

---

## Directory Structure

When adding, moving, or removing a top-level directory or well-known subdirectory:

| File | What to do | Why |
|------|-----------|-----|
| `.claude/docs/directory-structure.md` | Update tree | Primary reference; loaded by CLAUDE.md |
| Skills that hardcode paths | `grep -r "\"[path]\"" .claude/skills/` and update | Hardcoded paths silently break |
| `.claude/docs/context-management.md` | Update if session-state or drafts paths change | Session state paths documented here |
| `.claude/settings.json` `ignorePatterns` | Update if new directory should be excluded from scans | |
| `tools/hooks/*.sh` | Update any path references in hooks | Hooks often reference `production/`, `assets/`, etc. |
| `docs/CLAUDE.md` | Update if `docs/` subdirectory structure changes | Describes docs/ layout for contributors |
| `docs/engine-reference/README.md` | Update structure diagram if `engine-reference/` layout changes | Agents read this before using engine APIs |
| `docs/examples/README.md` | Update if `examples/` structure changes | Entry point for new contributors |

---

## Agent Memory Protocol

Changes to how agent memory files are structured, named, or sharded (`.claude/docs/agent-memory-protocol.md`):

| File | What to do | Why |
|------|-----------|-----|
| `.claude/docs/agent-memory-protocol.md` | Primary edit | |
| `.claude/docs/context-management.md` | Sync the "Crash-Safe Memory Protocol" section | Both documents describe the same protocol |
| `/checkpoint` SKILL.md | Verify memory paths and format match | Checkpoint writes to memory using these conventions |
| `/memory-shard` SKILL.md | Verify shard format matches | Shard skill restructures memory files |
| `/memory-prune` SKILL.md | Verify prune logic matches new format | Prune skill reads and deletes stale entries |

---

## Sprint Workflow

Changes to sprint close-out sequence, retro enforcement, or gate ordering:

| File | What to do | Why |
|------|-----------|-----|
| `.claude/rules/workflow.md` | Primary edit | Enforced rule |
| `.claude/docs/coordination-rules.md` | Sync "Sprint Close-Out Sequence" section | Both describe the same sequence; must stay identical |
| `/sprint-close` SKILL.md | Update orchestration sequence | Skill executes the sequence — must match the rule |
| `/sprint-plan` SKILL.md | Update retro-check gate logic | Sprint plan blocks until retro exists |
| `/gate-check` SKILL.md | Update if gate order changes | Gate-check validates readiness for advancement |

---

## Engine Reference

After upgrading the engine version, updating the LLM, or running `/refresh-docs`:

| File | What to do | Why |
|------|-----------|-----|
| `docs/engine-reference/[engine]/VERSION.md` | Update version, release date, verification date | Agents read this first to confirm engine version |
| `docs/engine-reference/[engine]/breaking-changes.md` | Add entries for the version transition | Prevents agents suggesting removed APIs |
| `docs/engine-reference/[engine]/deprecated-apis.md` | Move newly deprecated APIs; add "use Y instead" | Prevents agents using deprecated patterns |
| `docs/engine-reference/[engine]/current-best-practices.md` | Add new patterns introduced in this version | Prevents agents suggesting outdated idioms |
| `docs/engine-reference/[engine]/modules/*.md` | Update relevant subsystem files; set new "Last verified" date | Subsystem files scope what agents check |
| `docs/engine-reference/README.md` | Update `staleness_threshold_days` frontmatter only if staleness policy changes | Hook reads threshold to warn on stale files |

Use `/refresh-docs audit` to find empty stubs and stale files before a manual update pass. Use `/refresh-docs update [engine] [module] --web` to populate from official docs.

---

## Collaboration Protocol

When changing the collaborative workflow rules (Question→Options→Decision flow, approval gates, autonomous vs. user-driven behavior):

| File | What to do | Why |
|------|-----------|-----|
| `docs/COLLABORATIVE-DESIGN-PRINCIPLE.md` | Primary edit | Authoritative human-facing protocol doc |
| `CLAUDE.md` | Sync "Collaboration Protocol" section | Loaded every session; agents see this first |
| `.claude/docs/templates/collaborative-protocols/design-agent-protocol.md` | Sync if agent behavior changes | Template injected into design agent prompts |
| `.claude/docs/templates/collaborative-protocols/leadership-agent-protocol.md` | Sync | Template injected into leadership agent prompts |
| `.claude/docs/templates/collaborative-protocols/implementation-agent-protocol.md` | Sync | Template injected into coding agent prompts |
| `.claude/agents/*.md` | Review agents that bake in collaborative behavior | Agent definitions may hardcode the old flow |
| `docs/examples/README.md` | Add note if flow changes make existing examples outdated | Outdated examples teach wrong behavior |

---

## Examples

When adding, updating, or removing a workflow example session:

| File | What to do | Why |
|------|-----------|-----|
| `docs/examples/[session-name].md` | Create / edit / delete | The example itself |
| `docs/examples/README.md` | Add / update / remove entry in the index | Entry point; readers find examples here |
| `docs/examples/skill-flow-diagrams.md` | Update if a skill's flow structure changes materially | Diagram is a visual reference for onboarding |
| `docs/WORKFLOW-GUIDE.md` | Update any inline references if skill name or flow changes | Guide may link to or describe the skill |
