# Skill Spec: /demo-polish

> **Category**: utility
> **Priority**: low
> **Spec written**: 2026-05-26

## Skill Summary

`/demo-polish` runs a demo-specific polish pass scoped to conversion-critical areas: the first 2 minutes, onboarding clarity, completion rate, and end-state wishlist/buy CTA. It reads the demo scope doc and playtest reports, uses `game-designer` to generate a prioritized checklist, then delegates to `team-polish` scoped to demo metrics only. In full review mode, `creative-director` reviews the result for pillar alignment. Outputs `production/qa/demo-polish-[date].md`. Not a general content polish pass.

---

## Static Assertions

- [ ] Frontmatter has all required fields (`name`, `description`, `argument-hint`, `user-invocable`, `allowed-tools`)
- [ ] 2+ phase headings found (Phases 0–7)
- [ ] At least one verdict keyword present (`COMPLETE`, `APPROVED`, `BLOCKED`)
- [ ] If `allowed-tools` includes Write/Edit: `"May I write"` language present (Phase 6 asks before writing polish record)
- [ ] Next-step handoff section present at end (Phase 7 offers `/demo-build`)

---

## Director Gate Checks

- **Full mode**: CD-DEMO-POLISH (`creative-director`) spawned in Phase 5 to review pillar alignment
- **Lean mode**: CD-DEMO-POLISH skipped — noted in Phase 5
- **Solo mode**: CD-DEMO-POLISH skipped — noted in Phase 5

---

## Test Cases

### Case 1: Happy Path — Full polish pass with playtest data

**Fixture**:
- `design/demo/demo-scope.md` exists with complete playthrough flow and end-state CTA
- `design/gdd/game-concept.md` exists with pillars
- At least one `production/qa/playtests/demo-playtest-*.md` exists
- `production/qa/playtests/demo-feedback-synthesis.md` exists with P1/P2/polish categorization
- Review mode: lean

**Expected behavior**:
1. Phase 1 reads scope, concept, conversion summary, and playtest reports
2. Phase 2 extracts polish targets and asks user to confirm focus areas
3. Phase 3 spawns `game-designer` with scope + targets to produce prioritized checklist
4. Phase 4 spawns `team-polish` scoped to demo conversion metrics
5. Phase 5 skips CD gate (lean mode)
6. Phase 6 asks "May I write demo polish record to `production/qa/demo-polish-[date].md`?"
7. Phase 7 outputs COMPLETE summary

**Assertions**:
- [ ] Polish checklist is scoped to First impression / Onboarding / Gameplay feel / End state CTA only
- [ ] Phase 4 `team-polish` prompt explicitly lists P1/P2/P3 rules and scope restriction
- [ ] Phase 6 asks before writing (does not auto-write)
- [ ] Phase 7 lists P1/P2/P3 completion counts
- [ ] `/demo-build` offered as next step

**Case Verdict**: PASS

---

### Case 2: Failure — Missing demo scope doc

**Fixture**:
- `design/demo/demo-scope.md` does not exist

**Expected behavior**:
1. Phase 1 attempts to read demo-scope.md
2. Reports: "`design/demo/demo-scope.md` not found. Run `/demo-scope` first."
3. Stops — does not proceed to Phase 2

**Assertions**:
- [ ] Skill stops at Phase 1 with explicit message directing to `/demo-scope`
- [ ] No polish checklist generated
- [ ] No files written

**Case Verdict**: PASS

---

### Case 3: Mode Variant — No playtest data, user proceeds anyway

**Fixture**:
- `design/demo/demo-scope.md` exists
- No `demo-playtest-*.md` files found
- User selects "Yes — I'll identify polish targets manually"

**Expected behavior**:
1. Phase 1 finds no playtest reports
2. Warns: "No demo playtest reports found..." and asks whether to proceed
3. User approves proceeding
4. Phase 2 uses manual input (no playtest extraction)
5. Phase 3 generates checklist without playtest context

**Assertions**:
- [ ] Warning surfaces when no playtest data found
- [ ] `AskUserQuestion` used to ask whether to proceed
- [ ] Skill continues when user approves
- [ ] No crash or error when playtest data is absent

**Case Verdict**: PASS

---

### Case 4: Edge Case — team-polish returns BLOCKED items

**Fixture**:
- All prerequisites present
- `team-polish` returns one P1 item as BLOCKED (e.g., missing end-screen asset)

**Expected behavior**:
1. Phase 4 receives team-polish result with BLOCKED items
2. Skill surfaces BLOCKED items to user
3. Asks user how to proceed: defer or resolve first
4. Phase 7 reports blocked items in summary

**Assertions**:
- [ ] BLOCKED items surfaced explicitly (not silently dropped)
- [ ] Phase 7 summary lists blocked items with BLOCKED status
- [ ] Skill does NOT auto-defer or auto-complete blocked items

**Case Verdict**: PASS

---

### Case 5: Director Gate — Full mode spawns creative-director; solo skips

**Fixture (full mode)**:
- All prerequisites present, polish pass complete
- Review mode: full

**Expected behavior**:
1. Phase 5 spawns `creative-director` with pillars + scope + completed polish items
2. CD verdict: APPROVED
3. Polish record written with CD verdict included

**Assertions (full mode)**:
- [ ] `creative-director` spawned via Task in Phase 5
- [ ] CD verdict (APPROVED / MINOR CONCERNS / REJECTED) appears in output
- [ ] Polish record includes CD verdict when full mode

**Fixture (solo mode)**:
- Same, review mode: solo

**Assertions (solo mode)**:
- [ ] Phase 5 notes "CD-DEMO-POLISH skipped — Solo mode"
- [ ] Polish record proceeds without CD verdict

**Case Verdict**: PASS

---

## Protocol Compliance

- [ ] Uses `"May I write"` before writing `production/qa/demo-polish-[date].md` (Phase 6)
- [ ] Presents polish checklist to user before delegation to team-polish
- [ ] Ends with `/demo-build` as next step (Phase 7)
- [ ] Does not auto-create files without user approval

---

## Coverage Notes

- `team-polish` behavioral outcomes are runtime-only — spec tests skill's delegation prompt, not team-polish's internal logic
- Creative director verdict assessment (pillar alignment) requires a live run to validate quality
- CTA link functionality check is flagged in the skill but is a runtime-only verification
