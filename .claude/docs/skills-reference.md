# Available Skills (Slash Commands)

112 slash commands organized by phase. Type `/` in Claude Code to access any of them.

## Onboarding & Navigation

| Command | Purpose |
|---------|---------|
| `/start` | First-time onboarding — asks where you are, then guides you to the right workflow |
| `/next` | Context-aware "what do I do next?" — reads current stage and surfaces the required next step |
| `/project-stage-detect` | Full project audit — detect phase, identify existence gaps, recommend next steps |
| `/setup-engine` | Configure engine + version, detect knowledge gaps, populate version-aware reference docs |
| `/adopt` | Brownfield format audit — checks internal structure of existing GDDs/ADRs/stories, produces migration plan |
| `/continue` | Read session state and agent memory; present a brief so you resume immediately where you left off |
| `/checkpoint` | Flush session discoveries to agent memory files — call before crashes, /clear, or long breaks |
| `/autosave-mode` | Configure crash-protection level for long tasks: off / remind / enforce |
| `/setup-tool` | Configure a standalone pipeline tool project outside the engine |
| `/log-lesson` | Encode a lesson from review, playtesting, or press feedback into writing-lessons.md |

## Game Design

| Command | Purpose |
|---------|---------|
| `/brainstorm` | Guided ideation using professional studio methods (MDA, SDT, Bartle, verb-first) |
| `/map-systems` | Decompose game concept into systems, map dependencies, prioritize design order |
| `/design-system` | Guided, section-by-section GDD authoring for a single game system |
| `/quick-design` | Lightweight design spec for small changes — tuning, tweaks, minor additions |
| `/review-all-gdds` | Cross-GDD consistency and game design holism review across all design docs |
| `/propagate-design-change` | When a GDD is revised, find affected ADRs and produce an impact report |

## Art & Assets

| Command | Purpose |
|---------|---------|
| `/art-bible` | Guided, section-by-section Art Bible authoring — creates visual identity spec before asset production begins |
| `/taste-gate` | Human taste approval checkpoint — extract style parameters, generate pilots, loop until approved, lock template |
| `/asset-spec` | Generate per-asset visual specifications and AI generation prompts from GDDs, level docs, or character profiles |
| `/asset-audit` | Audit assets for naming conventions, file size budgets, and pipeline compliance |

## UX & Interface Design

| Command | Purpose |
|---------|---------|
| `/ux-design` | Guided section-by-section UX spec authoring (screen/flow, HUD, or pattern library) |
| `/ux-review` | Validate UX specs for GDD alignment, accessibility, and pattern compliance |

## Architecture

| Command | Purpose |
|---------|---------|
| `/create-architecture` | Guided authoring of the master architecture document |
| `/architecture-decision` | Create an Architecture Decision Record (ADR) |
| `/architecture-review` | Validate all ADRs for completeness, dependency ordering, and GDD coverage |
| `/create-control-manifest` | Generate flat programmer rules sheet from accepted ADRs |

## Stories & Sprints

| Command | Purpose |
|---------|---------|
| `/create-epics` | Translate GDDs + ADRs into epics — one per architectural module |
| `/create-stories` | Break a single epic into implementable story files |
| `/dev-story` | Read a story and implement it — routes to the correct programmer agent |
| `/sprint-plan` | Generate or update a sprint plan; initializes sprint-status.yaml |
| `/sprint-status` | Fast 30-line sprint snapshot (reads sprint-status.yaml) |
| `/story-readiness` | Validate a story is implementation-ready before pickup (READY/NEEDS WORK/BLOCKED) |
| `/story-done` | 8-phase completion review after implementation; updates story file, surfaces next story |
| `/estimate` | Structured effort estimate with complexity, dependencies, and risk breakdown |

## Reviews & Analysis

| Command | Purpose |
|---------|---------|
| `/design-review` | Review a game design document for completeness and consistency |
| `/code-review` | Architectural code review for a file or changeset |
| `/balance-check` | Analyze game balance data, formulas, and config — flag outliers |
| `/content-audit` | Audit GDD-specified content counts against implemented content |
| `/scope-check` | Analyze feature or sprint scope against original plan, flag scope creep |
| `/perf-profile` | Structured performance profiling with bottleneck identification |
| `/tech-debt` | Scan, track, prioritize, and report on technical debt |
| `/gate-check` | Validate readiness to advance between development phases (PASS/CONCERNS/FAIL) |
| `/consistency-check` | Scan all GDDs against the entity registry to detect cross-document inconsistencies (stats, names, rules that contradict each other) |
| `/security-audit` | Audit the game for security vulnerabilities: save tampering, cheat vectors, network exploits, data exposure, and input validation gaps |

## QA & Testing

| Command | Purpose |
|---------|---------|
| `/qa-plan` | Generate a QA test plan for a sprint or feature |
| `/smoke-check` | Run critical path smoke test gate before QA hand-off |
| `/soak-test` | Generate a soak test protocol for extended play sessions |
| `/regression-suite` | Map test coverage to GDD critical paths, identify fixed bugs without regression tests |
| `/test-setup` | Scaffold the test framework and CI/CD pipeline for the project's engine |
| `/test-helpers` | Generate engine-specific test helper libraries for the test suite |
| `/test-evidence-review` | Quality review of test files and manual evidence documents |
| `/test-flakiness` | Detect non-deterministic (flaky) tests from CI run logs |
| `/skill-test` | Validate skill files for structural compliance and behavioral correctness |
| `/skill-improve` | Improve a skill using a test-fix-retest loop — diagnose, propose fix, rewrite, verify |

## Production

| Command | Purpose |
|---------|---------|
| `/milestone-review` | Review milestone progress and generate status report |
| `/retrospective` | Run a structured sprint or milestone retrospective |
| `/bug-report` | Create a structured bug report |
| `/bug-triage` | Read all open bugs, re-evaluate priority vs. severity, assign owner and label |
| `/reverse-document` | Generate design or architecture docs from existing implementation |
| `/playtest-report` | Generate a structured playtest report or analyze existing playtest notes |

## Release

| Command | Purpose |
|---------|---------|
| `/release-checklist` | Generate and validate a pre-release checklist for the current build |
| `/launch-checklist` | Complete launch readiness validation across all departments |
| `/changelog` | Auto-generate changelog from git commits and sprint data |
| `/patch-notes` | Generate player-facing patch notes from git history and internal data |
| `/hotfix` | Emergency fix workflow with audit trail, bypassing normal sprint process |
| `/day-one-patch` | Prepare a focused day-one patch for known issues discovered after gold master but before or at public launch |
| `/export-build` | Export release build via engine headless export — logs version, platform, timestamp to production/qa/builds.md |

## Creative & Content

| Command | Purpose |
|---------|---------|
| `/prototype` | Concept prototype — throwaway build in Stage 2 (Prototype) to validate core idea before Systems Design |
| `/vertical-slice` | Stage 6 (Vertical Slice) — production-quality end-to-end build to prove the game loop before Production |
| `/onboard` | Generate contextual onboarding document for a new contributor or agent |
| `/refine-copy` | Remove AI writing patterns from player-facing copy — called automatically by all export skills |
| `/localize` | **DEPRECATED** — use modular pipeline: `/localization-prepare`, `/localization-integrate`, `/localization-qa`, `/localization-sync`, `/localization-cultural-review`, `/localization-vo`, `/localization-rtl` |

## Team Orchestration

Coordinate multiple agents on a single feature area:

| Command | Coordinates |
|---------|-------------|
| `/team-combat` | game-designer + gameplay-programmer + ai-programmer + technical-artist + sound-designer + qa-tester |
| `/team-narrative` | narrative-director + writer + world-builder + level-designer |
| `/team-ui` | ux-designer + ui-programmer + art-director + accessibility-specialist |
| `/team-release` | release-manager + qa-lead + devops-engineer + producer |
| `/team-polish` | performance-analyst + technical-artist + sound-designer + qa-tester |
| `/team-audio` | audio-director + sound-designer + technical-artist + gameplay-programmer |
| `/team-level` | level-designer + narrative-director + world-builder + art-director + systems-designer + qa-tester |
| `/team-live-ops` | live-ops-designer + economy-designer + community-manager + analytics-engineer |
| `/team-qa` | qa-lead + qa-tester + gameplay-programmer + producer |
| `/team-publish` | publishing-manager + community-manager + writer |

## Marketing & Growth — CCGS:TE

| Command | Purpose |
|---------|---------|
| `/marketing-plan` | Full publishing roadmap — community strategy, pre-launch milestones, content cadence |
| `/community-plan` | Platform setup, content calendar, metric tracking (wishlists, followers, engagement) |
| `/analytics-setup` | Design player event tracking — what to instrument, platform choice, engine implementation |
| `/press-outreach` | Build media contact list, draft outreach templates, track status in press-contacts.md |

## Publishing & Distribution — CCGS:TE

| Command | Purpose |
|---------|---------|
| `/publish-check` | Audit publishing roadmap vs. dev stage — surfaces overdue tasks and unlocked actions (also runs at session start) |
| `/export-steam-page` | Compile store page copy from GDDs and writing-lessons.md |
| `/export-devlog` | Draft devlog post from session state, sprint history, and GDDs; enforces writing-lessons rules |
| `/export-social` | Batch social content for scheduled platforms |
| `/export-pitch` | Investor/publisher pitch deck content |
| `/export-review` | Structured press/review copy |
| `/export-crowdfunding` | Crowdfunding campaign content |

## Post-Launch Lifecycle — CCGS:TE

| Command | Purpose |
|---------|---------|
| `/live-ops-plan` | Strategic post-launch plan — content cadence, seasonal events calendar, retention mechanics |
| `/monetization-design` | Revenue model design with ethical guardrails — flags pay-to-win and dark patterns |
| `/dlc-design` | DLC content package design — scope, pricing, content list, timeline |
| `/mod-support` | Mod support architecture — what to expose, tooling for modders, community integration |
| `/post-mortem` | Structured retrospective after milestone or release |

## Demo Workflow — CCGS:TE

| Command | Purpose |
|---------|---------|
| `/demo-plan` | Goals, milestones, effort estimate, risk register for the demo production effort |
| `/demo-scope` | Define demo boundaries — included content, what is cut, target impression |
| `/demo-build` | Export and validate a playable demo build |
| `/demo-playtest` | Structured playtest protocol for demo-specific goals (first impressions, conversion) |
| `/demo-feedback` | Aggregate 2+ playtest sessions into patterns and a go/no-go release verdict |
| `/demo-iterate` | Targeted blocker resolution: scope → delegate to dev-story/bug-report → verify |
| `/demo-polish` | Demo-specific polish scoped to first-impression, onboarding, and end-state CTA |
| `/demo-status` | Read-only snapshot of all active demo campaigns — confidence, artifact status, blockers |
| `/demo-gate` | Formal demo sub-stage gate — evaluates checklist, writes `state.txt` on PASS |
| `/demo-integrate` | Post-demo back-integration — classify changes as keep-demo-only/backport/needs-story; EA mode flags roadmap commitments |

## Localization Suite — CCGS:TE

| Command | Purpose |
|---------|---------|
| `/localization-prepare` | Scan for unwrapped strings, wrap in tr(), scaffold string table |
| `/localization-integrate` | Mid-pipeline — import translations, resolve merge conflicts |
| `/localization-sync` | Detect stale translations when source text changes |
| `/localization-qa` | Dedicated LQA pass — overflow, tone, placeholder, cultural checks |
| `/localization-cultural-review` | Standalone cultural sensitivity review per locale |
| `/localization-rtl` | RTL layout validation for Arabic/Hebrew locales |
| `/localization-vo` | Voice-over pipeline — script export, casting brief, sync validation |

## Framework Maintenance — CCGS:TE

Skills for maintainers of the CCGS:TE framework itself. Not for game project work.

| Command | Purpose |
|---------|---------|
| `/framework-release` | Cut a framework version: detect changes since last release, auto-detect breaking changes, propose semver bump, draft release notes, write changelog on approval |
