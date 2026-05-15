---
name: taste-gate
description: "Human taste approval checkpoint before batch AI image generation. Reads reference art and the art bible, extracts concrete prompt parameters, generates 1–3 pilot outputs, and loops until the user approves. Locks a prompt template that gates downstream batch generation. Run after /art-bible is approved, before any batch AI image generation begins."
argument-hint: "<asset-type>  e.g. characters | item | environment | ui"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit, Task, AskUserQuestion
model: sonnet
---

## Phase 0: Parse Argument & Prerequisites

**Extract asset type** from the CLI argument (normalize to kebab-case, e.g. `characters`, `item`, `environment`, `ui`).

If no argument provided, use `AskUserQuestion`:
- Prompt: "Which asset type are you running a taste gate for?"
- Options: `[A] characters` / `[B] item` / `[C] environment` / `[D] ui` / `[E] Other — I'll specify`

**Check art bible**: Read `design/art/art-bible.md`.
- If missing: fail with:
  > "No art bible found. Run `/art-bible` first — taste-gate anchors extracted prompt parameters to the art bible's visual rules. Sections 1–5 minimum are required."
- If present but fewer than Sections 1–5 have real content (not `[To be designed]` placeholders): warn:
  > "Art bible sections 1–5 are not fully complete. Taste-gate will extract from whatever is available, but results will be thinner. Consider completing the art bible before proceeding."
  Then use `AskUserQuestion`: `[A] Proceed anyway` / `[B] Stop — complete the art bible first`

**Check for existing locked template**: Glob `design/art/prompt-templates/[asset-type]-template.md`.
- If found and contains `Status: LOCKED`:
  > "A locked prompt template already exists for **[asset-type]** at `design/art/prompt-templates/[asset-type]-template.md`. Batch generation may proceed."
  Use `AskUserQuestion`:
  - Prompt: "This template is already locked. Why are you re-running taste-gate?"
  - Options:
    - `[A] Reference art changed — re-extract and re-approve` → proceed, will overwrite with a new LOCKED record
    - `[B] Style feedback after production — iterate the template` → proceed
    - `[C] I just wanted to check — I'm done` → stop

---

## Phase 1: Reference Intake

**Check for reference files**: Glob `design/art/references/[asset-type]/`.

If the directory is empty or missing:
> "No reference files found at `design/art/references/[asset-type]/`. Before running taste-gate, place your reference images, moodboard exports, or reference descriptions in that folder."
Use `AskUserQuestion`:
- Prompt: "How would you like to provide reference art?"
- Options:
  - `[A] I'll add files now — pause and resume when ready`
  - `[B] I'll describe the references in text — no files needed`
  - `[C] Use the art bible's Section 9 (Reference Direction) as the sole reference`

If [A]: pause. When user signals they're ready, re-Glob to confirm files are present, then continue.

If [B]: use `AskUserQuestion` (free text — let the user describe their reference: visual targets, comparable games or films, mood, distinguishing features). Store the description as the reference input for Phase 2.

If [C]: use art bible Section 9 content as the sole reference input.

If files are present: Read each file if they are text/markdown. For binary image files, note their filenames and ask the user to describe what they contain in one sentence each — the art-director agent will work from these descriptions.

Present a reference summary to the user before proceeding:
> **References loaded — [asset-type]:**
> - [N] files in `design/art/references/[asset-type]/`
> - [list filenames or user descriptions]
> - Art bible sections available: [which sections have content]

Use `AskUserQuestion`: `[A] These references are correct — extract style` / `[B] Add or correct a reference` / `[C] Stop here`

---

## Phase 2: Style Extraction

Spawn `art-director` via Task:

Provide:
- Asset type: `[asset-type]`
- Reference descriptions (from Phase 1 — filenames, user descriptions, or art bible Section 9 content)
- Art bible content: Visual Identity Statement (Section 1), Mood & Atmosphere (Section 2), Shape Language (Section 3), Color System (Section 4), and any asset-type-relevant section (Section 5 for characters, Section 6 for environment, Section 7 for UI)
- Any existing prompt template at `design/art/prompt-templates/[asset-type]-template.md` (context for iteration runs)

Ask the art-director:
> "Extract concrete AI image generation parameters for **[asset-type]** art. Anchor every parameter to the art bible and the provided references. Produce:
>
> 1. **Style keywords** (5–10): specific, combinable terms that define the visual style — not generic words like 'fantasy' or 'colorful'. Each keyword must trace back to either the art bible or a reference.
> 2. **Color constraints** (3–5 rules): specific palette anchors and forbidden color combinations derived from the art bible's Color System. Name the semantic roles (e.g., 'use Threat Blue for hostile elements, never warm tones').
> 3. **Shape language rules** (2–4 rules): geometry and silhouette guidelines from the art bible's Shape Language section. Specific enough for an AI generator to apply.
> 4. **Composition notes** (1–3): framing, focal point, and perspective guidelines appropriate for this asset type at its expected in-game display size.
> 5. **Negative prompts** (5–10): specific things to exclude — styles, colors, or visual motifs that would conflict with the art bible or references. Each negative must have a reason.
> 6. **Full generation prompt**: a ready-to-use text prompt combining all of the above into one block. Should be usable without modification as a first attempt.
> 7. **Art bible anchors**: for each extracted parameter, cite the specific art bible section it comes from."

Collect the art-director's output before Phase 3.

---

## Phase 3: Pilot Prompt Review

**Before any generation**, present the full extracted parameters to the user in conversation:

```
## Extracted Style Parameters — [asset-type]

**Style keywords:** [list]
**Color constraints:** [list]
**Shape language rules:** [list]
**Composition notes:** [list]
**Negative prompts:** [list]

**Full generation prompt:**
[prompt block]

**Art bible anchors:**
[section citations]
```

Use `AskUserQuestion`:
- Prompt: "These are the extracted parameters for **[asset-type]** pilots. Review before any generation runs."
- Options:
  - `[A] Looks right — generate pilots`
  - `[B] Adjust a specific parameter before generating`
  - `[C] The direction is wrong — I'll re-describe the references`

If [B]: ask which parameter and what to change. Update the prompt inline. Re-present the revised block. Loop until the user selects [A].

If [C]: return to Phase 1 with updated reference descriptions.

Do NOT proceed to Phase 4 without explicit user approval of the prompt parameters.

---

## Phase 4: Pilot Generation & Approval Gate

Generate 1–3 pilot outputs using the approved prompt. Use available AI image generation tools, or present the prompt for the user to run in their preferred tool and share the result.

After each pilot round, present results and use `AskUserQuestion`:
- Prompt: "Pilot result(s) for **[asset-type]**. Verdict?"
- Options:
  - `[A] APPROVED — this direction is right, lock the template`
  - `[B] ITERATE — close but needs refinement`
  - `[C] REJECT — wrong direction, start over with new references`

### If APPROVED → proceed to Phase 5.

### If ITERATE:
Use `AskUserQuestion` (free text): "What specifically needs to change? Describe what's off — color, shape, mood, composition, or style keywords."

Spawn `art-director` via Task with:
- The current prompt parameters
- The user's iteration feedback
- The pilot descriptions or results

Ask: "Refine the generation prompt based on this feedback: [user feedback]. Adjust only the parameters that address the feedback — keep everything else stable. Return the same parameter format as before."

Present revised parameters to the user (same format as Phase 3). Use `AskUserQuestion`:
- `[A] Generate new pilots with these parameters` → loop back to pilot generation
- `[B] Adjust parameters further before generating` → inline edit loop

Each iteration cycle increments a counter. After 3 ITERATE cycles without APPROVED, surface:
> "3 iteration rounds completed without approval. Options for breaking the loop:"
Use `AskUserQuestion`:
- `[A] Continue iterating — I can see we're getting closer`
- `[B] REJECT — the reference set isn't working, start over`
- `[C] APPROVED with reservations — lock what we have and note the open issues`

If [C]: proceed to Phase 5 and add an `Open Issues` block to the template.

### If REJECT:
Use `AskUserQuestion`:
- Prompt: "What was wrong with the direction? This helps re-anchor the references."
- Options:
  - `[A] The references themselves were wrong — I'll provide new ones`
  - `[B] The art-director misread the references — I'll clarify`
  - `[C] The art bible direction conflicts with what I want — the art bible needs updating first`

If [A] or [B]: return to Phase 1 with the rejection note as context.
If [C]: stop. Recommend running `/art-bible` to revise the relevant sections before re-running taste-gate.

---

## Phase 5: Template Lock

Write the approved parameters to `design/art/prompt-templates/[asset-type]-template.md` using the format in `.claude/docs/templates/art-prompt-template.md`.

Ask: "May I write the locked prompt template to `design/art/prompt-templates/[asset-type]-template.md`?"

The template is written with `Status: LOCKED` and today's date.

**Art bible amendment**: Ask: "May I append the approved style parameters to the art bible's Section 9 (Reference Direction) as a [asset-type] taste-gate record?"

If yes: append to `design/art/art-bible.md` Section 9:

```markdown
### Taste-Gate Record: [asset-type] — [date]

**Status**: LOCKED
**Iteration rounds**: [N]

**Approved style parameters:**
[style keywords, color constraints, shape rules — as a concise summary]

**Generation prompt (locked):**
[full prompt block]
```

If Section 9 does not exist in the art bible, create it before appending.

---

## Phase 6: Close

Use `AskUserQuestion`:
- Prompt: "Taste-gate complete for **[asset-type]**. Template is locked at `design/art/prompt-templates/[asset-type]-template.md`. What's next?"
- Options:
  - `[A] Run taste-gate for another asset type — /taste-gate [next-type]`
  - `[B] Run /asset-spec — generate full per-asset specs now that the template is locked`
  - `[C] Proceed to batch generation — the locked template is ready`
  - `[D] Stop here`

---

## Collaborative Protocol

Every phase follows: **Reference → Extract → Review → Generate → Verdict → Lock**

- Always show extracted prompt parameters to the user before any generation runs — never generate silently
- Never lock the template without an explicit APPROVED verdict
- Surface art-director output fully — do not summarize away parameters
- Never auto-resolve a REJECT by guessing new references — always ask the user
- Write the template only after explicit write approval
- Amend the art bible only after explicit write approval
