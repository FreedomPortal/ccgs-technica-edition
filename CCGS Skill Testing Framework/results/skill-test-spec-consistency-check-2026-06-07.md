# Skill Spec Test Results: /consistency-check
Date: 2026-06-07
Spec: CCGS Skill Testing Framework/skills/analysis/consistency-check.md
Overall Verdict: FAIL (4 cases failed, 1 passed, 3 protocol failures)

---

## Root Cause

Spec and skill describe different implementations. Investigation needed to
determine which is canonical — user interview in progress.

**Spec models:**
- GDD-to-GDD direct cross-check (no registry required)
- Verdicts: CONSISTENT, CONFLICTS FOUND, DEPENDENCY GAP
- Severity: HIGH / MEDIUM / LOW
- Read-only during analysis; optional report writing with "May I write"

**Skill is:**
- Registry-based (entities.yaml) with grep-first approach
- Verdicts: PASS, CONFLICTS FOUND, COMPLETE, BLOCKED
- Classification: 🔴 CONFLICT / ⚠️ STALE REGISTRY / ℹ️ UNVERIFIABLE
- Auto-writes Phase 6b (docs/consistency-failures.md) and Phase 7 (session-state) without asking

---

## Static Assertions

- [PASS] Has required frontmatter fields
- [PASS] Has ≥2 phase headings
- [FAIL] Verdict keywords: spec expects CONSISTENT/DEPENDENCY GAP; skill uses PASS
- [FAIL] Read-only during analysis: skill auto-writes Phase 6b + 7 without asking
- [PASS] Next-step handoff present
- [FAIL] Report writing documented as optional+gated: Phase 6b is mandatory, unconditional

---

## Case 1: Happy Path — No Conflicts
Verdict: FAIL
- [PARTIAL] GDD reads: grep-first, not full reads
- [PASS] Findings table present
- [FAIL] Verdict CONSISTENT: skill outputs PASS
- [FAIL] No unasked writes: Phase 6b + 7 auto-write
- [PASS] Next-step handoff

## Case 2: Conflicting Formulas
Verdict: FAIL
- [PASS] Verdict CONFLICTS FOUND
- [PASS] Both GDD filenames named in output
- [FAIL] Conflict type label "Formula Mismatch": skill uses 🔴 icon only
- [FAIL] Severity HIGH: no severity rubric in skill
- [PASS] Both formulas shown
- [PASS] No auto-resolve

## Case 3: Dependency Gap
Verdict: FAIL
- [FAIL] Verdict DEPENDENCY GAP: absent from skill
- [FAIL] Dependency gap detection: skill doesn't scan GDD Dependencies sections
- [FAIL] Severity MEDIUM: no severity rubric
- [FAIL] Suggests /design-system: absent

## Case 4: No GDDs Found
Verdict: FAIL
- [PARTIAL] Error on empty GDD dir: only if registry also empty; otherwise outputs PASS
- [FAIL] No verdict produced: skill still outputs PASS
- [PARTIAL] Recommends /design-system: only on empty registry
- [PASS] No crash

## Case 5: No Director Gate
Verdict: PASS
- [PASS] No gates spawned
- [PASS] review-mode.txt not read
- [PASS] No gate entries in output
- [PASS] Review mode has no effect

---

## Protocol Compliance
- [PARTIAL] All GDDs processed before findings: grep-based, not full reads
- [PASS] Findings shown before write ask
- [FAIL] Verdict vocabulary matches spec: CONSISTENT/DEPENDENCY GAP absent from skill
- [PASS] No director gates
- [FAIL] Phase 6b + 7 write without asking
- [PASS] Next-step handoff matches verdict

---

## Status
Pending user interview to resolve which model is canonical.
