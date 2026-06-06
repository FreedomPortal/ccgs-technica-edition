# Skill Test Spec: /market-research

> **Category**: publish
> **Priority**: medium
> **Spec written**: 2026-06-07

## Skill Summary

`/market-research` produces competitive intelligence for an indie game concept:
comp title analysis, pricing benchmarks, audience sizing, platform fit, and
release timing guidance. It reads `design/gdd/game-concept.md`, optionally
loads an existing `production/publishing/market-research.md` (update mode),
asks the user for depth/focus/known-comps parameters, spawns a
`publishing-manager` subagent to run the research via WebSearch, then writes
the output after explicit user approval. The final file is humanized via
`/refine-copy` automatically. Output feeds `/marketing-plan` and
`/press-outreach`.

---

## Static Assertions (Structural)

Verified automatically by `/skill-test static` — no fixture needed.

- [ ] Has required frontmatter fields: `name`, `description`, `argument-hint`, `user-invocable`, `allowed-tools`
- [ ] Has ≥2 phase headings (numbered Phase N or ## sections)
- [ ] Contains verdict keyword: `COMPLETE`
- [ ] Contains `"May I write"` collaborative protocol language
- [ ] Has a next-step handoff at the end (next steps section in Phase 7 summary)

---

## Director Gate Checks

**N/A** — `/market-research` does not trigger director gates. It is a
publishing-pipeline authoring skill driven by a single domain specialist
(publishing-manager). No creative, technical, or production directors are
involved in the research phase.

---

## Test Cases

### Case 1: Happy Path — Fresh concept, no existing research file

**Fixture:**
- `design/gdd/game-concept.md` exists with title, genre, one-line hook, target audience, platforms, scope, and comparable titles from brainstorm
- `production/publishing/market-research.md` does NOT exist
- `production/publishing/publishing-roadmap.md` does NOT exist

**Input:** `/market-research`

**Expected behavior:**
1. Skill reads `design/gdd/game-concept.md`
2. Skill detects no existing `market-research.md` — skips Phase 2 update prompt
3. Skill asks user: depth (Quick/Standard/Deep), focus (Pricing/Audience/Platform/All), known comps
4. Skill spawns `publishing-manager` via Task with game context + parameters
5. Agent returns structured report with comp table, pricing, audience, platform fit, release timing, market gap, solo-dev slice
6. Skill presents summary of findings to user
7. Skill asks: "May I write the market research report to `production/publishing/market-research.md`?"
8. On approval: writes file, then applies `/refine-copy` in-place automatically
9. Outputs Phase 7 summary block ending with `Verdict: COMPLETE`

**Assertions:**
- [ ] Skill reads `design/gdd/game-concept.md` before asking any questions
- [ ] Phase 2 update prompt is NOT shown when no existing file exists
- [ ] Skill asks three parameter questions (depth, focus, known comps) before spawning agent
- [ ] Subagent prompt includes data-freshness warning (⚠️ cutoff notice)
- [ ] Skill asks "May I write" before writing `production/publishing/market-research.md`
- [ ] Written file includes the data-freshness disclaimer block
- [ ] Written file includes all 7 sections: Comparable Titles, Pricing Benchmark, Audience Profile, Platform Fit, Release Timing, Market Gap, Priority Insights
- [ ] Phase 7 summary includes `Verdict: COMPLETE`
- [ ] Phase 7 summary lists `/marketing-plan` and `/press-outreach` as next steps

---

### Case 2: Blocked — No game concept exists

**Fixture:**
- `design/gdd/game-concept.md` does NOT exist
- `design/gdd/` directory is empty or absent

**Input:** `/market-research`

**Expected behavior:**
1. Skill attempts to read `design/gdd/game-concept.md` — file not found
2. Skill outputs stop message recommending `/brainstorm`
3. Skill does NOT proceed to Phase 2 or beyond
4. No files written, no agent spawned

**Assertions:**
- [ ] Skill stops at Phase 1 when `game-concept.md` is missing
- [ ] Output message references `/brainstorm` as the required prerequisite
- [ ] No `publishing-manager` agent is spawned
- [ ] No files are written to `production/publishing/`

---

### Case 3: Update Mode — Existing market-research.md present

**Fixture:**
- `design/gdd/game-concept.md` exists
- `production/publishing/market-research.md` exists with prior research content
- `production/publishing/publishing-roadmap.md` may or may not exist

**Input:** `/market-research`

**Expected behavior:**
1. Skill reads both `game-concept.md` and existing `market-research.md`
2. Skill detects existing file — triggers Phase 2 mode selection
3. Skill asks user: "Update with new comps or data" / "Re-run full analysis (archive old)" / "Just review the existing file"
4. User selects "Update with new comps or data"
5. Skill proceeds with Phase 3 parameters, carrying forward existing comps
6. Agent output notes what's being refreshed vs. retained

**Assertions:**
- [ ] Phase 2 AskUserQuestion fires when `production/publishing/market-research.md` exists
- [ ] Three mode options are presented: Update / Re-run full / Just review
- [ ] Existing comp data is noted as "carrying forward" in the agent prompt (not discarded)
- [ ] Skill still asks "May I write" before overwriting the existing file
- [ ] File is not written without explicit approval even in update mode

---

### Case 4: Edge Case — User provides seed comp titles

**Fixture:**
- `design/gdd/game-concept.md` exists
- No existing `market-research.md`
- User selects "Yes — let me list them now" for known comps in Phase 3

**Input:** `/market-research`

**Expected behavior:**
1. Phase 3 "Known comps" tab: user selects "Yes — let me list them now"
2. Skill follows up with a free-text prompt to capture user's comp list
3. User-provided titles are passed to the `publishing-manager` as seed comps
4. Agent report treats user titles as confirmed inclusions, noting any that look obscure or potentially misremembered
5. Phase 5 notes if any user-provided titles need manual verification

**Assertions:**
- [ ] Skill issues a follow-up free-text prompt when user selects "let me list them now"
- [ ] User-provided comp titles appear in the `publishing-manager` Task prompt as `user-provided comp titles: [LIST]`
- [ ] Agent or skill flags obscure/potentially misremembered comps rather than accepting them silently
- [ ] Final file includes user-provided comps in the comparable titles table

---

### Case 5: Review-Only Mode — User selects "Just review the existing file"

**Fixture:**
- `design/gdd/game-concept.md` exists
- `production/publishing/market-research.md` exists with prior research content

**Input:** `/market-research`

**Expected behavior:**
1. Phase 2 prompt fires — user selects "Just review the existing file"
2. Skill reads and summarizes the existing `market-research.md`
3. Skill stops after the summary — no agent spawned, no new research run
4. No file writes occur

**Assertions:**
- [ ] Skill reads existing `market-research.md` in full when "Just review" is selected
- [ ] Skill outputs a summary of the existing research (key comps, price recommendation, market gap)
- [ ] No `publishing-manager` agent is spawned
- [ ] Skill stops after the summary — does NOT proceed to Phase 3–7
- [ ] No files are written or modified in review-only mode

---

## Protocol Compliance

- [ ] Uses `"May I write"` before writing `production/publishing/market-research.md` (Phase 5)
- [ ] Presents agent findings summary before requesting write approval
- [ ] Always surfaces the data-freshness warning (LLM cutoff caveat) regardless of mode
- [ ] Does not write any file without explicit user confirmation
- [ ] Ends with Phase 7 summary listing `/marketing-plan` and `/press-outreach` as next steps
- [ ] `/refine-copy` pass runs automatically (no second approval needed for that step)

---

## Coverage Notes

- The "Re-run full analysis (archive old)" update sub-mode is not explicitly tested;
  it follows the same flow as the happy path with the addition of archiving the old file.
  Archiving behavior is not specified in the skill — treat as a coverage gap.
- WebSearch availability affects research quality but not skill correctness; assertions
  do not verify the actual comp data returned by the agent.
- The data-freshness warning is a correctness-critical requirement: without it, the
  user may act on stale LLM pricing data. This should be BLOCKING if absent from the
  subagent prompt and the written file.
- Regional pricing and discount calendar sections (within Pricing Benchmark) are not
  individually asserted — they are inside the agent prompt and considered covered by
  the subagent's scope.
