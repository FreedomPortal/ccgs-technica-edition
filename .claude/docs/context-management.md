# Context Management

Context is the most critical resource in a Claude Code session. Manage it actively.

## Communication Efficiency

**Efficiency override: Adhere to global token-saving protocols.**
When proposing 'Options' for the Collaboration Protocol (Question -> Options -> Decision):
- List options as a concise bulleted list.
- Eliminate all preambles, introductory filler, and conversational sycophancy.
- Provide raw data or code snippets directly unless an explanation is requested.

## File-Backed State (Primary Strategy)

**The file is the memory, not the conversation.** Conversations are ephemeral and
will be compacted or lost. Files on disk persist across compactions and session crashes.

### Session State File

Maintain `production/session-state/active.md` as a living checkpoint. Update it
after each significant milestone:

- Design section approved and written to file
- Architecture decision made
- Implementation milestone reached
- Test results obtained

The state file should contain: current task, progress checklist, key decisions
made, files being worked on, and open questions.

### Status Line Block (Production+ only)

When the project is in Production, Polish, or Release stage, include a structured
status block in `active.md` that the status line script can parse:

```markdown
<!-- STATUS -->
Epic: Combat System
Feature: Melee Combat
Task: Implement hitbox detection
<!-- /STATUS -->
```

- All three fields (Epic, Feature, Task) are optional — include only what applies
- Update this block when switching focus areas
- The status line displays it as a breadcrumb: `Combat System > Melee Combat > Hitboxes`
- Remove or empty the block when no active work focus exists

After any disruption (compaction, crash, `/clear`), read the state file first.

## Crash-Safe Memory Protocol

**Write agent memory immediately — never defer to session end.**

A session crash loses everything not backed to a file. The session state file
captures task progress; agent memory files capture knowledge. Both must be
updated as discoveries happen, not batched at the end.

Write to agent memory the moment any of these are established:
- A comparable title, reference game, film, or inspiration is identified
- A design decision, pillar, anti-pillar, or settled question is confirmed
- A technical constraint, engine limitation, or architectural choice is made
- A production fact is established (scope, platform, monetization, timeline)
- A user preference or workflow feedback is given

**Routing guide:**

| Discovery type | Agent memory file |
|---------------|------------------|
| Creative / design / art | `creative-director/MEMORY.md` |
| Technical / engine / architecture | `technical-director/MEMORY.md` |
| Production / scope / schedule | `producer/MEMORY.md` |
| Code standards / skill conventions | `lead-programmer/MEMORY.md` |
| Workflow / collaboration preferences | User memory (`~/.claude/projects/.../memory/`) |

Use `/checkpoint` to explicitly flush all session discoveries to memory at any time.

Use `/memory-prune` at sprint boundaries or before `/gate-check` and `/architecture-review` to remove stale
forward-looking entries from agent memory files and `session-state/active.md`. Stale "Pending:" and "Next:"
entries can cause those skills to report false blockers or miss resolved issues.

### Incremental File Writing

When creating multi-section documents (design docs, architecture docs, lore entries):

1. Create the file immediately with a skeleton (all section headers, empty bodies)
2. Discuss and draft one section at a time in conversation
3. Write each section to the file as soon as it's approved
4. Update the session state file after each section
5. After writing a section, previous discussion about that section can be safely
   compacted — the decisions are in the file

This keeps the context window holding only the *current* section's discussion
(~3-5k tokens) instead of the entire document's conversation history (~30-50k tokens).

## Draft-First Protocol

**Write output before asking for approval — never the reverse.** Work products that
take more than a few seconds to generate must be written to disk before the approval
gate. Crashes, token limits, and computer restarts can strike at the `[y/N]` prompt.

**Rule:** Before any `AskUserQuestion` that asks for write approval ("May I write X?"),
write the work product to:

```
production/session-state/drafts/[skill]-draft-YYYYMMDD-HHMMSS.md
```

Then ask for approval. If approved: write to final destination. If crashed before
approval: draft persists on disk for recovery — maximum rework is re-running the
approval step, not the entire task.

Draft files live in `production/session-state/` (gitignored). Cheap to keep,
invaluable when something goes wrong.

**Autosave enforcement level** is configured in `production/autosave-mode.txt`:
- `off` — no reminders or blocks (reliable machine, fast iteration)
- `remind` — stderr reminder before approval gates (default if file missing)
- `enforce` — hard block until a draft file exists in `drafts/` (modified within 3 min)

Change the level with `/autosave-mode`.

**Skills that follow this protocol** (output is expensive to regenerate):
- `/code-review` — draft written to `drafts/` before Phase 9
- `/design-review` — draft written to `drafts/` before Phase 5
- `/sprint-plan` — draft written to `drafts/` before Phase 4 approval gate
- `/architecture-review` — draft written to `drafts/` before Phase 8 approval
- `/gate-check` — draft written to `drafts/` before Section 6 write approval
- **Subagents** (via `/dev-story`) — `SubagentStop` hook writes implementation summary to `drafts/`

## Proactive Compaction

- **Compact proactively** at ~60-70% context usage, not reactively at the limit
- **Use `/clear`** between unrelated tasks, or after 2+ failed correction attempts
- **Natural compaction points:** after writing a section to file, after committing,
  after completing a task, before starting a new topic
- **Focused compaction:** `/compact Focus on [current task] — sections 1-3 are
  written to file, working on section 4`

## Context Budgets by Task Type

- Light (read/review): ~3k tokens startup
- Medium (implement feature): ~8k tokens
- Heavy (multi-system refactor): ~15k tokens

## Subagent Delegation

Use subagents for research and exploration to keep the main session clean.
Subagents run in their own context window and return only summaries:

- **Use subagents** when investigating across multiple files, exploring unfamiliar code,
  or doing research that would consume >5k tokens of file reads
- **Use direct reads** when you know exactly which 1-2 files to check
- Subagents do not inherit conversation history — provide full context in the prompt

## Compaction Instructions

When context is compacted, preserve the following in the summary:

- Reference to `production/session-state/active.md` (read it to recover state)
- List of files modified in this session and their purpose
- Any architectural decisions made and their rationale
- Active sprint tasks and their current status
- Agent invocations and their outcomes (success/failure/blocked)
- Test results (pass/fail counts, specific failures)
- Unresolved blockers or questions awaiting user input
- The current task and what step we are on
- Which sections of the current document are written to file vs. still in progress

**After compaction:** Read `production/session-state/active.md` and any files being
actively worked on to recover full context. The files contain the decisions; the
conversation history is secondary.

## Recovery After Session Crash

If a session dies ("prompt too long") or you start a new session to continue work:

1. The `session-start.sh` hook will detect and preview `active.md` automatically
2. Read the full state file for context
3. Read the partially-completed file(s) listed in the state
4. Continue from the next incomplete section or task
