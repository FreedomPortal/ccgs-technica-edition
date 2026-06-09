# Rules Reference

## Global Rules (no path restriction — apply everywhere)

| Rule File | Enforces |
| ---- | ---- |
| `workflow.md` | Sprint close-out sequence, retro-before-plan enforcement — run via `/sprint-close` |
| `coding-agent-behavior.md` | Think before execute, simplicity, surgical changes, goal-driven execution — passed to all coding agent Task prompts via `dev-story` |

## Path-Specific Rules

Rules automatically enforced when editing files in matching paths:

| Rule File | Path Pattern | Enforces |
| ---- | ---- | ---- |
| `src-baseline.md` | `src/**` | Doc comments, data-driven values, DI, ADR requirement, engine-reference check |
| `gameplay-code.md` | `src/gameplay/**` | Data-driven values, delta time, no UI references |
| `engine-code.md` | `src/core/**` | Zero allocs in hot paths, thread safety, API stability |
| `ai-code.md` | `src/ai/**` | Performance budgets, debuggability, data-driven params |
| `network-code.md` | `src/networking/**` | Server-authoritative, versioned messages, security |
| `ui-code.md` | `src/ui/**` | No game state ownership, localization-ready, accessibility |
| `design-docs.md` | `design/gdd/**` | Required 8 sections, formula format, edge cases |
| `narrative.md` | `design/narrative/**` | Lore consistency, character voice, canon levels |
| `data-files.md` | `assets/data/**` | JSON validity, naming conventions, schema rules |
| `test-standards.md` | `tests/**` | Test naming, coverage requirements, fixture patterns |
| `prototype-code.md` | `prototypes/**` | Relaxed standards, README required, hypothesis documented |
| `shader-code.md` | `assets/shaders/**` | Naming conventions, performance targets, cross-platform rules |
