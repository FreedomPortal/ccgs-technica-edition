# Skill Test Suite Report
Date: 2026-06-11
Run scope: 9 tested (uncatalogued), 132 skipped (CURRENT), 0 UNTESTED, 0 STALE

## Summary

| Result  | Count |
|---------|-------|
| PASS    | 7     |
| WARN    | 2     |
| FAIL    | 0     |
| CURRENT (not retested) | 132 |

## Skills Tested

All 9 are uncatalogued (on disk but absent from catalog.yaml).
Category and Spec checks SKIPPED for all — no catalog entry to look up.

<!-- SKILL: ab-test | verdict: FIXED | priority: uncatalogued -->
### /ab-test
Combined: WARN
Static: WARNINGS | Category: SKIPPED | Spec: SKIPPED
Warnings:
  - Check 5: LOG mode has no next-step handoff; skill ends at Collaborative Protocol with no follow-up section
Observation:
  - AskUserQuestion used in body (Design Phase 1, Review Phase 2) but absent from allowed-tools frontmatter — runtime error when those branches execute
Suggested catalog entry: category: analytics, priority: high
<!-- /SKILL -->

<!-- SKILL: economy-simulation | verdict: PASS | priority: uncatalogued -->
### /economy-simulation
Combined: PASS
Static: COMPLIANT | Category: SKIPPED | Spec: SKIPPED
Observation:
  - AskUserQuestion used in Phase 2, 3, 6 but absent from allowed-tools frontmatter
Suggested catalog entry: category: analytics, priority: high
<!-- /SKILL -->

<!-- SKILL: framework-release | verdict: PASS | priority: uncatalogued -->
### /framework-release
Combined: PASS
Static: COMPLIANT | Category: SKIPPED | Spec: SKIPPED
Suggested catalog entry: category: utility, priority: low
<!-- /SKILL -->

<!-- SKILL: player-segmentation | verdict: PASS | priority: uncatalogued -->
### /player-segmentation
Combined: PASS
Static: COMPLIANT | Category: SKIPPED | Spec: SKIPPED
Observation:
  - AskUserQuestion used in Phase 2, 3, 4, 6 but absent from allowed-tools frontmatter
Suggested catalog entry: category: analytics, priority: medium
<!-- /SKILL -->

<!-- SKILL: refresh-docs | verdict: PASS | priority: uncatalogued -->
### /refresh-docs
Combined: PASS
Static: COMPLIANT | Category: SKIPPED | Spec: SKIPPED
Suggested catalog entry: category: utility, priority: medium
<!-- /SKILL -->

<!-- SKILL: retention-analysis | verdict: FIXED | priority: uncatalogued -->
### /retention-analysis
Combined: WARN
Static: WARNINGS | Category: SKIPPED | Spec: SKIPPED
Warnings:
  - Check 5: Framework Mode (second operating mode) has no next-step handoff; skill ends at Collaborative Protocol without a global next-steps section
Observation:
  - AskUserQuestion used in Phase 1, 2 but absent from allowed-tools frontmatter
Suggested catalog entry: category: analytics, priority: high
<!-- /SKILL -->

<!-- SKILL: sprint-close | verdict: PASS | priority: uncatalogued -->
### /sprint-close
Combined: PASS
Static: COMPLIANT | Category: SKIPPED | Spec: SKIPPED
Suggested catalog entry: category: sprint, priority: critical
<!-- /SKILL -->

<!-- SKILL: telemetry-design | verdict: PASS | priority: uncatalogued -->
### /telemetry-design
Combined: PASS
Static: COMPLIANT | Category: SKIPPED | Spec: SKIPPED
Observation:
  - AskUserQuestion used in Phase 2, 5 but absent from allowed-tools frontmatter
Suggested catalog entry: category: analytics, priority: high
<!-- /SKILL -->

<!-- SKILL: wishlist | verdict: PASS | priority: uncatalogued -->
### /wishlist
Combined: PASS
Static: COMPLIANT | Category: SKIPPED | Spec: SKIPPED
Note: wishlist correctly includes AskUserQuestion in allowed-tools (reference model for other analytics skills)
Suggested catalog entry: category: pipeline, priority: medium
<!-- /SKILL -->

---

## Warnings Index

Priority-ordered list of WARN skills — input queue for `/skill-improve from-report`:

1. [uncatalogued] sprint-close — add to catalog (priority: critical)
2. [uncatalogued] ab-test — 1 static warning (Check 5) + AskUserQuestion missing from allowed-tools
3. [uncatalogued] retention-analysis — 1 static warning (Check 5) + AskUserQuestion missing from allowed-tools

## Observation: AskUserQuestion Missing from Analytics Skills

Five uncatalogued analytics skills call `AskUserQuestion` in their body but omit it from
`allowed-tools`. This is not caught by C1 (which only checks the field exists) but will
cause a runtime permission error when those branches execute.

Affected skills:
  - ab-test
  - economy-simulation
  - player-segmentation
  - retention-analysis
  - telemetry-design

Fix: add `AskUserQuestion` to the `allowed-tools:` frontmatter line in each.
(wishlist already does this correctly — use it as the reference.)

## Agent Specs (Advisory)

| Agent | Category | Last Spec | Status |
|-------|----------|-----------|--------|
| (all 52 agents) | various | never | STALE |

All 52 agent specs have never been tested. Advisory — does not block skill work.

## Uncatalogued Skills — Catalog Entries Needed

All 9 skills tested in this run need catalog entries. Suggested entries:

| Skill | Category | Priority | Spec path needed |
|-------|----------|----------|-----------------|
| ab-test | analytics | high | CCGS Skill Testing Framework/skills/analytics/ab-test.md |
| economy-simulation | analytics | high | CCGS Skill Testing Framework/skills/analytics/economy-simulation.md |
| framework-release | utility | low | CCGS Skill Testing Framework/skills/utility/framework-release.md |
| player-segmentation | analytics | medium | CCGS Skill Testing Framework/skills/analytics/player-segmentation.md |
| refresh-docs | utility | medium | CCGS Skill Testing Framework/skills/utility/refresh-docs.md |
| retention-analysis | analytics | high | CCGS Skill Testing Framework/skills/analytics/retention-analysis.md |
| sprint-close | sprint | critical | CCGS Skill Testing Framework/skills/sprint/sprint-close.md |
| telemetry-design | analytics | high | CCGS Skill Testing Framework/skills/analytics/telemetry-design.md |
| wishlist | pipeline | medium | CCGS Skill Testing Framework/skills/pipeline/wishlist.md |
