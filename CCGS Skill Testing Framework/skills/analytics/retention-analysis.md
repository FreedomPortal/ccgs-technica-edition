# Skill Spec: /retention-analysis
> **Category**: analytics
> **Priority**: high
> **Spec written**: 2026-06-11

## Skill Summary

`/retention-analysis` analyzes player retention curves against genre benchmarks by classifying curve shape, identifying drop-off points, and producing prioritized action items. It operates in three modes—Analyze live data, Design monitoring framework, and Update prior analysis—branching after a benchmark source selection gate and a mode selection gate. The skill spawns a `growth-analyst` subagent for the analytical core and produces either `docs/analytics/retention-[slug].md` (analysis) or `docs/analytics/retention-framework.md` (framework), both gated behind explicit user approval before any write occurs.

---

## Static Assertions

- [x] Frontmatter has all required fields — `name`, `description`, `argument-hint`, `user-invocable`, `allowed-tools` all present
- [x] 2+ phase headings found — Phase 1, Phase 2, Analysis Phases 3–5, Framework Phases 3–4 all present
- [x] At least one verdict keyword present — "Verdict: COMPLETE" appears in both Analysis Phase 5 and Framework Phase 4 output blocks, and in the Recommended Next Steps section
- [x] If allowed-tools includes Write/Edit: "May I write" language present — Analysis Phase 5: "May I write the retention analysis to `docs/analytics/retention-[slug].md`?"; Framework Phase 4: "May I write the retention monitoring framework to `docs/analytics/retention-framework.md`?"
- [x] Next-step handoff section present at end — "Recommended Next Steps" section at end of file lists `/ab-test`, `/telemetry-design`, `/player-segmentation`, and re-run cadence

---

## Director Gate Checks

N/A — the skill does not explicitly trigger any director review agent. Analysis is delegated to `growth-analyst` via Task, which is a subagent spawn, not a director gate pattern.

---

## Test Cases

**Case 1: Happy Path — Full analysis with stored benchmarks and live data**

Fixture:
- `docs/reference/analytics/genre-benchmarks.md` exists with D1/D7/D30 data
- `docs/analytics/analytics-plan.md` exists
- `design/gdd/game-concept.md` exists with game title and genre
- User selects: Option A (stored benchmarks) → "Analyze live data" → provides complete D1/D7/D14/D30 data with cohort of 2,000 players

Expected behavior:
1. Phase 1 reads all four reference files
2. Presents stored benchmark summary and asks benchmark source question (AskUserQuestion)
3. User selects A — loads benchmarks from file, proceeds
4. Phase 2 mode question presented — user selects "Analyze live data"
5. Phase 3 prompts for retention data in specified format
6. Analysis Phase 4 spawns `growth-analyst` via Task with data, benchmarks, and context injected
7. Agent produces: curve classification, drop-off identification, benchmark comparison, 3 root cause hypotheses, recommended actions with segment/priority/next-skill, monitoring cadence
8. Results presented to user before any write
9. Phase 5 asks "May I write the retention analysis to `docs/analytics/retention-[slug].md`?"
10. After approval: file written, summary block output with Verdict: COMPLETE and 4 next steps

Assertions:
- AskUserQuestion called twice before data collection (benchmark source, mode)
- `growth-analyst` Task spawned with populated data, benchmarks, and context slots
- Retention data table includes vs. Genre Median and Status columns
- Benchmark gaps section only lists windows >5pp below median
- Root cause hypotheses: exactly 3, each linking to confirmable data
- Recommended Actions table includes Segment, Priority, Next Step columns
- Write gated — file not created until explicit approval
- Output block contains Verdict: COMPLETE
- Next steps reference /ab-test, /telemetry-design, /retention-analysis

Verdict: PASS if all file gates respected, agent output structured correctly, write gated, terminal block correct.

---

**Case 2: Failure/Blocked — No analytics plan, no benchmark file, only partial retention data**

Fixture:
- `docs/reference/analytics/genre-benchmarks.md` does NOT exist
- `docs/analytics/analytics-plan.md` does NOT exist
- `design/gdd/game-concept.md` does NOT exist
- User selects "Analyze live data" and provides only D1 and D7 (no D14, D30, D60, D90)

Expected behavior:
1. Phase 1 reads all four files — all either missing or absent; skill does not abort
2. Benchmark file not found — skill outputs the "Genre benchmark file not found" warning message verbatim, states "comparisons will note 'benchmark unavailable'", proceeds to Phase 2 without benchmark comparison
3. Mode: user selects Analyze live data
4. Phase 3 data prompt issued — user provides only D1 and D7
5. Skill proceeds with partial data; analysis note flags missing windows as "unavailable"
6. Analysis Phase 4 agent prompt receives "unavailable" for benchmark rows
7. Agent output labels the analysis as PARTIAL
8. Benchmark comparison section notes "no benchmark available — comparison skipped"
9. Report template reflects N/A in benchmark columns for all windows
10. Write gate still fires before file creation
11. Verdict: COMPLETE still issued (analysis produced, even if partial)

Assertions:
- Skill does not block or abort on missing reference files
- "benchmark unavailable" wording present in output
- Partial data does not prevent agent spawn
- PARTIAL label applied when only D1+D7 provided (per Collaborative Protocol)
- Write still gated behind approval
- No benchmark gap action items generated (no basis for comparison)

Verdict: PASS if skill degrades gracefully, partial label applied, no phantom benchmark data invented.

---

**Case 3: Mode Variant — Framework mode (no data yet)**

Fixture:
- `docs/reference/analytics/genre-benchmarks.md` exists
- No existing `docs/analytics/retention-*.md` files
- User selects: Option A (stored benchmarks) → "Design monitoring framework"

Expected behavior:
1. Phase 1 completes normally
2. Benchmark source: A selected, benchmarks loaded
3. Phase 2: user selects "Design monitoring framework"
4. Framework Phase 3 spawns `growth-analyst` via Task with framework prompt (7 output items: windows, events, cohort definition, dashboard spec, alert thresholds, baseline expectations, first analysis trigger)
5. Framework presented to user before write
6. Framework Phase 4 asks "May I write the retention monitoring framework to `docs/analytics/retention-framework.md`?"
7. After approval: `docs/analytics/` created if needed, file written
8. Output block: windows count, events count, dashboard description, output path, 3 next steps
9. Verdict: COMPLETE — retention monitoring framework produced

Assertions:
- Correct agent prompt variant used (7-item framework prompt, not 6-item analysis prompt)
- No retention data collected (Phase 3 data prompt not issued)
- Output block references `retention-framework.md` not `retention-[slug].md`
- Write path differs from analysis mode — `docs/analytics/retention-framework.md`
- Next steps reference programmer stories, /retention-analysis trigger condition, /telemetry-design
- Verdict wording: "retention monitoring framework produced" (not "retention analysis produced")

Verdict: PASS if framework mode follows separate code path with distinct output file and terminal block.

---

**Case 4: Edge Case — Update prior analysis mode**

Fixture:
- Two existing files: `docs/analytics/retention-2026-04-01.md`, `docs/analytics/retention-2026-05-01.md`
- User selects: Option A (stored benchmarks) → "Update prior analysis"

Expected behavior:
1. Phase 2 "Update prior analysis" path triggered
2. Skill lists existing `docs/analytics/retention-*.md` files
3. AskUserQuestion asks which file to update (or equivalent prompt)
4. User selects `retention-2026-05-01.md`
5. Selected file loaded as context before proceeding to Phase 3
6. Analysis Phase 3 data prompt issued — user provides new cohort data
7. Analysis continues normally (Phase 4 → 5)
8. Phase 5 write gate: slug may reflect updated cohort date or overwrite existing file — behavior depends on implementation
9. Verdict: COMPLETE issued

Assertions:
- Existing retention files listed (Glob used)
- File loaded as context before Phase 3 — not ignored
- No hardcoded file path — selection is dynamic
- Write still gated before any modification
- Analysis agent receives loaded prior file context in Task prompt

Coverage Note: The skill says "Load the selected file as context before proceeding to Phase 3" but does not specify how prior context is injected into the Phase 4 agent Task prompt. This is a documentation gap — the agent Task template in Phase 4 does not include a slot for prior analysis context. Testers should verify the subagent actually receives the prior file content.

Verdict: PASS if prior file is loaded and surfaced to agent; PARTIAL if file is read but not injected into Task prompt.

---

**Case 5: Benchmark Source Variant — User provides own benchmark data (Option C)**

Fixture:
- `docs/reference/analytics/genre-benchmarks.md` exists (to avoid the missing-file fallback)
- User selects: Option C (provide own data) → "Analyze live data"

Expected behavior:
1. Phase 1 presents stored benchmark summary
2. AskUserQuestion: user selects C — "Provide my own data"
3. Skill presents the exact format prompt: Platform, D1, D7, D30, D60 (optional), D90 (optional), Source
4. User provides values and source
5. Skill asks: "May I update `docs/reference/analytics/genre-benchmarks.md` with your data?"
6. User approves — user data appended as a new section with source noted
7. Skill then proceeds to Phase 2 using user-provided benchmarks (not stored data, not web data)
8. Analysis continues normally through Phases 3–5

Assertions:
- Option C path issues the structured format prompt verbatim (Platform/D1/D7/D30/source)
- Write gate fires before updating genre-benchmarks.md (separate from analysis write gate)
- User data stored as a new section, not overwriting existing entries
- Phase 4 agent receives user-provided benchmark values, not the original stored values
- Two distinct write approval gates in this path (benchmark update + analysis report)

Coverage Note: The skill specifies Option B (WebSearch) would trigger a WebSearch call, but `WebSearch` is not listed in `allowed-tools`. If the user selects B, the skill cannot fulfill it — this is a missing tool declaration. Testers should surface this as a defect.

Verdict: PASS if both write gates fire, user benchmarks flow through to agent, new section appended cleanly.

---

## Protocol Compliance

- [x] Uses "May I write" before file writes — explicitly present in Analysis Phase 5 and Framework Phase 4; benchmark update (Options B and C) also gated with "May I update...?" language
- [x] Presents findings before approval — Phase 4 "Present analysis to user before writing" instruction explicit; Framework Phase 3 "Present framework to user" explicit
- [x] Ends with next step — "Recommended Next Steps" section closes the skill with four follow-on actions
- [x] No auto-create without approval — Collaborative Protocol section explicitly states "Never write files without asking"; all write paths confirmed gated

---

## Coverage Notes

**AL1 — Reads data before analysis, never invents numbers**: MET. Phase 1 reads four reference files. Phase 3 collects live data from the user. Phase 4 injects both into the agent prompt with explicit slots. The Collaborative Protocol states "Drop-off hypotheses must link to specific observable data — no unfounded assertions."

**AL2 — Benchmarks explicitly sourced**: MET. Phase 1 Benchmark Source Selection displays source attribution (GameAnalytics, Adjust, AppsFlyer, Mistplay, Sensor Tower) from the stored file. Option B requires 3+ sources from WebSearch. Option C requires a Source field. The agent prompt passes benchmark origin into the Task.

**AL3 — Structured findings table with severity**: MET. Analysis output template includes a Retention Data table (with vs. Genre Median and Status columns), a Benchmark Gaps / Action Items section, and a Recommended Actions table with Priority column (HIGH/MEDIUM/LOW). Drop-off confidence levels (High/Medium/Low) also present.

**AL4 — All output gated behind "May I write"**: MET. Two distinct write gates confirmed: `docs/analytics/retention-[slug].md` (Analysis Phase 5) and `docs/analytics/retention-framework.md` (Framework Phase 4). Benchmark file updates (Options B and C) also explicitly gated.

**AL5 — Explicit follow-on skill recommended**: MET. Both terminal output blocks name specific follow-on skills (`/ab-test`, `/telemetry-design`, `/player-segmentation`). The Recommended Next Steps section closes the file with the same three skills plus re-run cadence instruction.

**Gaps identified:**

1. `WebSearch` not in `allowed-tools` — Option B invokes WebSearch but the tool is not declared in frontmatter. This will cause a tool-unavailable error if the user selects B. Either the allowed-tools list must be updated or Option B must be removed.

2. Update Prior Analysis — Phase 4 Task prompt template has no slot for prior analysis context. The skill says "Load the selected file as context" but the agent Task template does not include a section to paste it. Prior file content may be silently dropped.

3. Partial data label threshold — The Collaborative Protocol says "only D1 + D7" triggers PARTIAL label, but the condition "two data points" is not given a precise threshold. If a user provides D1, D7, and D30 but omits D14 and D60, it is unclear whether PARTIAL applies.

4. slug definition is informal — Phase 5 defines slug as "cohort start date or topic" with an example but no enforcement mechanism. Update Prior Analysis mode may produce a conflicting slug when writing over or alongside an existing file.