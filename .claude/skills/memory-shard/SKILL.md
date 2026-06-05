---
name: memory-shard
description: "Split a flat agent MEMORY.md into topic shards. Rewrites MEMORY.md as a lightweight index with inline loading instructions. Run when an agent's MEMORY.md exceeds ~150 lines."
argument-hint: "[agent-name]"
user-invocable: true
allowed-tools: Read, Write, Edit, Glob, Bash, AskUserQuestion
model: sonnet
---

> **Explicit invocation only.** Run only when user calls `/memory-shard`.
> See `.claude/docs/agent-memory-protocol.md` for the target format.

---

## Phase 1 — Resolve Target Agent

If argument provided, use it as `AGENT`.

Else ask:

```
AskUserQuestion:
  prompt: "Which agent's MEMORY.md should be sharded? (e.g. lead-programmer, game-designer)"
  (free text)
```

Set `MEMORY_PATH=.claude/agent-memory/[AGENT]/MEMORY.md`.

Check file exists:
```bash
[ -f "$MEMORY_PATH" ] || echo "NOT FOUND"
```

If not found: stop.
```
⛔ No MEMORY.md found at [MEMORY_PATH].
   Agent memory directory must exist before sharding.
   Aborting.
```

Check if already sharded (index format present):
```bash
grep -q "Shard loading protocol" "$MEMORY_PATH" && echo "ALREADY_SHARDED"
```

If already sharded:
```
ℹ️  [AGENT]/MEMORY.md is already in sharded index format.
   To add a new shard: write directly to shards/[topic].md and add a row to the index.
   To re-shard (restructure existing shards): confirm below.
```

```
AskUserQuestion:
  prompt: "MEMORY.md is already sharded. Re-shard from scratch (reads all shard content and restructures)?"
  options:
    - "yes — re-shard"
    - "no — abort"
```

If re-sharding: read both MEMORY.md and all existing shard files before Phase 2.

---

## Phase 2 — Read and Analyze

Read full MEMORY.md content.

Count lines:
```bash
wc -l < "$MEMORY_PATH" | tr -d ' '
```

Parse `##` headers as natural topic boundaries. Each `##` header and its content
below (until the next `##` or EOF) is one candidate shard.

Display:
```
[AGENT]/MEMORY.md — [N] lines

Detected topic groups:
  1. [## Header text] — [N] lines
  2. [## Header text] — [N] lines
  ...
  [N]. Ungrouped entries (no header) — [N] lines
```

If any group exceeds 150 lines, flag it:
```
  ⚠️  Group [N] ([header]) is [N] lines — will need a sub-split after sharding.
```

Propose shard filename for each group: lowercase, hyphen-separated, no spaces.
Example: "Skill Authoring Conventions" → `skills.md`; "Known Canonical Paths" → `paths.md`

Display proposed mapping:
```
Proposed shards → .claude/agent-memory/[AGENT]/shards/

  [## Header]         → shards/[filename].md
  [## Header]         → shards/[filename].md
  [Ungrouped]         → shards/general.md
```

---

## Phase 3 — User Approval

```
AskUserQuestion:
  prompt: "Proposed shard mapping above. Approve, or rename any shards?
           Enter renames as 'old → new' (e.g. 'general.md → patterns.md'), comma-separated.
           Press Enter to accept as-is:"
  (free text)
```

Apply any renames to the mapping.

Show final plan:
```
Final shard plan:
  shards/[file].md — [N] lines — "[## header summary]"
  ...

  MEMORY.md → rewritten as index ([~20] lines)
  Original MEMORY.md → backed up to shards/_legacy-flat.md
```

```
AskUserQuestion:
  prompt: "Proceed with sharding?"
  options:
    - "yes — write shards now"
    - "no — abort"
```

---

## Phase 4 — Write Shards

```bash
mkdir -p ".claude/agent-memory/$AGENT/shards"
```

**Backup original:**
```bash
cp "$MEMORY_PATH" ".claude/agent-memory/$AGENT/shards/_legacy-flat.md"
```

**Write each shard file** at `.claude/agent-memory/[AGENT]/shards/[filename].md`:

```markdown
# [Agent display name] — [Topic]

[verbatim content from the corresponding ## section of MEMORY.md,
 minus the ## header line itself — that becomes the shard file's # title]
```

**Rewrite MEMORY.md as index:**

```markdown
# [Agent display name] — Memory Index

> **Shard loading protocol**: Read this index on startup. For any topic relevant
> to your current task, load the corresponding shard via Read tool before proceeding.
> Load only what applies — do not read all shards.

## Shards

| Topic | File | Summary |
|-------|------|---------|
| [topic] | shards/[file].md | [one-line summary — specific enough to judge relevance] |
...

---
*Sharded by /memory-shard on [date]. Legacy flat file: shards/_legacy-flat.md*
```

---

## Phase 5 — Verify and Report

```bash
for f in ".claude/agent-memory/$AGENT/shards/"*.md; do
  echo "$f: $(wc -l < "$f") lines"
done
echo "MEMORY.md: $(wc -l < "$MEMORY_PATH") lines"
```

Display:
```
Sharding complete — [AGENT]

  MEMORY.md (index):    [N] lines  ✓
  shards/[file].md:     [N] lines  [⚠️ >150 — consider splitting] or [✓]
  ...
  shards/_legacy-flat.md: [N] lines (backup, safe to delete after review)

Token cost before: ~[N*4] tokens per agent invocation
Token cost after:  ~[index_lines*4] tokens base + shard on demand
```

If any shard exceeds 150 lines:
```
⚠️  [filename].md is [N] lines. Consider splitting by sub-topic.
    Run /memory-shard [agent] again after review to restructure.
```

Verdict: **SHARDING COMPLETE**

Recommended: run `/memory-prune [agent]` to clean stale entries within each shard.
