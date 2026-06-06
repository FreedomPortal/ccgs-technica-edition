# PlayStation — Platform Overview

| Field | Value |
|-------|-------|
| **Platforms** | PS4, PS5 |
| **Cert Process** | TRC (Technical Requirements Checklist) |
| **Last Verified** | 2026-06-06 |
| **LLM Knowledge Cutoff** | August 2025 |
| **Dev Portal** | https://partners.playstation.net/ |

## NDA Warning

PlayStation TRC requirements are covered by NDA. The `trc.md` file in this
directory is a stub. Fill it from the PlayStation Partner portal after
signing the developer agreement. **Do not commit actual TRC content to a
public repository.**

## Dev Access Requirements

- PlayStation Partner account (apply via partners.playstation.net)
- PS4/PS5 devkit hardware
- SDK: PlayStation SDK (version pinned per project — see partner portal)
- Submission via PlayStation Partner submission system

## Key Submission Milestones

| Milestone | Typical Lead Time |
|-----------|------------------|
| First submission | 5–10 business days |
| Resubmission (minor issues) | 3–5 business days |
| Resubmission (major issues) | 5–10 business days |
| Emergency/expedited review | Contact partner rep |

## Platform-Specific Notes

- PS5 has separate TRC from PS4 — if targeting both, both must pass
- Trophies are mandatory on PS4/PS5 (minimum 1 Platinum or no Platinum with set structure)
- Save data cross-play between PS4/PS5 versions requires explicit TRC compliance
- DualSense haptics/adaptive triggers: not required, but TRC has specific rules if implemented

## Official Sources

- Partner portal: https://partners.playstation.net/
- SDK downloads: via partner portal (NDA-gated)
- TRC documents: via partner portal (NDA-gated)
