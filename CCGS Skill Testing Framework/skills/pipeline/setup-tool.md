# Skill Spec: /setup-tool

> **Category**: pipeline
> **Priority**: low
> **Spec written**: 2026-05-26

## Skill Summary

`/setup-tool` configures a game development tooling project by capturing the tool's purpose, I/O contract, and tech stack in `tools/TOOL_SPEC.md`. It operates in named mode (`/setup-tool [tool_name]`) or fully guided mode with no argument. Before asking questions it silently checks for an existing `TOOL_SPEC.md`, engine references in `CLAUDE.md`, and existing scripts in `tools/`. Questions are asked in four groups (purpose, target engine + formats, tech stack, I/O contract). A spec draft is shown in conversation for approval before any file is written. After confirmation it writes `tools/TOOL_SPEC.md` and optionally updates the Technology Stack section in `CLAUDE.md` — each with its own approval gate. It ends with next-step recommendations including `/reverse-document` and `/architecture-decision`.

---

## Static Assertions

- [ ] Frontmatter has all required fields (`name`, `description`, `argument-hint`, `user-invocable`, `allowed-tools`)
- [ ] 2+ phase headings found
- [ ] At least one verdict keyword present (`PASS`, `FAIL`, `CONCERNS`, `APPROVED`, `BLOCKED`, `COMPLETE`, `READY`)
- [ ] If `allowed-tools` includes Write/Edit: `"May I write"` language present
- [ ] Next-step handoff section present at end

---

## Director Gate Checks

- **N/A**: `/setup-tool` does not route through a director gate. It is a project initialization skill. No verdict is issued — the output is a spec document whose quality is validated by user review before writing. The skill's guardrails (never overwrite without reading, always show draft first) serve as self-contained quality gates.

---

## Test Cases

### Case 1: Happy Path — Named mode, fresh project
**Fixture**:
- `/setup-tool texture-atlas-packer` invoked
- `tools/TOOL_SPEC.md` does not exist
- `CLAUDE.md` exists but does not reference an engine (TO BE CONFIGURED)
- `tools/` directory is empty

**Expected behavior**:
1. Detect phase: no existing spec, no engine reference, no existing scripts
2. Group 1 questions: purpose and workflow position
3. Group 2 questions: target engine and file formats
4. Group 3 questions: language, runtime, dependencies
5. Group 4 questions: inputs, outputs, edge cases
6. Draft `TOOL_SPEC.md` shown in conversation with all sections filled
7. "Here's the spec I'd write to `tools/TOOL_SPEC.md`. Want to adjust anything before I save it?"
8. User approves; file written to `tools/TOOL_SPEC.md`
9. Skill asks: "May I also update the Technology Stack section in CLAUDE.md?"
10. User approves; CLAUDE.md Technology Stack section updated
11. Next steps block displayed with `/reverse-document` and `/architecture-decision` options

**Assertions**:
- [ ] Questions asked in groups (not all at once)
- [ ] Draft shown before any write
- [ ] Separate approval for TOOL_SPEC.md and CLAUDE.md
- [ ] Tool name from argument used (not prompted again)
- [ ] Next steps block present with at least 3 options

**Case Verdict**: PASS

---

### Case 2: Failure — Existing spec detected
**Fixture**:
- `/setup-tool my-exporter` invoked
- `tools/TOOL_SPEC.md` already exists with prior content

**Expected behavior**:
1. Detect phase reads existing `TOOL_SPEC.md`
2. Skill presents: "I found an existing spec — want to review and update it, or start fresh?"
3. User selects "Review and update it"
4. Existing content read and shown; user guided to confirm changes
5. Updated spec shown as draft before overwrite
6. Write approval requested before overwriting

**Assertions**:
- [ ] Existing spec detected and read before prompting
- [ ] User offered update vs. start-fresh choice
- [ ] No overwrite without reading existing content first
- [ ] Write approval required before overwrite

**Case Verdict**: PASS

---

### Case 3: Mode Variant — No argument (fully guided mode)
**Fixture**:
- `/setup-tool` invoked with no argument
- No existing `TOOL_SPEC.md`
- `CLAUDE.md` references Godot 4.6

**Expected behavior**:
1. Detect phase: notes CLAUDE.md references game engine — informs user this may be a game project with a tooling component
2. Group 1: asks tool purpose via plain-text prompt
3. Tool name derived from user's purpose description (or asked explicitly)
4. Groups 2–4 proceed as normal
5. Draft spec includes tool name derived from guided session

**Assertions**:
- [ ] Engine reference in CLAUDE.md noted to user
- [ ] Plain-text purpose prompt shown (not AskUserQuestion options)
- [ ] Questions remain in groups (not dumped all at once)

**Case Verdict**: PASS

---

### Case 4: Edge Case — Existing scripts in tools/ directory
**Fixture**:
- `/setup-tool level-export-tool` invoked
- `tools/TOOL_SPEC.md` does NOT exist
- `tools/export.py` and `tools/config.json` already exist

**Expected behavior**:
1. Detect phase finds existing scripts in `tools/`
2. Skill notes: "Existing scripts found — strongly recommend `/reverse-document` afterward to verify the spec matches reality"
3. Guided questions proceed normally
4. Next steps block emphasizes `/reverse-document` as first priority

**Assertions**:
- [ ] Existing scripts detected and flagged to user
- [ ] `/reverse-document` strongly recommended in next steps
- [ ] Skill does not read or attempt to parse existing scripts directly

**Case Verdict**: PASS

---

### Case 5: Protocol — Draft shown before write, per-file approval
**Fixture**:
- Fresh tooling project; all questions answered

**Expected behavior**:
1. Full draft spec rendered in conversation: "Here's the spec I'd write… Want to adjust anything before I save it?"
2. User approves draft
3. TOOL_SPEC.md written only after explicit confirmation
4. Separate "May I also update the Technology Stack section in CLAUDE.md?" gate before CLAUDE.md write
5. Neither file auto-written

**Assertions**:
- [ ] Uses "May I write" (or equivalent approval language) before file writes
- [ ] Presents content before approval
- [ ] No auto-write
- [ ] CLAUDE.md update is a separate optional approval gate from TOOL_SPEC.md

**Case Verdict**: PASS

---

## Protocol Compliance

- [ ] Uses `"May I write"` before any file writes (or is read-only and skips this)
- [ ] Presents findings/draft to user before requesting approval
- [ ] Ends with a recommended next step or follow-up action
- [ ] Does not auto-create files without user approval

---

## Coverage Notes

- The CLAUDE.md Technology Stack update modifies an existing file — the guardrail "NEVER overwrite an existing TOOL_SPEC.md without reading it first" applies to TOOL_SPEC.md explicitly; the spec should be read as applying to CLAUDE.md edits as well.
- Tool name derivation in no-argument mode (when the user describes purpose in free text) is runtime logic — static tests cannot verify the name extraction or slug formatting.
- `WebSearch` is in `allowed-tools` but is not referenced in any phase of the skill — its intended use case is undocumented. This is a coverage gap worth flagging for the skill author.
- The CLAUDE.md Technology Stack section format is prescribed in the skill; runtime tests should verify the Edit does not damage surrounding CLAUDE.md content.
