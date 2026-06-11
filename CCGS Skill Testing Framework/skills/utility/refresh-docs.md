# Skill Spec: /refresh-docs
> **Category**: utility
> **Priority**: medium
> **Spec written**: 2026-06-11

## Skill Summary

`/refresh-docs` maintains `docs/engine-reference/` by auditing engine reference documentation for staleness and populating module files via version-aware web fetch. It operates in two distinct modes: `audit` (read-only staleness report across all engine reference files) and `update [engine] [module]` (populates or refreshes a single module file, always prompting for a target version before proceeding, with an optional `--web` flag that triggers WebSearch/WebFetch to source content from official documentation). Write operations only occur in `update` mode with `--web`, are preceded by a draft presentation, and require explicit user approval before any file is written.

---

## Static Assertions

- [x] Frontmatter has all required fields (`name`, `description`, `argument-hint`, `user-invocable`, `allowed-tools`, `model`)
- [x] 2+ phase headings (audit has Phases 1–5; update has Phases 1–5)
- [x] Verdict keyword present ("Verdict: COMPLETE — engine reference updated.")
- [x] If Write/Edit in allowed-tools: "May I write" language present (Phase 5: `Ask: "May I write docs/engine-reference/[engine]/[module-path]? [Y/N]"`)
- [x] Next-step handoff present ("Run `/refresh-docs audit` to check overall reference health after updates" + additional handoff lines under Recommended Next Steps)

---

## Director Gate Checks

N/A — the skill contains no director gate, spawns no subagents, and does not read review-mode. U2 does not apply.

---

## Test Cases

### Case 1: Happy Path — audit with stale and missing files

**Fixture**: `docs/engine-reference/` contains a Godot subdirectory. `README.md` has frontmatter with `staleness_threshold_days: 90`. One module file has `Last verified: 2025-11-01` (>90 days before 2026-06-11). One expected module file (`modules/scripting.md`) is absent entirely.

**Expected behavior**:
- Phase 1 reads `README.md`, extracts threshold (90 days).
- Phase 2 scans `.md` files, calculates age; the 2025-11-01 file is classified STALE.
- Phase 3 detects `modules/scripting.md` as MISSING with priority HIGH.
- Phase 4 checks `docs/reference/analytics/genre-benchmarks.md` and reports its status.
- Phase 5 outputs the full formatted audit report with Stale, Missing, Summary, and Recommended Actions sections.
- No files are written.

**Assertions**:
- Report includes stale file row with engine, filename, last-verified date, and age.
- Report includes missing file row for `modules/scripting.md` with priority HIGH.
- Recommended Actions list includes `/refresh-docs update godot scripting --web`.
- No Write tool call is made.

**Verdict**: PASS

---

### Case 2: Failure / Blocked — update with unknown engine

**Fixture**: User invokes `/refresh-docs update frostbite rendering`. `docs/engine-reference/` contains no `frostbite/` subdirectory.

**Expected behavior**:
- Phase 1 of update mode validates `[engine]` against known engine directories.
- `frostbite` is not found.
- Skill surfaces a validation error and stops without proceeding to the version prompt or any web fetch.
- No files are written.

**Assertions**:
- Skill does not emit a version prompt.
- Skill does not call WebSearch or WebFetch.
- Error message indicates `frostbite` is not a known engine directory.
- No Write tool call is made.

**Verdict**: PASS (if validation blocks) / FAIL (if skill proceeds past Phase 1)

---

### Case 3: Mode Variant — update without `--web` flag

**Fixture**: User invokes `/refresh-docs update godot physics`. `docs/engine-reference/godot/VERSION.md` exists and pins Godot 4.6. `modules/physics.md` exists with `Last verified: 2025-09-01` (STALE). User responds to version prompt with "Godot 4.6".

**Expected behavior**:
- Phase 1 shows current module status (STALE) and prompts for target version. Waits for input.
- Phase 2 (no `--web` flag): outputs the Manual Verification Checklist with engine-specific documentation URLs and stop. Does not call WebSearch, WebFetch, or Write.

**Assertions**:
- Output contains "Manual Verification Checklist — Godot physics" heading.
- Output contains Godot-specific URLs (docs.godotengine.org migration guide, GDScript/physics references).
- Output includes guidance to run `/refresh-docs update godot physics --web` to auto-populate.
- No WebSearch, WebFetch, or Write tool calls are made.
- Skill does not proceed to Phase 3 or beyond.

**Verdict**: PASS

---

### Case 4: Edge Case — audit with no `README.md` or missing `staleness_threshold_days`

**Fixture**: `docs/engine-reference/README.md` is absent or contains no parseable YAML frontmatter.

**Expected behavior**:
- Phase 1 fails to read or parse the config.
- Skill falls back to default: `staleness_threshold_days: 90`, `analytics_staleness_threshold_days: 365`.
- Audit proceeds normally using default thresholds.
- Report header shows "Threshold: 90 days".

**Assertions**:
- No crash or halt when `README.md` is missing or frontmatter is malformed.
- Default threshold (90) is used and reflected in report output.
- Audit phases 2–5 complete normally.

**Verdict**: PASS (if defaults applied) / FAIL (if skill errors out or skips phases)

---

### Case 5: Most Relevant Variant — update with `--web` flag, draft presented, write approved then VERSION.md update offered

**Fixture**: User invokes `/refresh-docs update godot scripting --web`. `docs/engine-reference/godot/VERSION.md` pins Godot 4.5. `modules/scripting.md` is an EMPTY-STUB. User responds to version prompt with "Godot 4.6" (different from pinned 4.5).

**Expected behavior**:
- Phase 1: reads VERSION.md, shows EMPTY-STUB status, prompts for target version. Waits.
- Phase 3: calls WebSearch using `site:docs.godotengine.org upgrading_to_godot_4.6` and changelog URL. Calls WebFetch on relevant results. Extracts scripting-domain content only.
- Phase 4: composes draft using the engine-ref-module template format (Last verified, What Changed, Current API Patterns, Common Mistakes, Official Documentation). Presents draft to user before writing.
- Phase 5: asks "May I write `docs/engine-reference/godot/modules/scripting.md`? [Y/N]". On approval, writes the file. Because target version (4.6) differs from pinned (4.5), asks "Update VERSION.md pinned version to Godot 4.6? [Y/N]".

**Assertions**:
- Phase 3 uses WebSearch and WebFetch; no write occurs during these phases.
- Draft is presented before the write approval prompt.
- Write approval uses exact "May I write" phrasing with full path.
- VERSION.md update is offered as a separate approval gate, not written automatically.
- Only claims sourced from fetched official docs appear in the module file; fabricated details must be absent or marked `[needs-verification]`.
- Skill ends with "Verdict: COMPLETE" and recommended next steps.

**Verdict**: PASS

---

## Protocol Compliance

- [x] "May I write" before file writes (Phase 5 of update mode: explicit ask with path and [Y/N])
- [x] Presents findings before approval (Phase 4 drafts and presents module content before Phase 5 write gate; Phase 5 audit outputs report without writing)
- [x] Ends with next step (Recommended Next Steps section lists follow-on `/refresh-docs` commands)
- [x] No auto-create without approval (update mode stops at checklist without `--web`; with `--web` requires explicit Y/N before any write)

---

## Coverage Notes

**U1**: All 7 static checks should pass. Frontmatter is complete (6 fields present). Phase headings are present in both modes (5 phases each). Verdict keyword is present. "May I write" language matches the Write tool in allowed-tools. Next-step handoff is explicit in Recommended Next Steps.

**U2**: Not applicable. The skill does not spawn any director gate, contains no `review-mode` read, and has no full/lean/solo branching logic.

**Gap note**: The skill's `--web` branch (Phase 3) depends on WebSearch and WebFetch returning usable results. Test Case 5 assumes successful fetches. A supplementary case could cover WebSearch returning no results or WebFetch failing — the skill does not document explicit fallback behavior for this scenario, which represents a spec ambiguity worth flagging to the skill author.