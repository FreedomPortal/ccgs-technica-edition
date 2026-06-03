# Coding Agent Behavioral Guidelines

Applies to all coding agents: `gameplay-programmer`, `engine-programmer`,
`ui-programmer`, `ai-programmer`, `network-programmer`, and all engine
specialists. Enforced during the `dev-story` implementation phase and any
other skill that spawns a coding agent.

**Tradeoff:** These guidelines bias toward caution over speed. For trivial
one-line changes, use judgment.

---

## 1. Think Before Execute

**Don't assume. Don't hide confusion. Surface tradeoffs.**

Before implementing:
- State your assumptions explicitly. If uncertain, ask.
- If multiple interpretations exist, present them — don't pick silently.
- If a simpler approach exists, say so. Push back when warranted.
- If something is unclear, stop. Name what's confusing. Ask.

## 2. Simplicity First

**Minimum code that solves the problem. Nothing speculative.**

- No features beyond what the story's acceptance criteria define.
- No abstractions for single-use code.
- No "flexibility" or "configurability" that wasn't in the ADR or story.
- No error handling for impossible scenarios — trust engine and framework guarantees.
- If you write 200 lines and it could be 50, rewrite it.

Ask yourself: "Would a senior engineer say this is overcomplicated?" If yes, simplify.

## 3. Surgical Changes

**Touch only what you must. Clean up only your own mess.**

When editing existing code:
- Don't "improve" adjacent code, comments, or formatting.
- Don't refactor things that aren't broken.
- Match existing style, even if you'd do it differently.
- If you notice unrelated dead code, mention it — don't delete it.

When your changes create orphans:
- Remove imports/variables/functions that YOUR changes made unused.
- Don't remove pre-existing dead code unless asked.

The test: every changed line should trace directly to an acceptance criterion
in the story file.

## 4. Goal-Driven Execution

**Define success criteria. Loop until verified.**

Transform story acceptance criteria into verifiable implementation goals:

- "Implement [mechanic]" → "Write the test first, then make it pass"
- "Fix the bug" → "Write a test that reproduces it, then make it pass"
- "Add validation" → "Write tests for invalid inputs, then make them pass"

For multi-step implementation, state a brief plan before coding:

```
1. [Step] → verify: [check]
2. [Step] → verify: [check]
3. [Step] → verify: [check]
```

Clarifying questions come **before** implementation, not after mistakes.
