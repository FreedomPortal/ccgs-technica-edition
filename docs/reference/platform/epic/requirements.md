# Epic Games Store — Requirements

Last verified: 2026-06-06  
Source: https://dev.epicgames.com/docs/epic-games-store/requirements-guidelines

> **Warning**: EGS requirements evolve. Verify at dev portal before submission.

## Mandatory Technical Requirements

### EOS SDK Integration (Required)
- Auth Interface: Epic account login
- Achievements: configure and implement (minimum set required)
- EOS SDK version: use current stable — check https://dev.epicgames.com/docs/epic-online-services

### Minimum Feature Set
- [ ] Epic account authentication via EOS Auth
- [ ] Achievements implemented (all configured achievements must be obtainable)
- [ ] Controller support declared accurately

### Build Requirements
- Windows: 64-bit build required
- No always-online requirement for single-player games
- No third-party launchers that require separate account creation (beyond Epic account)
- Must launch from Epic Games Launcher without errors

## Store Page Requirements

| Asset | Dimensions | Format |
|-------|-----------|--------|
| Landscape key art | 2560×1440 px | JPG/PNG |
| Portrait key art | 1200×1600 px | JPG/PNG |
| Thumbnail | 284×380 px | JPG/PNG |
| Screenshots (min 5) | 1920×1080 recommended | JPG/PNG |

- At least one trailer required
- Short description: ~140 chars
- Long description: no hard limit
- System requirements: minimum and recommended

## Age Rating

- IARC questionnaire via dev portal — free, automated
- Required before store page goes live

## Content Policy

- Content must comply with EGS content guidelines
- Explicit adult content: requires separate approval, may not be permitted
- Accurate content descriptors required

## Optional but Recommended

- Cloud saves via EOS
- Cross-play with other platforms via EOS
- Epic First Run enrollment (exclusivity for better revenue share)
