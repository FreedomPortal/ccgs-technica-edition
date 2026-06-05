---
name: memory-shard
description: "Split agent memory into topic shards. Handles flat MEMORY.md, oversized shards (### sub-splitting), and multi-file directories (art-director style). Rewrites MEMORY.md as a lightweight index. Optionally promotes project-wide facts to .claude/docs/."
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

Set `AGENT_DIR=.claude/agent-memory/[AGENT]` and `MEMORY_PATH=$AGENT_DIR/MEMORY.md`.

Detect directory state:
```bash
AGENT_DIR=".claude/agent-memory/$AGENT"

MEMORY_EXISTS=false
[ -f "$AGENT_DIR/MEMORY.md" ] && MEMORY_EXISTS=true

LOOSE_FILES=$(find "$AGENT_DIR" -maxdepth 1 -name "*.md" ! -name "MEMORY.md" -type f 2>/dev/null | sort)
LOOSE_COUNT=$(echo "$LOOSE_FILES" | grep -c '.md' 2>/dev/null || echo 0)

ALREADY_SHARDED=false
$MEMORY_EXISTS && grep -q "Shard loading protocol" "$AGENT_DIR/MEMORY.md" 2>/dev/null \
  && ALREADY_SHARDED=true
```

**Route by detected state:**

| State | Action |
|-------|--------|
| Nothing in `AGENT_DIR` | Stop — no memory to shard |
| `MEMORY.md` only, flat | Normal flow → Phase 2 |
| `MEMORY.md` with "Shard loading protocol" | Already sharded → offer re-shard |
| `MEMORY.md` + loose `.md` files | Multi-file mode → Phase 1b |
| Loose `.md` files only (no `MEMORY.md`) | Multi-file mode → Phase 1b |

**Stop condition:**
```
⛔ No memory files found at [AGENT_DIR].
   Create .claude/agent-memory/[AGENT]/MEMORY.md first.
   Aborting.
```

**Already sharded:**
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
If re-sharding: read MEMORY.md and all files in `shards/` (skip `_legacy-flat.md`) before Phase 2.

### Phase 1b — Multi-File Consolidation

Reached when loose `.md` files exist alongside or instead of a flat MEMORY.md.

List all files with line counts:
```bash
for f in $LOOSE_FILES; do echo "$f: $(wc -l < "$f") lines"; done
[ -f "$AGENT_DIR/MEMORY.md" ] && echo "MEMORY.md: $(wc -l < "$AGENT_DIR/MEMORY.md") lines"
```

Display:
```
[AGENT] has multiple loose memory files — not yet in sharded format:

  [filename].md   — [N] lines
  [filename].md   — [N] lines
  MEMORY.md       — [N] lines  (if present)

These will be treated as pre-separated shards.
Files already under 150 lines → promoted to shards/ as-is.
Files over 150 lines → analyzed for ## / ### sub-splitting in Phase 2.
```

```
AskUserQuestion:
  prompt: "Consolidate into sharded format? MEMORY.md will be rewritten as an index."
  options:
    - "yes — consolidate"
    - "no — abort"
```

If yes: set `SOURCE_FILES` = all loose files + MEMORY.md (if flat). Proceed to Phase 2
treating each file as a single `##`-level group (filename → shard name). Phase 2 will
further sub-split any file over 150 lines using its internal `##` / `###` headers.

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

**Backup originals:**
```bash
# Single flat MEMORY.md
cp "$AGENT_DIR/MEMORY.md" "$AGENT_DIR/shards/_legacy-flat.md"

# Multi-file mode: concatenate all source files into one backup
# (only when SOURCE_FILES was set in Phase 1b)
cat $SOURCE_FILES > "$AGENT_DIR/shards/_legacy-flat.md"
```

In multi-file mode: after writing shards and index, delete the original loose files
from `AGENT_DIR` root (they are now replaced by `shards/` + `MEMORY.md` index):
```bash
for f in $SOURCE_FILES; do
  [ "$f" != "$AGENT_DIR/MEMORY.md" ] && rm "$f"
done
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
