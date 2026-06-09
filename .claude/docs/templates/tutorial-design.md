# Tutorial Design: [Game Title]

**Created**: [YYYY-MM-DD]
**Stage**: [Pre-Production | Vertical Slice]
**Status**: [Draft | Approved | Implemented]
**Lead**: ux-designer | **Mechanic source**: game-designer

---

## Mechanic Inventory

| Mechanic | Complexity | Teachability | Dependencies | Critical Path |
|----------|-----------|-------------|-------------|--------------|
| [name] | Simple / Compound / Systemic | Discovery / Must-teach | [mechanic names or "None"] | Yes / No |

---

## Teaching Sequence

| # | Segment Name | Mechanics Introduced | Prerequisites | Est. Duration |
|---|-------------|---------------------|--------------|--------------|
| 1 | [name] | [mechanic list] | None | [N] min |
| 2 | [name] | [mechanic list] | Segment 1 | [N] min |

**Total estimated tutorial time**: [N] minutes

---

## Scaffolding Strategy

| Mechanic | Method | Justification | UI / World Element Needed |
|----------|--------|--------------|--------------------------|
| [name] | Diegetic / Contextual / Forced / Scaffolded | [reason] | [element or "None"] |

**Forced tutorial moments**: [N] — [flag if > 3 — high friction risk]

---

## Skip / Replay Design

### Skip Conditions

| Segment | Skip Condition | Trigger |
|---------|---------------|---------|
| [segment] | [competence check description] | [N correct completions / returning player flag / manual skip] |

### Replay Access

- **Location**: [Help menu / Settings / Not available]
- **Trigger**: [how player re-opens a tutorial segment]

### Accessibility Fallback

- **Always-available reference**: [in-game codex / `/player-docs help-text` strings / external manual link]

---

## Tutorial State Machine

```
pre-tutorial
  → [segment-1-name]  (entry: [condition])
      → [segment-2-name]  (entry: [segment-1 complete])
          → ...
              → complete
  → skipped  (entry: [skip condition])
```

### Persistence Requirements

States that must survive session quit:

| State | Persistence Required | Reason |
|-------|---------------------|--------|
| [segment name] | Yes / No | [reason] |

---

## Implementation Notes

- This doc is the contract for `/dev-story tutorial` implementation stories
- Help text strings derived from this doc: run `/player-docs help-text` after approval
- Accessibility review: run `/ux-review design/tutorial/tutorial-design.md`
