# Demo Campaign State Template

This document describes the directory structure and file formats for a demo campaign
tracked under `production/demo/[demo-id]/`.

---

## Directory Structure

```
production/demo/
└── [demo-id]/                    # e.g., steam-next-fest-2026-10, always-on-demo, ea-launch
    ├── state.txt                 # Single line: current sub-stage name (written by /demo-gate)
    ├── demo-plan.md              # Copy or symlink of design/demo/demo-plan.md for this campaign
    ├── ea-roadmap.md             # [EA only] Player-facing commitments before 1.0
    ├── playtests/                # Playtest session records for this campaign
    │   ├── session-001.md
    │   └── session-002.md
    ├── evaluation.md             # Synthesis of playtest findings + conversion blocker list
    ├── integration-report.md     # Output of /demo-integrate after campaign wraps
    └── go-live.md                # Go-live confirmation record (date, platform link, notes)
```

---

## state.txt Format

Single line, no trailing newline. One of these exact values:

```
Planning
Scoping
Building
Playtesting
Evaluating
Iterating
Polishing
Released
Publishing
Live
```

`Publishing` and `Live` are only valid when the campaign has `Early Access: true` in its demo-plan.

Written by `/demo-gate` on PASS. Never edit manually unless recovering from a known-bad state.

---

## Demo ID Conventions

Choose a demo-id that describes the campaign purpose, not a number:

| Good | Bad |
|------|-----|
| `steam-next-fest-2026-10` | `demo-001` |
| `always-on-store-demo` | `demo-v2` |
| `ea-launch` | `early-access` |
| `press-preview-2026-07` | `build-3` |

Multiple campaigns can exist simultaneously (e.g., an always-on demo while EA is live).

---

## ea-roadmap.md Format

*(EA campaigns only — created during `/demo-plan --early-access` or authored manually)*

```markdown
# EA Roadmap Commitments — [demo-id]

**Created**: [date]
**Last updated**: [date]

These commitments were made public to Early Access players. Each must be delivered
before 1.0 or explicitly communicated as changed/removed with player notification.

## Committed Features

| Commitment | Status | Target sprint | Notes |
|------------|--------|--------------|-------|
| [Feature description visible to players] | Pending | Sprint 7 | |
| [Another commitment] | In Progress | Sprint 6 | |
| [Completed item] | Done | Sprint 5 | Released in patch 0.3 |

## Content Commitments

| Content | Status | Notes |
|---------|--------|-------|
| [Content area promised] | Pending | |

## Explicit Non-Commitments

Things players asked about that we explicitly did NOT commit to:
- [Feature not committed] — communicated as "not planned" or "maybe post-1.0"
```

This file is read by `/demo-integrate --early-access` to generate Required 1.0 stories.

---

## evaluation.md Format

```markdown
# Demo Evaluation — [demo-id]

**Date**: [date]
**Sessions analyzed**: [N]
**Conversion signal**: [X/N playtesters would wishlist or buy]

## Conversion Blockers (P1 — fix before next iteration)

1. **[Blocker name]**
   - Type: [UX confusion | onboarding gap | pacing issue | technical bug | content gap]
   - Observed in: [N/N sessions]
   - Description: [what happened]
   - Proposed fix: [what to change]

## Secondary Issues (P2 — address if time allows)

2. **[Issue name]**
   - Type: [same categories]
   - Description: [what happened]

## Positive Signals (keep these)

- [What playtesters responded to positively]

## Verdict

[GO — conversion blockers are minor or zero / NO-GO — address P1 blockers before next build]
```
