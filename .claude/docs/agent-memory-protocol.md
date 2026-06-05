# Agent Memory Protocol — Sharded Format

Agent memory files in `.claude/agent-memory/[agent]/` use a two-tier structure
to keep token cost low while preserving full history.

## Directory Layout

```
.claude/agent-memory/[agent]/
  MEMORY.md          ← index + loading instructions (always loaded via memory: project)
  shards/
    [topic].md       ← one file per topic, loaded on demand
```

## MEMORY.md — Index Format

```markdown
# [Agent] — Memory Index

> **Shard loading protocol**: Read this index on startup. For any topic relevant
> to your current task, load the corresponding shard via Read tool before proceeding.
> Load only what applies — do not read all shards.

## Shards

| Topic | File | Summary |
|-------|------|---------|
| [topic] | shards/[file].md | [one-line summary of what's in it] |
```

**Rules for MEMORY.md:**
- Index only — no substantive content
- One row per shard
- Summary must be specific enough to judge relevance without opening the file
- Target: under 30 lines total

## Shard Files — Format

```markdown
# [Agent] — [Topic]

[entries verbatim from the original MEMORY.md, grouped by this topic]
```

**Rules for shards:**
- Hard cap: 150 lines per shard
- If a shard grows past 150 lines, split by sub-topic
- One truth per entry — update in place, do not append corrections
- Remove entries that describe resolved or superseded state

## When to Use Which Tier

| Situation | Action |
|-----------|--------|
| Starting a task — topic is in index | Read the relevant shard |
| Starting a task — topic not in index | Proceed without memory, add entry after if decision was made |
| Writing new memory | Write to the relevant shard; add row to index if new shard |
| Shard hits 150 lines | Split into two shards; update index rows |
| `/memory-prune` runs | Prunes each shard individually, not just MEMORY.md |

## Agents That Use Sharded Memory

Agents with `memory: project` in frontmatter use this structure once `/memory-shard`
has been run. Before sharding, their MEMORY.md is flat (legacy format).

`memory: user` agents (creative-director etc.) use the user memory system instead
and are not affected by this protocol.

## Migrating a Flat MEMORY.md

Run `/memory-shard [agent-name]` to split a flat MEMORY.md into shards.
The skill reads the file, groups by `##` headers, proposes shard names,
and rewrites MEMORY.md as an index on approval.
