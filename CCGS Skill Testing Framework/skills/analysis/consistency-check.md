# Skill Test Spec: /consistency-check

## Skill Summary

`/consistency-check` verifies that all GDDs in `design/gdd/` agree with the
values declared in `design/registry/entities.yaml` — the single source of truth
for all named game-world facts that appear in more than one document.

The skill is **registry-driven and grep-first**: it loads the registry once, then
targets only the GDD sections that mention registered names. It does not do
full GDD reads during the scan phase — only during Phase 4 conflict investigation.

This skill checks **registered entity value consistency only**. It does NOT:
- Detect dependency gaps (GDD references a system with no GDD) → use `/review-all-gdds`
- Detect design-theory conflicts or dominant-strategy issues → use `/review-all-gdds`

Verdicts: `PASS`, `CONFLICTS FOUND`, `COMPLETE`, `BLOCKED`

Write gates: All file writes (conflict log, session state) require "May I write"
approval, except when `review-mode.txt` is `lean` or `solo` (auto-approved).

---

## Static Assertions (Structural)

Verified automatically by `/skill-test static` — no fixture needed.

- [ ] Has required frontmatter fields: `name`, `description`, `argument-hint`, `user-invocable`, `allowed-tools`
- [ ] Has ≥2 phase headings
- [ ] Contains verdict keywords: PASS, CONFLICTS FOUND, COMPLETE, BLOCKED
- [ ] Uses "May I" ask-before-write language for registry updates, conflict log, and session state
- [ ] Has a next-step handoff at the end
- [ ] Documents cross-reference to `/review-all-gdds` for dependency gaps

---

## Director Gate Checks

No director gates. Consistency checking is a mechanical registry scan — no
creative or technical director review is part of this skill.

---

## Test Cases

### Case 1: Happy Path — Registry with 3 entities, all GDDs agree

**Fixture:**
- `design/registry/entities.yaml` has 3 entries: `SwordDamage`, `GoldCost`, `SpeedMultiplier`
- `design/gdd/combat.md` mentions `SwordDamage = 25` — matches registry
- `design/gdd/economy.md` mentions `GoldCost = 100` — matches registry
- No GDD mentions a different value for any registered entry

**Input:** `/consistency-check`

**Expected behavior:**
1. Phase 1 loads registry: reports "3 entities, 0 items, 0 formulas, 0 constants"
2. Phase 2 globs GDDs, reports in-scope list
3. Phase 3 greps each registered name across GDDs — no conflicts found
4. Phase 5 outputs report: Clean Entries section shows 3 verified, Conflicts section empty
5. Verdict: PASS

**Assertions:**
- [ ] Registry is loaded before any GDD scanning begins
- [ ] Skill does NOT do full GDD reads in Phase 3 (grep-only until Phase 4)
- [ ] Findings report is present with a clean entries count
- [ ] Verdict is PASS when no conflicts exist
- [ ] No files are written without a "May I" ask (or review-mode override)

---

### Case 2: Conflict — Registry entity contradicted in a GDD

**Fixture:**
- Registry: `SwordDamage` source=`combat.md`, value=25
- `design/gdd/combat.md`: `SwordDamage = 25` (matches)
- `design/gdd/tutorial.md`: mentions `SwordDamage = 15` (contradicts registry)

**Input:** `/consistency-check`

**Expected behavior:**
1. Phase 3 grep finds `SwordDamage` in both GDDs
2. Phase 4 targeted read of `tutorial.md` confirms value=15 vs registry value=25
3. Phase 5 report: 🔴 CONFLICT entry for SwordDamage — registry source vs tutorial.md
4. Verdict: CONFLICTS FOUND

**Assertions:**
- [ ] Verdict is CONFLICTS FOUND
- [ ] 🔴 CONFLICT entry names both the registry source GDD and the conflicting GDD
- [ ] Both values are shown (registry: 25, conflict: 15)
- [ ] Skill does NOT auto-resolve — no registry or GDD edits without asking
- [ ] Phase 6b ask: "May I append [N] conflict(s) to docs/consistency-failures.md?" before writing

---

### Case 3: Stale Registry — Source GDD updated, registry behind

**Fixture:**
- Registry: `GoldCost` source=`economy.md`, value=100, written 2026-01-01
- `design/gdd/economy.md` (the source GDD) now says `GoldCost = 150`
- No other GDD mentions GoldCost

**Input:** `/consistency-check`

**Expected behavior:**
1. Phase 3 grep finds `GoldCost` in economy.md
2. Extracted value (150) contradicts registry (100)
3. Since the conflict is in the source GDD itself, classified as ⚠️ STALE REGISTRY
4. Phase 5 report: Stale Registry section shows GoldCost — registry says 100, source GDD says 150
5. Phase 6 asks: "May I update design/registry/entities.yaml to fix the 1 stale entry?"
6. After write: Verdict: COMPLETE

**Assertions:**
- [ ] Stale registry entry classified as ⚠️ STALE REGISTRY (not 🔴 CONFLICT)
- [ ] Report shows both registry value and current source GDD value
- [ ] Phase 6 asks before updating the registry (not auto-updates)
- [ ] After approved write, verdict is COMPLETE
- [ ] Registry entry gets `revised:` date and `# was:` comment

---

### Case 4: Empty Registry — Hard stop

**Fixture:**
- `design/registry/entities.yaml` does not exist OR exists but has no entries

**Input:** `/consistency-check`

**Expected behavior:**
1. Phase 1 attempts to load registry
2. Registry is empty or absent
3. Skill outputs: "Entity registry is empty. Run `/design-system` to write GDDs — the registry
   is populated automatically after each GDD is completed. Nothing to check yet."
4. Skill stops — no GDD scanning, no report, no verdict

**Assertions:**
- [ ] Skill stops at Phase 1 with a clear message
- [ ] No GDD scanning occurs
- [ ] No verdict is issued (PASS / CONFLICTS FOUND / etc.)
- [ ] Message recommends `/design-system` as the correct next step
- [ ] No files are written

---

### Case 5: No Director Gate Spawned

**Fixture:**
- Registry has ≥1 entry
- `production/session-state/review-mode.txt` exists with value `full`

**Input:** `/consistency-check`

**Expected behavior:**
1. Skill loads registry, scans GDDs, produces report normally
2. Skill does NOT read `review-mode.txt` for gate-spawning purposes
3. No director gate agents are spawned at any point
4. Review mode is only read in Phase 6b and Phase 7 to decide whether to skip the "May I write" ask

**Assertions:**
- [ ] No director gate agents spawned (no CD-, TD-, PR-, AD- prefixed gates)
- [ ] Output contains no "Gate:" entries
- [ ] `review-mode.txt` is only accessed for write-gate override, not gate spawning
- [ ] Verdict and report are produced regardless of review mode value

---

## Protocol Compliance

- [ ] Registry loaded in Phase 1 before any GDD interaction
- [ ] Phase 3 uses grep (not full reads); Phase 4 targeted reads only for confirmed conflicts
- [ ] Findings report shown in full before any write ask
- [ ] Verdict is one of: PASS, CONFLICTS FOUND, COMPLETE, BLOCKED
- [ ] No director gates — no gate-mode logic
- [ ] Phase 6b conflict log write: gated by "May I write" ask (auto-approved if lean/solo)
- [ ] Phase 7 session state write: gated by "May I" ask (auto-approved if lean/solo)
- [ ] Registry updates (Phase 6) gated by "May I update" ask
- [ ] Ends with AskUserQuestion closing widget (not plain text)
- [ ] Recovery section cross-references `/review-all-gdds` for dependency gaps

---

## Coverage Notes

- Dependency gap detection (GDD references nonexistent system) is out of scope for
  this skill — handled by `/review-all-gdds`.
- Design-theory conflicts (dominant strategies, pillar drift) are out of scope —
  handled by `/review-all-gdds`.
- This skill's correctness depends on the registry being up to date. If `/design-system`
  was not used to author GDDs, the registry may be incomplete and results unreliable.
