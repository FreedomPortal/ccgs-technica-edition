---
name: team-publish
description: "Orchestrate the publishing team through a publishing cycle. Coordinates publishing-manager (roadmap + store readiness), community-manager (platform activity + content calendar), and writer (copy drafting) in parallel. Produces a unified publishing status summary with prioritized action items."
argument-hint: "[launch | devlog | full]  — default: full"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Task, AskUserQuestion
agent: publishing-manager
---

When this skill is invoked, orchestrate the publishing team through a structured
publishing cycle. All three agents run in parallel — issue all Task calls before
waiting for any result.

## Team Composition

- **publishing-manager** — roadmap review, store page status, press kit status, launch readiness
- **community-manager** — platform activity, content calendar, metrics review
- **writer** — drafts copy: devlogs, patch notes, social posts, store description updates

## Modes

| Mode | Focus | When to use |
|------|-------|-------------|
| `launch` | Store readiness + pre-launch community push | Final weeks before launch |
| `devlog` | Content calendar + devlog draft for this cycle | End of sprint or milestone |
| `full` | Comprehensive review of all publishing domains | Monthly publishing audit |

Default: `full`

## How to Delegate

Use the Task tool to spawn each agent as a subagent:
- `subagent_type: publishing-manager`
- `subagent_type: community-manager`
- `subagent_type: writer`

Always provide full context in each agent's prompt — agents do not share state.
Spawn all three simultaneously; collect all results before Phase 3.

---

## Pipeline

### Phase 1: Load Context

Read before spawning agents:
1. `production/stage.txt` — current dev stage
2. `production/publishing/publishing-roadmap.md` — if exists
3. `production/publishing/community-status.md` — if exists
4. `production/session-state/active.md` — recent work (for writer)
5. Glob `production/sprints/` for most recent sprint plan (for writer)

Report:
> "Publishing cycle starting. Mode: [mode]. Stage: [stage]. Spawning publishing team in parallel."

---

### Phase 2: Parallel Team Execution

Issue all three Task calls simultaneously before waiting for any result.

**publishing-manager task** — pass: dev stage, publishing-roadmap.md contents (if
exists), list of files present in `production/publishing/`, mode.

Ask the publishing-manager to:
- Review `publishing-roadmap.md` for overdue and unlocked tasks given the current stage
- Report store page status: does `production/publishing/store-page*` exist? Is content current?
- Report press kit status: does `production/publishing/presskit*` exist? Is content current?
- *`launch` adds*: identify the top 3 publishing actions needed before launch
- *`full` adds*: full roadmap audit — overdue, unlocked, blocked, and recommended next tasks

Required output format:
```
## Publishing Manager Report
### Roadmap Status
[overdue / unlocked / on-track items]
### Store Page: [EXISTS | MISSING | NEEDS UPDATE]
### Press Kit: [EXISTS | MISSING | NEEDS UPDATE]
### Action Items
- [item] → suggested skill: /[skill-name]
```

---

**community-manager task** — pass: dev stage, community-status.md contents (if
exists), publishing-roadmap.md contents (if exists), mode.

Ask the community-manager to:
- Review platform activity: which platforms are active, silent, or not yet set up?
- Review posting cadence: is the content calendar on track?
- *`devlog` adds*: suggest 3 content angles for the devlog this cycle; propose social post topics for the next week
- *`launch` adds*: assess community readiness; identify platform gaps before launch
- *`full` adds*: full platform audit — activity, content type performance, strategy recommendations

Required output format:
```
## Community Manager Report
### Platform Activity
| Platform | Status | Last Post | Notes |
|----------|--------|-----------|-------|
### Content Calendar: [ON TRACK | BEHIND | NOT SET UP]
### Action Items
- [item] → suggested skill: /[skill-name]
```

---

**writer task** — pass: dev stage, session-state/active.md summary, most recent
sprint plan contents (if exists), mode.

Ask the writer to:
- *`devlog`*: draft a devlog post covering progress since the last devlog; draft 2–3 social media posts from the same content
- *`launch`*: draft a launch announcement (broad audience, no jargon); flag any store copy that needs updating
- *`full`*: identify the highest-priority copy gap (missing devlog, stale store description, no patch notes); draft the top item only

Writer output is draft text for user review — no files are written until the user
approves in Phase 4.

---

### Phase 3: Collate and Present

After all three agents complete, present the unified summary:

```markdown
## Publishing Status — [date] — Mode: [mode]

### Publishing Manager
[publishing-manager report verbatim]

### Community Manager
[community-manager report verbatim]

### Writer Output
[writer draft or gap list]

---

### Action Items (consolidated)
| Priority | Item | Owner | Suggested Skill |
|----------|------|-------|----------------|
| HIGH | [item] | [agent] | /[skill] |
| MED  | [item] | [agent] | /[skill] |
| LOW  | [item] | [agent] | /[skill] |
```

Then use `AskUserQuestion`:
```
question: "Publishing cycle complete. What would you like to do next?"
options:
  - "Approve writer output — save drafts to production/publishing/"
  - "Run /publish-devlog to develop the devlog further"
  - "Run /marketing-plan to update the roadmap"
  - "Run /community-plan to update platform strategy"
  - "Nothing — review only"
```

---

### Phase 4: Write Approved Copy

Only if the user approved writer output in Phase 3:
- Devlog draft → ask: "May I write to `production/publishing/devlog-[N]-[date].md`?"
- Social posts → ask: "May I write to `production/publishing/social-[date].md`?"
- Store copy update → ask: "May I write to `production/publishing/store-page-[date].md`?"

Never write any file without explicit per-file approval.

---

## Error Recovery Protocol

If any agent returns BLOCKED or cannot complete:

1. **Surface immediately**: "[AgentName]: BLOCKED — [reason]"
2. **Continue**: do not stop the cycle — proceed with available results
3. **Mark the gap**: that agent's section appears as BLOCKED in the summary
4. **Offer options** via `AskUserQuestion`:
   - "Skip [agent] and proceed with the other outputs"
   - "Retry [agent] with narrower scope"
   - "Stop here and resolve the blocker first"

Always produce a partial summary — never discard completed work because one agent blocked.

---

## Output

Unified publishing status covering: roadmap tasks, store/presskit status, platform
activity, content calendar, copy drafts, and a prioritized action item list.

Verdict: **COMPLETE** — cycle finished, action items surfaced.
Verdict: **PARTIAL** — one or more agents blocked; partial summary produced with noted gaps.
