# Skill Spec: /press-outreach

> **Category**: utility
> **Priority**: low
> **Spec written**: 2026-05-26

## Skill Summary

`/press-outreach` builds a media contact list and drafts outreach templates for journalists, YouTubers, and streamers. It reads the game concept, publishing roadmap, existing press contacts, and any press kit files. It determines outreach goal (review coverage, wishlist push, content creator coverage, or all) and time-to-launch, then spawns two agents simultaneously: `publishing-manager` (contact tiers, outlet suggestions, email templates, timing advice, solo-dev scope filter) and `community-manager` (Reddit/Discord amplification strategy). After presenting agent output for user review, it asks approval before writing `production/publishing/press-contacts.md`. A humanize pass runs automatically before the final COMPLETE verdict and next-step handoff.

---

## Static Assertions

- [ ] Frontmatter has all required fields (`name`, `description`, `argument-hint`, `user-invocable`, `allowed-tools`)
- [ ] 2+ phase headings found
- [ ] At least one verdict keyword present (`PASS`, `FAIL`, `CONCERNS`, `APPROVED`, `BLOCKED`, `COMPLETE`, `READY`)
- [ ] If `allowed-tools` includes Write/Edit: `"May I write"` language present
- [ ] Next-step handoff section present at end

---

## Director Gate Checks

- **N/A**: `/press-outreach` does not invoke a director gate check. It spawns two specialist agents (`publishing-manager`, `community-manager`) to produce research content, but neither acts as a gate with a blocking verdict. The skill itself reviews and writes — no gate approval phase is defined.

---

## Test Cases

### Case 1: Happy Path — First-Run Contact List Creation
**Fixture**:
- `design/gdd/game-concept.md` exists with title, genre, one-line hook, target audience
- `production/publishing/publishing-roadmap.md` exists with dev stage and launch window
- No `production/publishing/press-contacts.md` exists
- No press kit files found via Glob

**Expected behavior**:
1. Reads all source files; notes press kit is missing (advisory warning, does not stop)
2. No existing contacts file; skips mode-selection question; proceeds to Phase 3
3. Asks outreach goal (review / wishlist push / content creators / all)
4. Asks time-to-launch (6+ months / 2–3 months / under 1 month / already launched)
5. Reads game concept again; spawns `publishing-manager` and `community-manager` via Task simultaneously
6. Presents full agent output (contact suggestions, templates, timing, amplification) before writing
7. Asks `"May I write the press contacts file to production/publishing/press-contacts.md?"`
8. Writes `press-contacts.md` with all required sections
9. Runs humanize pass on the file
10. Outputs structured summary with contact counts, template count, and COMPLETE verdict

**Assertions**:
- [ ] Advisory note about missing press kit surfaced but does not halt execution
- [ ] Mode-selection question NOT fired (no existing contacts file)
- [ ] Both goal and timing questions asked before agent spawn
- [ ] Both agents spawned via Task simultaneously (not sequentially)
- [ ] Agent output presented to user before any write
- [ ] `"May I write"` approval gate fires
- [ ] Output file contains: Outreach Templates (3), Timing Guide, Contact List table, Amplification Strategy, Minimum Viable Outreach sections
- [ ] COMPLETE verdict in summary
- [ ] Next steps include verifying contact details independently

**Case Verdict**: PASS

---

### Case 2: Failure — Missing Game Concept
**Fixture**:
- `design/gdd/game-concept.md` does not exist
- No other publishing files present

**Expected behavior**:
1. Phase 1 read finds no game concept
2. Skill halts with: `"No game concept found. Run /brainstorm first — press outreach requires knowing the game's genre, target audience, and hook."`
3. No questions asked, no agents spawned, no files written

**Assertions**:
- [ ] Failure message references `/brainstorm`
- [ ] Failure message explains genre/audience/hook dependency
- [ ] No AskUserQuestion calls issued
- [ ] No Task agents spawned
- [ ] No files written

**Case Verdict**: PASS

---

### Case 3: Mode Variant — Update Contact Statuses
**Fixture**:
- `design/gdd/game-concept.md` exists
- `production/publishing/press-contacts.md` exists with contact list populated
- User selects "Update contact statuses" at mode question

**Expected behavior**:
1. Detects existing contacts file; presents four-option mode question
2. User selects "Update contact statuses"
3. Skill loads existing contact list; prompts user for updated Status values per contact (or batch update instructions)
4. Asks approval before writing updated statuses to the contacts file
5. Does NOT re-spawn agents or regenerate templates
6. Outputs COMPLETE verdict

**Assertions**:
- [ ] Four-option mode question fires
- [ ] Agents NOT re-spawned in status-update mode
- [ ] Templates NOT regenerated
- [ ] Approval gate fires before writing updated statuses
- [ ] COMPLETE verdict present

**Case Verdict**: PASS

---

### Case 4: Edge Case — Already Launched Timing
**Fixture**:
- `design/gdd/game-concept.md` exists with a launched game
- `production/publishing/publishing-roadmap.md` exists (post-launch stage)
- No existing contacts file
- User selects "Already launched" for time-to-launch

**Expected behavior**:
1. Timing recorded as "Already launched"
2. `publishing-manager` agent prompt substituted with "Already launched" timing
3. Agent output adjusts tone: focuses on long-tail visibility, discount events, update milestones — not review embargoes
4. Templates reflect post-launch context (no embargo language)
5. Timing Guide section reflects post-launch strategy
6. Approval gate and write proceed normally

**Assertions**:
- [ ] "Already launched" timing passed into agent prompt
- [ ] No embargo date recommendation in timing guide
- [ ] Templates do not contain pre-launch review request language
- [ ] Approval gate fires before write
- [ ] COMPLETE verdict present

**Case Verdict**: PASS

---

### Case 5: Protocol — Approval Gate Before File Writes
**Fixture**:
- `design/gdd/game-concept.md` exists, no existing contacts file
- Both agents have returned output
- Output has been presented to user for review

**Expected behavior**:
1. After presenting full agent output, skill asks `"May I write the press contacts file to production/publishing/press-contacts.md?"`
2. Waits for explicit confirmation before any Write call
3. Does not write on agent completion alone
4. Does not write during the presentation step

**Assertions**:
- [ ] Uses "May I write" before file writes
- [ ] Presents content before approval
- [ ] No auto-write

**Case Verdict**: PASS

---

## Protocol Compliance

- [ ] Uses `"May I write"` before any file writes (or is read-only and skips this)
- [ ] Presents findings/draft to user before requesting approval
- [ ] Ends with a recommended next step or follow-up action
- [ ] Does not auto-create files without user approval

---

## Coverage Notes

- The SKILL.md explicitly prohibits suggesting bought contact lists, automated mass email tools, or spam-classified outreach — this is a behavioral constraint on agent output that is runtime-only and cannot be verified statically.
- The advisory note about missing press kit (Phase 1) is non-blocking by design; testers should confirm the skill proceeds rather than halts when no presskit files are found.
- The humanize writing pass (Phase 6, `/refine-copy` in-place) runs automatically without user approval — runtime-only behavior.
- Agent-suggested contact names are explicitly flagged as starting points requiring independent verification; whether the summary output contains this disclaimer is a runtime assertion.
- Parallel Task spawn (both agents simultaneously) is a coordination requirement; static analysis can confirm both Task calls are described in the SKILL.md but cannot verify they fire concurrently at runtime.
- The "Add new contacts" mode is listed as an option but not fully detailed in the SKILL.md beyond the mode selection — this path's behavior is partially underdefined and warrants a follow-up skill-improve pass.
