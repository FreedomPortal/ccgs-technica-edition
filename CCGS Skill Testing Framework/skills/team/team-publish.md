# Skill Spec: /team-publish

> **Category**: team
> **Priority**: low
> **Spec written**: 2026-05-26

## Skill Summary

`/team-publish` orchestrates the publishing team through a structured publishing cycle in one of three modes: `launch`, `devlog`, or `full` (default). It reads project state (stage, publishing roadmap, community status, session state, recent sprint) then spawns three subagents in parallel — `publishing-manager` (roadmap review, store/press kit status), `community-manager` (platform activity, content calendar), and `writer` (copy drafts). All three run simultaneously. Results are collated into a unified publishing status summary with a consolidated, prioritized action item table. Writer output is draft-only — no files are written until the user explicitly approves each one individually in Phase 4. Partial results are always surfaced if any agent is blocked.

---

## Static Assertions

- [ ] Frontmatter has all required fields (`name`, `description`, `argument-hint`, `user-invocable`, `allowed-tools`)
- [ ] 2+ phase headings found
- [ ] At least one verdict keyword present (`PASS`, `FAIL`, `CONCERNS`, `APPROVED`, `BLOCKED`, `COMPLETE`, `READY`)
- [ ] If `allowed-tools` includes Write/Edit: `"May I write"` language present
- [ ] Next-step handoff section present at end

---

## Director Gate Checks

- **Applicable**: `team-publish` declares `agent: publishing-manager` in its frontmatter, indicating the publishing-manager is the lead agent. The publishing-manager reviews roadmap overdue/unlocked items and store readiness, and its report feeds the consolidated action item list. However, this is not a formal gate check (no PASS/FAIL verdict issued) — it is a status and triage skill. The COMPLETE/PARTIAL verdicts at the end reflect cycle completion, not a gate decision.

---

## Test Cases

### Case 1: Happy Path — Full mode with all context present
**Fixture**:
- No argument (defaults to `full` mode)
- `production/stage.txt` exists: "Beta"
- `production/publishing/publishing-roadmap.md` exists
- `production/publishing/community-status.md` exists
- `production/session-state/active.md` exists
- `production/sprints/sprint-5.md` exists (most recent)

**Expected behavior**:
1. Phase 1 reads all 5 context files
2. Reports: "Publishing cycle starting. Mode: full. Stage: Beta. Spawning publishing team in parallel."
3. Phase 2 issues all 3 Task calls simultaneously before waiting for any result
4. All three agents complete and return results
5. Phase 3 collates results into unified summary: Publishing Manager, Community Manager, Writer sections
6. Consolidated action item table rendered with Priority / Item / Owner / Suggested Skill columns
7. AskUserQuestion: "Publishing cycle complete. What would you like to do next?" with 5 options
8. User selects "Nothing — review only"
9. No files written; outputs `Verdict: COMPLETE`

**Assertions**:
- [ ] All 3 agents spawned before any result awaited
- [ ] Unified summary contains all three agent report sections
- [ ] Action item table has Priority, Item, Owner, Suggested Skill columns
- [ ] AskUserQuestion shown after collation

**Case Verdict**: PASS

---

### Case 2: Failure — One agent blocked
**Fixture**:
- `full` mode; context files present
- `community-manager` agent returns BLOCKED (no platforms configured)

**Expected behavior**:
1. All 3 agents spawned simultaneously
2. `publishing-manager` and `writer` complete; `community-manager` returns BLOCKED
3. Phase 3 surfaces immediately: "community-manager: BLOCKED — [reason]"
4. Summary produced with `publishing-manager` and `writer` sections complete
5. Community Manager section shows BLOCKED with reason
6. AskUserQuestion offered: "Skip community-manager and proceed", "Retry with narrower scope", "Stop here"
7. Outputs `Verdict: PARTIAL` — partial summary produced

**Assertions**:
- [ ] BLOCKED agent surfaced immediately, not silently skipped
- [ ] Completed agent results not discarded
- [ ] PARTIAL verdict used when any agent blocked
- [ ] Recovery options offered via AskUserQuestion

**Case Verdict**: PASS

---

### Case 3: Mode Variant — Devlog mode
**Fixture**:
- `/team-publish devlog` invoked
- `production/publishing/publishing-roadmap.md` exists
- `production/sprints/sprint-6.md` exists (most recent sprint with new features)

**Expected behavior**:
1. Mode set to `devlog`
2. `community-manager` prompt includes devlog-specific instruction: suggest 3 content angles, propose social topics
3. `writer` prompt set to devlog mode: draft devlog post + 2–3 social posts from same content
4. `publishing-manager` prompt omits full roadmap audit (devlog-specific scope only)
5. Writer output is draft text — presented for review, not written immediately

**Assertions**:
- [ ] Mode-specific agent prompt variants active for all 3 agents
- [ ] Writer produces devlog draft + social posts
- [ ] No files written during Phase 2–3 (draft only)

**Case Verdict**: PASS

---

### Case 4: Edge Case — Launch mode with missing press kit
**Fixture**:
- `/team-publish launch` invoked
- `production/stage.txt` exists: "Release"
- `production/publishing/publishing-roadmap.md` exists
- No `production/publishing/presskit*` files exist
- No `production/publishing/store-page*` files exist

**Expected behavior**:
1. `publishing-manager` reports: `Store Page: MISSING`, `Press Kit: MISSING`
2. Action items include: create press kit → `/publish-pitch` or equivalent; create store page → `/publish-steam-page`
3. Launch top-3 actions surfaced prominently
4. `Verdict: COMPLETE` — cycle runs; missing assets are reported as action items, not blockers

**Assertions**:
- [ ] Store Page and Press Kit status show MISSING (not silent)
- [ ] Action items reference suggested skills for resolution
- [ ] Cycle completes despite missing files (assets are action items, not blockers)

**Case Verdict**: PASS

---

### Case 5: Protocol — Per-file write approval
**Fixture**:
- `devlog` mode; writer has produced devlog draft and social posts
- User selects "Approve writer output — save drafts to production/publishing/"

**Expected behavior**:
1. Phase 4 triggered by user approval in Phase 3
2. Devlog: "May I write to `production/publishing/devlog-[N]-[date].md`?"
3. Social posts: "May I write to `production/publishing/social-[date].md`?"
4. Each file requires its own explicit approval — no batch write
5. No file written until that specific file's approval is given

**Assertions**:
- [ ] Uses "May I write" before file writes
- [ ] Presents content before approval
- [ ] No auto-write
- [ ] Per-file approval (not single approval for all files)

**Case Verdict**: PASS

---

## Protocol Compliance

- [ ] Uses `"May I write"` before any file writes (or is read-only and skips this)
- [ ] Presents findings/draft to user before requesting approval
- [ ] Ends with a recommended next step or follow-up action
- [ ] Does not auto-create files without user approval

---

## Coverage Notes

- Simultaneous Task spawning is a runtime behavior — static analysis can confirm all three Task calls appear in the skill but cannot verify they are truly issued before any result is awaited.
- The devlog numbering (`devlog-[N]`) requires runtime enumeration of existing devlog files; static tests cannot verify this counter is correct.
- Platform activity data (Twitter/X, Steam, Discord, etc.) in the community-manager report is runtime-only — depends on external platform state the agent cannot query directly without configured integrations.
- Writer copy quality and absence of AI writing patterns are runtime concerns; consider `/refine-copy` as a post-step for writer output.
- Session log data (`production/session-state/active.md`) is gitignored; CI test environments will always see this as empty.
