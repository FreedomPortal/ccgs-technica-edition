# Indie Playtest Standards

Empirical checklist derived from common failures across hundreds of indie game
playtests. These are **post-implementation, pre-ship** checks — not design-doc
concerns. Reference this document during `/playtest-report analyze`, `/qa-plan`,
and `/gate-check` to catch the mistakes that appear most often in playtests.

`/ux-review` covers design-document quality. This document covers **built-game
quality** — things you can only verify once the game is running.

---

## 1. Tutorial & Onboarding

- Every core mechanic has a guided, interactive introduction — players physically
  perform the action in a safe context before encountering it in real gameplay.
  Text screens and static images do not count as teaching.
- Mechanics are introduced one at a time. No segment introduces more than 2 new
  systems simultaneously before the player has demonstrated competence in the prior
  ones.
- Audit for **orphan mechanics**: list every mechanic, control, and system. Verify
  each is explicitly taught before the player first needs it. Secondary controls
  (dodge, sprint, heavy attack, dash) and progression systems (skill trees,
  crafting, shops) are the most commonly missed.
- Tutorial information is re-accessible at any time via a controls/mechanics
  reference in the pause menu or journal. A player who clicks past a prompt or
  forgets a mechanic must have a recovery path.
- Tutorial prompts stay on screen long enough and **advance on player input, not
  a timer**. Auto-progressing prompts that disappear while the player is still
  reading are a common cause of first-hour dropout.
- Test the first 5 minutes with someone who has never seen the game. Watch silently.
  Every moment of "what do I do?" or accidental mechanic discovery is an onboarding
  gap. This test cannot be replaced by internal review.

---

## 2. Audio Volume

- Default master volume is 50% or lower at first launch. Players can always turn
  up — an eardrum-blasting first impression causes immediate frustration and
  destroys content creator recordings.
- All volume sliders (master, music, SFX) actually work against all audio sources.
  Verify each slider against each source: some audio (cutscenes, specific SFX)
  commonly ignores the slider entirely.
- Audio settings are accessible from the **main menu or title screen** — not buried
  behind starting a new game. Players must calibrate volume before gameplay audio
  hits.
- Volume levels are normalized across all game states: menus vs. gameplay,
  cutscenes vs. exploration, UI alerts vs. ambient. A single ear-piercing alert
  undermines an otherwise good mix.
- Volume settings persist across sessions and state changes. Verify they survive:
  restart, pause/resume, and scene transitions.
- Background music loops seamlessly and all core interactions have sound effects
  (attacks, footsteps, deaths, scoring). Missing audio for fundamental actions
  signals incompleteness to players.

---

## 3. Feedback Systems

Every player action must communicate its result — never let an outcome happen
silently.

- Every attack or damaging action produces **at least two feedback channels**
  (e.g., hit sound + visual flash + damage number). Players who miss one channel
  must still be able to confirm contact.
- When the player takes damage: communicate immediately via screen shake, hurt
  sound, health bar flash, or vignette. Health must never decrease silently.
- Failed or blocked actions (can't afford, wrong item, on cooldown, out of range)
  produce distinct negative feedback (error sound, UI shake, tooltip). Doing
  nothing silently is not acceptable.
- Any state change the player causes (collecting items, leveling up, activating
  buffs, completing objectives) has an explicit confirmation moment — popup, sound,
  particle effect, or log entry.
- Ongoing states (buff durations, cooldown timers, charge progress, ability
  readiness) have persistent visible indicators (bars, icons, glows). Players
  must not have to guess or spam inputs to check state.
- After any resolved game event with multiple variables (combat round, card
  effects, crafting outcome), show a brief breakdown or history entry so players
  understand **why** the result happened, not just **that** it happened.

---

## 4. Controls & Input Ergonomics

- Genre-standard defaults are used: WASD for movement, left-click for primary
  action, E/F for interact, Tab for inventory, Space or Shift for dodge/roll.
  Players expect to play competently within seconds without reading a controls
  screen.
- Input is consistent across all game states. If left-click selects in menus, it
  is also the primary action in gameplay. If scroll wheel zooms the camera, it
  does not silently switch to rotating objects based on selection state.
- All frequently-used action keys are reachable from the movement hand. If WASD
  is movement, core actions must be within reach: Q, E, R, F, C, Space, Shift,
  Tab, 1–5. Never assign core actions to J, U, I, O or require simultaneous
  arrow keys and WASD.
- Every documented binding actually works. Before shipping, press every key shown
  in the controls screen and verify it does what it says. Broken bindings that
  appear in the settings UI are a common late-stage finding.
- All menus and UI support both mouse and keyboard. If the game supports
  controllers, every action — including restart-from-checkpoint and menu back —
  has a controller binding.
- Non-QWERTY layouts (AZERTY, etc.) are supported either by layout detection with
  remapped defaults, or a complete key rebinding screen.

---

## 5. Settings Menu Completeness

- **Separate volume sliders** for master, music, and sound effects. A single
  toggle or combined slider is the most-cited audio complaint across playtests.
- Settings menu is accessible from **both the main menu and the pause menu
  during gameplay**. Never force players to quit or restart to adjust options.
- A controls reference or rebinding screen exists in settings so players can
  discover keybindings without trial and error.
- Every slider, toggle, and dropdown in the settings menu is functional.
  Non-responsive sliders, toggles with no effect, and placeholder controls signal
  to players that the game is not finished.

---

## 6. Difficulty Curve

- **First boss spike**: the first boss should be no more than one incremental step
  harder than the hardest regular encounter before it. Test the first boss in
  isolation with a fresh player — across many playtests, the first boss is the
  single most common difficulty spike.
- **Graph the actual difficulty curve** — map enemy HP, damage output, and
  mechanical complexity level-by-level and verify it ascends smoothly. Flat-then-
  vertical curves and random difficulty ordering only become obvious when charted.
- **Stress-test new mechanic introductions separately**: when a new enemy type,
  puzzle constraint, or mechanic is added, give the player at least one low-
  pressure encounter before combining it with existing pressure.
- **Audit builds and items for curve-breaking potential**: one overpowered weapon,
  healing upgrade, or summon build can trivialize entire games. Test each upgrade
  path for upper and lower extremes.
- **Enemy fairness**: enemies that are faster than the player, stunlock without
  counterplay, or attack without telegraphing generate the most "unfair" moments.
  Every enemy action must have a learnable, executable counter.
- At least two difficulty settings or adaptive scaling. A single forced tuning
  fails players who are newer or more experienced than the assumed baseline.

---

## 7. Visual Polish & Bug Categories

These are not style issues — they are functional correctness issues that playtests
surface as "broken."

- **Clipping**: test every wearable, held item, and cape/accessory against all
  animations (idle, run, crouch, climb). Attachment points and collision volumes
  must prevent parts from passing through the character body or each other.
- **Level boundaries and camera limits**: walk every edge of every level at all
  zoom levels and angles to ensure players cannot see void, skybox, or unrendered
  space through walls, floors, doors, or transparent objects.
- **Animation state transitions**: verify animations stop when they should (rope
  climbing when stationary, petting while moving), play at correct speed (no fast-
  forwarded death animations), and blend smoothly without snapping or T-posing.
- **UI under display changes**: resize the window, switch fullscreen/windowed, and
  change resolution mid-gameplay to catch HUD misalignment, element overflow, and
  layout breaks that only appear after display changes.
- **Z-fighting and draw order**: identify all areas where geometry shares the same
  plane (overlapping floors, stacked walls, co-planar decals) and add depth offsets
  or correct render queue ordering.
- **Particle and VFX layer order**: smoke, rain, sparkles, and other particle
  systems must render behind UI text and menus, not re-trigger on unrelated state
  changes, and clip correctly at screen edges rather than cutting off abruptly.

---

## Skill Integration

| When to reference this document | How |
|---|---|
| Analyzing raw playtest notes | `/playtest-report analyze` — route findings against these categories |
| Writing a QA plan for a sprint | `/qa-plan` — include relevant sections as manual test criteria |
| Pre-milestone gate check | `/gate-check` — flag any unchecked category as advisory risk |
| Tutorial implementation review | Cross-check Section 1 before `/story-done` on any tutorial story |
| Audio implementation review | Cross-check Section 2 before closing any audio story |
| Pre-ship final review | `/launch-checklist` — Sections 2–7 map to the QA and content readiness blocks |
