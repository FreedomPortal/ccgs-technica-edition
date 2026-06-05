---
name: memory-shard
description: "Split a flat agent MEMORY.md into topic shards. Rewrites MEMORY.md as a lightweight index. Handles oversized shards via ### sub-splitting. Optionally promotes project-wide facts to .claude/docs/. Run when MEMORY.md exceeds ~150 lines or shards exceed 150 lines."
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

Parse `##` headers as primary topic boundaries. Each `##` header and its content
below (until the next `##` or EOF) is one candidate shard.

**Oversized group handling**: If any `##` group exceeds 150 lines, parse its `###`
sub-headers as split points — each `###` block becomes a separate shard candidate.
If no `###` sub-headers exist in an oversized group, flag it for manual review.

Display:
```
[AGENT]/MEMORY.md — [N] lines  (or: [N] lines across [M] shard files)

Detected topic groups:
  1. [## Header text] — [N] lines
  2. [## Header text] — 280 lines → sub-split by ### into:
       2a. [### Sub-header] — [N] lines
       2b. [### Sub-header] — [N] lines
       2c. (ungrouped content) — [N] lines
  3. [## Header text] — [N] lines
  ...
  [N]. Ungrouped entries (no header) — [N] lines
```

If an oversized group has no `###` sub-headers:
```
  ⚠️  Group [N] ([header]) is [N] lines with no sub-headers — flag for manual split.
      Shard will be written as-is; prune stale entries first to reduce size.
```

Propose shard filename for each group/sub-group: lowercase, hyphen-separated, no spaces.
Example: "Skill Authoring Conventions" → `skills.md`; "### File Layout" within a group → `skills-layout.md`

Display proposed mapping:
```
Proposed shards → .claude/agent-memory/[AGENT]/shards/

  [## Header]              → shards/[filename].md
  [## Header / ### Sub]    → shards/[filename].md
  [Ungrouped]              → shards/general.md
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

---

## Phase 6 — Promote to Docs (Optional)

Scan all written shard content for entries that are project-wide facts rather than
agent-specific context. Skip this phase silently if no candidates found.

**High-signal patterns:**

| Pattern | Likely target |
|---------|--------------|
| Canonical / known file paths | `.claude/docs/technical-preferences.md` or new `canonical-paths.md` |
| Forbidden patterns, banned APIs | `.claude/docs/technical-preferences.md` |
| Allowed libraries / addons | `.claude/docs/technical-preferences.md` |
| Naming conventions, coding standards | `.claude/docs/coding-standards.md` |
| Architecture decisions (ADRs) | `docs/architecture/` |

Display candidates (skip phase if none):
```
Promotion candidates — project-wide facts found in [AGENT] shards:

  shards/[file].md:
    "[entry text]" → suggested: [target doc]
  ...

  [N] candidate(s). Promoting removes them from the shard.
```

```
AskUserQuestion:
  prompt: "Promote entries to .claude/docs/? Removes them from agent memory (project-wide facts don't belong there)."
  options:
    - "yes — select entries to promote"
    - "no — skip"
```

If yes: for each candidate, confirm target file (accept suggestion or enter path), then:
1. Append the entry to the target doc file under an appropriate section header
2. Remove the entry from its shard via Edit
3. Update the shard's line count in the index if count changed materially

Report:
```
Promoted [N] entries:
  "[entry]" → [target doc]
  ...
Shards updated. Shard sizes unchanged for entries not promoted.
```

Verdict: **COMPLETE** (with or without promotions)
