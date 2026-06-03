## General Standards

### Sprint Close-Out Sequence (ENFORCED ORDER)

The sprint close-out sequence is non-negotiable and must run in this order:

```
/smoke-check sprint → /team-qa sprint → /retrospective → /gate-check → /sprint-plan new
```

**Retrospective MUST exist before `/sprint-plan new` runs.**

If no retrospective file exists at `production/retrospectives/retro-sprint-[N]-*.md`
when `/sprint-plan new` is invoked: STOP. Run `/retrospective` first.

**Why**: Sprint can be closed without a retrospective. Lessons went uncaptured.
Velocity data became estimated rather than measured. The same process failures recurred
across sprints. A missing retro breaks the compound-improvement loop.

**How to apply**: Before generating any Sprint N+1 plan, glob for the Sprint N retro file.
If not found, surface as a BLOCKED condition and prompt the user to run `/retrospective`.

## Project-Specific Rules

*(None yet — add project-specific workflow constraints here as they emerge.)*
