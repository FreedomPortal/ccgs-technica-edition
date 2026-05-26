# Skill Spec: /taste-gate

> **Category**: utility
> **Priority**: low
> **Spec written**: 2026-05-26

## Skill Summary

`/taste-gate` is a human taste approval checkpoint that runs before any batch AI image generation. It takes an asset type argument (e.g., `characters`, `item`, `environment`, `ui`) and progresses through six phases: prerequisites check, reference intake, style extraction via the `art-director` subagent, pilot prompt review, pilot generation and approval gate, and template lock. It reads `design/art/art-bible.md` and reference files from `design/art/references/[asset-type]/`, then uses `AskUserQuestion` at every decision point. No generation runs and no files are written without explicit user approval. The skill loops through ITERATE cycles until the user approves, rejects, or approves with reservations. On APPROVED, it writes a locked prompt template to `design/art/prompt-templates/[asset-type]-template.md` and optionally amends the art bible's Section 9. The skill runs on the Sonnet model and spawns the `art-director` agent via Task.

---

## Static Assertions

- [ ] Frontmatter has all required fields (`name`, `description`, `argument-hint`, `user-invocable`, `allowed-tools`)
- [ ] 2+ phase headings found
- [ ] At least one verdict keyword present (`APPROVED`, `REJECT`, `LOCKED`)
- [ ] `allowed-tools` includes Write, Edit, Task, and AskUserQuestion
- [ ] `"May I write"` / `"May I"` language present (Phase 5: template write and art bible amendment)
- [ ] Next-step handoff section present at end (Phase 6: close with follow-up options)

---

## Director Gate Checks

- **N/A**: `/taste-gate` does not invoke director-level gate agents. Its approval loop is user-facing (AskUserQuestion), not a director gate. The `art-director` is spawned as a subagent for extraction/refinement, not as a gate authority.

---

## Test Cases

### Case 1: Happy Path — Characters approved on first pilot
**Fixture**:
- `design/art/art-bible.md` exists with Sections 1–5 complete
- `design/art/references/characters/` contains 2 reference image files (user provides descriptions)
- No existing locked template for `characters`
- Argument: `characters`

**Expected behavior**:
1. Phase 0: asset type parsed as `characters`; art bible found and complete; no locked template
2. Phase 1: 2 reference files found; user provides one-sentence descriptions; reference summary presented; user approves references
3. Phase 2: `art-director` spawned via Task; style keywords, color constraints, shape rules, composition notes, negative prompts, and full prompt extracted
4. Phase 3: full parameters presented to user; user selects "Looks right — generate pilots"
5. Phase 4: pilot generation runs; user selects "APPROVED — this direction is right, lock the template"
6. Phase 5: "May I write the locked prompt template to `design/art/prompt-templates/characters-template.md`?" — user approves; template written with `Status: LOCKED`; art bible amendment offered and approved
7. Phase 6: close with follow-up options presented
8. Iteration count: 0

**Assertions**:
- [ ] Asset type is `characters` throughout
- [ ] Parameters shown to user before any generation runs
- [ ] "May I write" used before template is written
- [ ] Art bible amendment requires separate explicit approval
- [ ] Template written with `Status: LOCKED`
- [ ] Phase 6 follow-up options presented

**Case Verdict**: PASS

---

### Case 2: Failure — Art bible missing
**Fixture**:
- `design/art/art-bible.md` does not exist
- Argument: `environment`

**Expected behavior**:
1. Phase 0: asset type parsed; art bible check fails — file absent
2. Skill fails with: "No art bible found. Run `/art-bible` first — taste-gate anchors extracted prompt parameters to the art bible's visual rules. Sections 1–5 minimum are required."
3. Skill stops; no reference intake, no generation

**Assertions**:
- [ ] Failure message references `/art-bible`
- [ ] Skill stops at Phase 0 (does not proceed to Phase 1)
- [ ] No files written
- [ ] No generation attempted

**Case Verdict**: PASS

---

### Case 3: Mode Variant — Locked template already exists; user re-runs to iterate
**Fixture**:
- `design/art/art-bible.md` present and complete
- `design/art/prompt-templates/ui-template.md` exists with `Status: LOCKED`
- Argument: `ui`

**Expected behavior**:
1. Phase 0: locked template detected; `AskUserQuestion` asks why user is re-running
2. User selects "[B] Style feedback after production — iterate the template"
3. Skill proceeds through all phases; on APPROVED, overwrites existing template with new LOCKED record
4. Template file updated (not duplicated)

**Assertions**:
- [ ] Locked-template detection triggers `AskUserQuestion` before proceeding
- [ ] Option [C] "I just wanted to check — I'm done" exits without modification
- [ ] Overwrite path still requires "May I write" approval
- [ ] New template record replaces old LOCKED status

**Case Verdict**: PASS

---

### Case 4: Edge Case — Three ITERATE cycles without APPROVED
**Fixture**:
- `design/art/art-bible.md` present
- `design/art/references/item/` contains reference files
- Argument: `item`
- User selects ITERATE for 3 consecutive pilot rounds

**Expected behavior**:
1. Phases 0–3 complete normally
2. Pilot round 1: user selects ITERATE; feedback collected; `art-director` refines; revised params shown; new pilots generated
3. Pilot round 2: user selects ITERATE again; same flow
4. Pilot round 3: user selects ITERATE again → iteration counter = 3
5. Skill surfaces: "3 iteration rounds completed without approval." with options: continue / REJECT / APPROVED with reservations
6. User selects "APPROVED with reservations — lock what we have and note the open issues"
7. Phase 5 proceeds; template written with `Open Issues` block appended

**Assertions**:
- [ ] Loop-break surface appears after exactly 3 ITERATE cycles
- [ ] "APPROVED with reservations" path still triggers write approval gate
- [ ] `Open Issues` block is present in the written template
- [ ] Skill does not loop infinitely

**Case Verdict**: PASS

---

### Case 5: Protocol — Write approval gates enforced for both template and art bible
**Fixture**:
- Full successful run through Phase 4 with APPROVED verdict
- Phase 5 reached

**Expected behavior**:
1. Template write: "May I write the locked prompt template to `design/art/prompt-templates/[asset-type]-template.md`?" asked before any write
2. Art bible amendment: "May I append the approved style parameters to the art bible's Section 9?" asked separately before any edit
3. Neither write occurs without explicit approval
4. If user declines template write: template is not created; skill acknowledges and stops
5. If user declines art bible amendment: art bible is unchanged; skill proceeds to Phase 6

**Assertions**:
- [ ] Uses "May I write" before template write
- [ ] Art bible amendment requires a second, separate approval
- [ ] Presents extracted parameters before any generation runs
- [ ] No auto-write of template or art bible

**Case Verdict**: PASS

---

## Protocol Compliance

- [ ] Uses `"May I write"` before template write and `"May I append"` before art bible amendment
- [ ] Presents extracted prompt parameters to user before any pilot generation runs
- [ ] Ends with a recommended next step or follow-up action (Phase 6 close options)
- [ ] Does not auto-create files without user approval

---

## Coverage Notes

- The "[B] I'll describe the references in text" path in Phase 1 (no reference files) is not given a dedicated case; it follows the same extraction flow with user text as the sole reference input.
- The "[C] Use art bible Section 9 as sole reference" path in Phase 1 is runtime-only and not statically testable.
- The REJECT path returning to Phase 1 is described in the SKILL.md but not covered by a dedicated case; it is an extension of the flow tested in Cases 2 and 4.
- Section 9 creation (if not present in the art bible) is mentioned but the exact creation logic is not fully specified; this is a runtime behavior gap.
- Pilot generation itself depends on available AI image generation tools, which are environment-specific and cannot be asserted statically.
