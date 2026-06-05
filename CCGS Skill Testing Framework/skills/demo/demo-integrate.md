# Skill Spec: /demo-integrate

> **Category**: utility
> **Priority**: low
> **Spec written**: 2026-06-05

## Skill Summary

After a demo campaign reaches Released/Publishing/Live sub-stage, classifies all changes made during the demo build into three buckets: keep-demo-only, backport-to-main, or needs-story. In Early Access mode, additionally audits EA roadmap commitments and flags any missing as Required 1.0 Stories. Produces an integration report and optional story files, both gated behind user approval.

---

## Static Assertions

- [x] Frontmatter has all required fields (`name`, `description`, `argument-hint`, `user-invocable`, `allowed-tools`)
- [x] 2+ phase headings found (Phases 1–8)
- [x] At least one verdict keyword present (`COMPLETE`)
- [x] `allowed-tools` includes Write — `"May I write"` language present (Phase 7)
- [x] Next-step handoff section present (Phase 8: Summary and Next Steps)

---

## Director Gate Checks

**N/A** — demo-integrate is a classification and reporting skill. It does not trigger director agent panels. EA commitment warnings use ⚠️ in-line, not gate prompts.

---

## Test Cases

### Case 1: Happy Path — Changes classified, report written

**Fixture**:
- `production/demo/alpha/state.txt` contains `Released`
- User provides a changelog file path (`production/demo/alpha/changelog.md`) listing 5 changes
- No Early Access mode

**Expected behavior**:
1. Skill reads state.txt, confirms `Released` sub-stage — proceeds
2. Reads campaign artifacts (demo-plan, demo-scope, playtest/eval docs)
3. Asks how changes were tracked → user selects `[B] Changelog or notes file`
4. Reads changelog, lists 5 changes
5. Classifies each into keep-demo-only / backport-to-main / needs-story — presents to user for confirmation
6. User confirms classifications
7. Produces integration report draft and presents it
8. Asks "May I write this integration report to `production/demo/alpha/integration-report.md`?"
9. Asks "May I create sprint story files for the N needs-story items?"
10. On approval: writes report and story files

**Assertions**:
- [ ] Skill checks state.txt is Released/Publishing/Live before proceeding
- [ ] Classification presented to user before generating output (Phase 4 requirement)
- [ ] "May I write" asked separately for report and story files
- [ ] Story files written to `production/epics/[epic-slug]/`
- [ ] Phase 8 summary shows backport count, new stories count, report path

**Case Verdict**: PASS

---

### Case 2: Failure — Campaign not yet Released

**Fixture**:
- `production/demo/alpha/state.txt` contains `Polishing`

**Expected behavior**:
1. Skill reads state.txt
2. Detects sub-stage is `Polishing`, not Released/Publishing/Live
3. Reports: "Demo campaign 'alpha' is not yet Released. Run `/demo-gate alpha released` before integrating."
4. Stops — no further phases run

**Assertions**:
- [ ] Skill stops at Phase 1 when state is not Released/Publishing/Live
- [ ] Error message names the specific corrective action (`/demo-gate alpha released`)
- [ ] No classification, no report, no story files created

**Case Verdict**: PASS

---

### Case 3: Early Access Mode — EA roadmap commitments audited

**Fixture**:
- `production/demo/ea-demo/state.txt` contains `Publishing`
- `production/demo/ea-demo/demo-plan.md` contains `Early Access: true`
- `production/demo/ea-demo/ea-roadmap.md` lists 3 player-facing feature commitments
- Only 1 of the 3 commitments exists as an epic story in `production/epics/`

**Expected behavior**:
1. Skill detects EA mode
2. Runs Phase 5: reads ea-roadmap.md, globs epics for existing stories
3. Finds 2 commitments with no corresponding story
4. Output table marks 2 items as "Create required story" with ⚠️ warning
5. Integration report includes Required 1.0 Stories section
6. Phase 8 summary includes "Required 1.0 stories: 2"

**Assertions**:
- [ ] EA mode detected from demo-plan.md `Early Access: true`
- [ ] Phase 5 runs only in EA mode — non-EA run skips it
- [ ] Missing EA commitments flagged with ⚠️ and "player trust" warning text
- [ ] Report includes `## Required 1.0 Stories` section when EA mode active
- [ ] Story creation approval prompt covers EA commitments

**Case Verdict**: PASS

---

### Case 4: Edge Case — No tracking, nothing to integrate

**Fixture**:
- `production/demo/alpha/state.txt` contains `Released`
- User selects `[D] No tracking — the demo used the same build as main`

**Expected behavior**:
1. Skill asks how changes were tracked (Phase 3)
2. User selects option D
3. Skill reports "Nothing to integrate." and stops
4. No report written, no story files created

**Assertions**:
- [ ] Option D is presented as a valid choice in Phase 3
- [ ] Skill exits cleanly on option D without error
- [ ] No writes occur when nothing to integrate
- [ ] "Nothing to integrate" message shown

**Case Verdict**: PASS

---

### Case 5: Edge Case — Ambiguous classification

**Fixture**:
- `production/demo/alpha/state.txt` contains `Released`
- One change is "large onboarding refactor that improves main game but is large"
- Classification is ambiguous: could be backport-to-main or needs-story

**Expected behavior**:
1. Skill encounters ambiguous change during Phase 4
2. Per skill instructions: "When classification is ambiguous, present both options to the user"
3. AskUserQuestion used to resolve
4. User selects needs-story
5. Classification proceeds with user-resolved value

**Assertions**:
- [ ] Ambiguous changes are not silently auto-classified
- [ ] AskUserQuestion surfaces the ambiguity with both options shown
- [ ] Skill uses user selection, not default assumption
- [ ] Resolved classification appears correctly in final report

**Case Verdict**: PASS

---

## Protocol Compliance

- [x] Uses `"May I write"` before writing integration report
- [x] Uses `"May I write"` separately before creating story files
- [x] Classification results presented to user before generating report output (Phase 4)
- [x] EA roadmap commitments flagged with ⚠️ — never silently deferred
- [x] Ends with Phase 8 summary including next steps
- [x] Does not merge code — classification and instructions only

---

## Coverage Notes

- Phase 3 option [A] (git branch/commit range) uses Grep/Glob on changed file paths. The exact grep behavior depends on branch naming and is not independently testable without a real git repo.
- Story file format depends on "most recently modified story file" in epics/ — the spec tests that the write occurs and approval is requested, not the exact format.
- EA roadmap audit (Phase 5) only runs if EA mode is detected — a non-EA run with ea-roadmap.md present is an untested edge case.
