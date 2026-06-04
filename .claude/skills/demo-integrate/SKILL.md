---
name: demo-integrate
description: "Backport improvements made during a demo build back into main production. Classifies each change as keep-demo-only / backport-to-main / needs-story. For Early Access: flags player-facing roadmap commitments as required 1.0 stories. Run after /demo-gate released."
argument-hint: "[demo-id] [--early-access]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, AskUserQuestion
---

# Demo Back-Integration

After a demo campaign wraps, improvements made under demo deadline pressure often benefit the main game.
This skill classifies those changes, generates a backport task list, and creates sprint stories where needed.

**Does not merge code** — outputs instructions and stories for `/dev-story`.

---

## Phase 1: Resolve Campaign

Read `$ARGUMENTS[0]` as demo-id. If not provided:
- Glob `production/demo/*/state.txt`
- Filter to campaigns with state `Released`, `Publishing`, or `Live`
- If only one: confirm and proceed
- If multiple: use `AskUserQuestion` to ask which campaign to integrate

Check for `--early-access` flag in arguments OR read `production/demo/[id]/demo-plan.md` for EA mode flag.

If state.txt does not exist or sub-stage is not `Released`, `Publishing`, or `Live`:
> "Demo campaign '[id]' is not yet Released. Run `/demo-gate [id] released` before integrating."
Stop.

---

## Phase 2: Read Campaign Artifacts

Read the following if they exist:
- `production/demo/[id]/state.txt` — current sub-stage
- `production/demo/[id]/demo-plan.md` or `design/demo/demo-plan.md` — goals, target event
- `design/demo/demo-scope.md` or `production/demo/[id]/demo-scope.md` — included/excluded content
- Any evaluation or playtest docs in `production/demo/[id]/` — known improvements made during demo
- `production/sprint-status.yaml` — current main production state
- Glob `production/epics/` — existing epic structure (to know where to attach new stories)

---

## Phase 3: Gather Change List

Use `AskUserQuestion`:

**Prompt:** "How were the demo build changes tracked?"
**Options:**
- `[A] Git branch — I can provide the branch name or commit range`
- `[B] Changelog or notes file — I have a list of what changed`
- `[C] I remember what changed — I'll describe the key changes`
- `[D] No tracking — the demo used the same build as main (nothing to integrate)`

**If [A]:** Ask for branch name or commit range. Use Grep/Glob on changed file paths to identify the scope of changes.

**If [B]:** Ask for the file path or paste location. Read it.

**If [C]:** Ask the user to list key changes. Record them before proceeding.

**If [D]:** Report "Nothing to integrate." and stop.

---

## Phase 4: Classify Each Change

For each change identified, classify into one of three categories and present to the user for confirmation before generating output:

| Category | Meaning | Action |
|----------|---------|--------|
| **keep-demo-only** | Belongs in demo build only — content gates, placeholder art, demo-specific UI, time limits, tutorial bypasses | Leave in demo branch; do not backport |
| **backport-to-main** | Improves the main game directly — bug fixes, performance improvements, balance changes, onboarding polish | Cherry-pick to main production |
| **needs-story** | Too large to cherry-pick; requires design review or is a new feature not present in main | Create sprint story for `/dev-story` |

**Classification heuristics:**
- Content gate (locks out non-demo content) → **keep-demo-only**
- Bug that also exists in main build → **backport-to-main**
- Performance improvement (rendering, load time, memory) → **backport-to-main**
- Onboarding or tutorial polish for a flow that exists in main → **backport-to-main**
- Balance data change applying to full game, not just demo scope → **backport-to-main**
- New mechanic or system added specifically for the demo → **needs-story**
- Large refactor introduced under demo deadline → **needs-story** (review before backporting)

When classification is ambiguous, present both options to the user.

---

## Phase 5: Early Access Roadmap Audit *(EA mode only)*

If Early Access mode is active:

1. Read `production/demo/[id]/ea-roadmap.md` if it exists, or extract EA commitments from demo-plan.md
2. For each player-facing commitment (features promised before 1.0):
   - Glob `production/epics/` to check if already tracked as a story or epic
   - If missing: classify as **Required 1.0 Story**

Output a table:

```
### EA Roadmap Commitments → Required 1.0 Stories

| Commitment | Already tracked? | Action |
|------------|----------------|--------|
| [Feature X promised to players] | No | Create required story |
| [Bug fix promised in EA update] | Yes (S5-04) | Confirm in correct epic |
```

> ⚠️ **EA integrity note:** These commitments were made to paying Early Access players. They must be delivered before 1.0 or players must be explicitly informed of any changes. Do not defer without community communication.

---

## Phase 6: Generate Integration Report Draft

Produce a structured integration report:

```markdown
# Demo Integration Report — [demo-id]

**Date**: [date]
**Campaign**: [demo-id]
**Early Access**: [Yes | No]
**Total changes reviewed**: [N]

## Keep Demo-Only ([N] items)
*Not backported — belong in the demo build only.*

- [Change description] — Reason: [content gate / placeholder / demo-specific flow]

## Backport to Main ([N] items)
*Apply these to main production:*

### 1. [Change description]
- **Files**: `[src/path/file.gd]`
- **Type**: [Bug fix | Performance | Balance | Onboarding polish]
- **Description**: [What changed and why it improves the main game]
- **Action**: Cherry-pick from demo branch OR manually apply the following change: [brief instruction]

### 2. ...

## Needs Story ([N] items)
*Too large to cherry-pick — create sprint stories:*

### Story: [Brief title]
- **Epic**: [Which epic this belongs to]
- **Description**: [What needs to be done]
- **Why from demo**: [What the demo revealed that motivates this work]
- **Priority suggestion**: [Must Have | Should Have | Nice to Have]

[EA only — omit if not EA:]
## Required 1.0 Stories — EA Commitments ([N] items)

[table from Phase 5]
```

Present the draft to the user before writing. Discuss and revise if needed.

---

## Phase 7: Write Approval

1. Ask: "May I write this integration report to `production/demo/[id]/integration-report.md`?"
   - If yes: write the file.

2. For each **needs-story** item: "May I create sprint story files for the [N] items that need stories? I'll write them to `production/epics/[epic-slug]/`."
   - If yes: write story files using the format found in existing story files at `production/epics/`
   - If no story template exists: use the format from the most recently modified story file in `production/epics/`

---

## Phase 8: Summary and Next Steps

```
Demo Integration — COMPLETE
===========================
Campaign: [demo-id]
Backport items: [N] (apply to main build manually or via /dev-story)
New stories: [N] (queued for sprint planning)
[EA: Required 1.0 stories: [N]]
Report: production/demo/[id]/integration-report.md

Next steps:
- Apply backport changes (listed in report) before closing this branch
- Add needs-story items to sprint backlog via /sprint-plan
[EA: - Review Required 1.0 stories with producer before next sprint — these are player commitments]
```

---

## Collaborative Protocol

- Never merge code — classify and instruct only
- Never invent changes — derive only from what the user provides or from existing files
- Present classification results to the user before generating output (Phase 4)
- Flag EA roadmap commitments with ⚠️ — these carry player trust implications
- Story files require explicit "May I write?" approval before creating
- Integration report requires explicit approval before writing
- When classification is ambiguous, surface the choice — don't pick silently
