# Directory Structure

```text
/
├── CLAUDE.md                    # Master configuration
├── .claude/                     # Agent definitions, skills, hooks, rules, docs
│   └── agent-memory/            # Per-agent persistent memory (MEMORY.md index + shards/)
├── src/                         # Game source code (core, gameplay, ai, networking, ui, tools)
├── assets/                      # Game assets (art, audio, vfx, shaders, data)
├── design/                      # Game design documents (gdd, narrative, levels, balance)
├── docs/                        # Technical documentation (architecture, api, postmortems)
│   ├── architecture/            # ADRs, control manifest, TR registry, data schema examples
│   ├── engine-reference/        # Curated engine API snapshots (version-pinned)
│   ├── examples/                # CCGS workflow examples (session transcripts, skill flows)
│   ├── export/                  # CCGS-generated reports not specific to game project
│   └── reference/               # External docs imported into project for reference
│       └── prompt/              # Prompt files (image gen, AI tool prompts)
├── tests/                       # Test suites (unit, integration, performance, playtest)
├── tools/                       # Build and pipeline tools (ci, build, asset-pipeline)
├── prototypes/                  # Throwaway prototypes (isolated from src/)
└── production/                  # Production management (sprints, milestones, releases)
    ├── roadmap.yaml             # Scope authority — milestone-to-system assignments (written by /roadmap)
    ├── roadmap.md               # Human-readable narrative view of roadmap.yaml
    ├── backlog.yaml             # Canonical story registry — all epics/stories across all sprints
    ├── sprint-status.yaml       # Current sprint view (generated from backlog; regeneratable)
    ├── wishlist.yaml            # Uncommitted ideas holding area (written by /wishlist)
    ├── milestones/              # Milestone definitions and active.txt (current milestone name)
    ├── epics/                   # Epic files — one subdirectory per epic (EPIC.md + story files)
    ├── sprints/                 # Sprint plan files (sprint-NN.md)
    ├── retrospectives/          # Sprint retrospectives
    ├── qa/                      # QA plans, sign-offs, smoke checks, evidence docs
    ├── session-state/           # Ephemeral session state (active.md — gitignored)
    └── session-logs/            # Session audit trail (gitignored)
```
