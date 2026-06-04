# CCGS Pipeline Redesign — 2026-06-05

**Status:** Design approved — pending implementation  
**Scope:** CCGS base + CCGS:TE  
**Author:** FreedomPortal / Technica Games  

---

## Problem

The existing 7-stage pipeline skips two real development phases and misplaces two others.

**Current pipeline:**
```
Concept → Systems Design → Technical Setup → Pre-Production → Production → Polish → Release
```

**Gaps:**
1. **No Prototype stage.** `/prototype` skill exists but there is no named stage for it. A developer doing a 1-hour vibe-code session has no pipeline home. The framework offers no continuity path from throwaway prototype into full game design — the developer must re-explain the game concept from scratch when entering Systems Design.
2. **No Vertical Slice stage.** `/vertical-slice` skill exists but Pre-Production flows directly into Production. A project enters "Production" without having proven the full game loop works. The word "Production" culturally implies "we know it works; now we build content" — which is untrue at this point.
3. **Demo misplaced.** Demo skills are distributed across Pre-Production, Production, and Polish as if demo is a stage-bounded activity. Culturally, a demo is built by cutting content from a near-complete game, or making the game shippable before Polish is done. It is an external-facing product, not an internal milestone. It has no single stage home.
4. **No Demo track state.** The demo skill chain (7 skills) has no unified tracking — no state file, no gate skill, no status skill. Each skill only checks its own immediate prerequisite.

---

## Design Decisions

### Decision 1: Two new stages

Insert `Prototype` and `Vertical Slice` into the main pipeline.

**New 9-stage pipeline:**
```
Concept → Prototype → Systems Design → Technical Setup → Pre-Production → Vertical Slice → Production → Polish → Release
```

**`Prototype` stage:**
- Purpose: prove the core mechanic is worth designing before writing GDDs
- Entry: after Concept gate passes
- Exit gate: `/prototype` REPORT.md with PROCEED verdict
- Key property: game concept document and prototype report carry forward automatically to Systems Design — developer does not re-explain the game
- Vibe-coding, throwaway code, HTML builds, paper prototypes all live here
- Existing skill: `/prototype` (no changes to skill needed)

**`Vertical Slice` stage:**
- Purpose: prove the full game loop works at production quality before committing to full content production
- Entry: after Pre-Production gate passes (GDDs, architecture, UX specs complete)
- Exit gate: personal playtest pass (developer must play it, not just build it)
- Key property: "Production" now means what it should — the team knows the game works and is building content
- Existing skill: `/vertical-slice` (no changes to skill needed; wording already correct)

### Decision 2: Demo as a parallel track, not a stage

Demo and Early Access are how the game is presented to players. They are not development milestones. A demo can be built and shipped at multiple points during Production and Polish. Treating it as a stage creates false sequencing.

**Demo track:**
- Parallel branch from main pipeline
- Available when: `stage.txt` = `Production` or `Polish`
- Multiple demo campaigns can run sequentially (Steam Next Fest, always-on store demo, press build)
- Each campaign has its own state file: `production/demo/[demo-id]/state.txt`

**Demo sub-stages (within track):**
```
Planning → Scoping → Building → Playtesting → Evaluating → Iterating → Polishing → Released
```

**Early Access variant:**
- Early Access = Demo track + publishing requirements layer
- Activated by `--early-access` flag on `/demo-plan`
- Adds sub-stages after `Released`: `Publishing` → `Live`
- Publishing layer adds: store page live, EA pricing set, EA roadmap communicated to players, `/publish-check` EA requirements satisfied
- EA is not a separate pipeline — it is a Demo campaign that ships a full (unfinished) game build instead of a scoped demo slice

### Decision 3: Demo track needs its own tracking infrastructure

Mirror the main pipeline's `stage.txt` + `/gate-check` + `/project-stage-detect` pattern.

**New artifacts and skills:**

| What | Main pipeline equivalent | Demo track |
|------|-------------------------|------------|
| State file | `production/stage.txt` | `production/demo/[id]/state.txt` |
| Stage detection | `/project-stage-detect` | `/demo-status` (NEW) |
| Advancement gate | `/gate-check` | `/demo-gate` (NEW) |
| Back-integration | n/a | `/demo-integrate` (NEW) |

### Decision 4: Post-demo integration skill

Demo work often improves the game under external deadline pressure: bug fixes, balance changes, performance improvements, onboarding polish. These improvements should not be stranded in the demo branch.

`/demo-integrate`:
- Reads demo build changes against main production state
- Classifies each change: **keep-demo-only** / **backport-to-main** / **needs-story** (too large, create sprint story)
- For Early Access: flags player-facing roadmap commitments as stories required before 1.0
- Output: backport task list + new sprint stories (if any)
- Does not merge code — outputs instructions and stories for `/dev-story`

---

## Implementation Scope

### Phase 1 — Pipeline stages (gate-check + detect)

Files to update:
- `.claude/skills/gate-check/SKILL.md` — add `Prototype` and `Vertical Slice` to stage list and gate definitions
- `.claude/skills/project-stage-detect/SKILL.md` — add both new stages to detection logic
- `.claude/docs/templates/project-stage-report.md` — add both new stages to stage name list
- `README.md` — update pipeline integration table (remove demo from stage rows; add Demo track row)
- `CCGS Skill Testing Framework/skills/utility/project-stage-detect.md` — update static assertions (now 9 stage names)

### Phase 2 — Demo track infrastructure

New files:
- `.claude/skills/demo-status/SKILL.md` — detection skill (Haiku tier, read-only)
- `.claude/skills/demo-gate/SKILL.md` — advancement gate skill (Sonnet tier)
- `.claude/skills/demo-integrate/SKILL.md` — post-demo back-integration skill (Sonnet tier)

### Phase 3 — Early Access integration

Files to update:
- `.claude/skills/demo-plan/SKILL.md` — add `--early-access` flag handling
- `.claude/skills/demo-build/SKILL.md` — add EA publishing checklist gate
- New file: `.claude/docs/templates/demo-state-template.md` — state file format for demo campaigns

### Phase 4 — Documentation

Files to update:
- `README.md` — update pipeline section with 9-stage diagram and Demo track section
- `docs/WORKFLOW-GUIDE.md` — add Prototype stage, Vertical Slice stage, Demo track workflow
- `CCGS Skill Testing Framework/catalog.yaml` — add entries for demo-status, demo-gate, demo-integrate

---

## What Does Not Change

- Systems Design, Technical Setup, Pre-Production, Production, Polish, Release stages — unchanged
- All existing demo skills (`/demo-plan` through `/demo-polish`) — content unchanged, only context updated
- Post-Launch track — remains a parallel track, not a stage (CCGS:TE handles this)
- `/vertical-slice` and `/prototype` skill content — no changes needed; they already describe correct behavior

---

## Stage Gate Summary (new)

| Transition | Gate skill | Key exit artifact |
|------------|-----------|-------------------|
| Concept → Prototype | `/gate-check prototype` | Concept doc + pillars defined |
| Prototype → Systems Design | `/gate-check systems-design` | `/prototype` REPORT.md with PROCEED verdict |
| Systems Design → Technical Setup | `/gate-check technical-setup` | All MVP GDDs authored + reviewed |
| Technical Setup → Pre-Production | `/gate-check pre-production` | Engine configured, architecture ADRs written |
| Pre-Production → Vertical Slice | `/gate-check vertical-slice` | GDDs reviewed, control manifest written, UX specs done |
| Vertical Slice → Production | `/gate-check production` | Personal playtest pass + `/vertical-slice` PROCEED verdict |
| Production → Polish | `/gate-check polish` | Feature complete (all epics closed or deferred) |
| Polish → Release | `/gate-check release` | QA pass, platform cert ready, store page live |

---

*This document is the design record for the CCGS pipeline redesign. Implementation tracked in sprint backlog.*
