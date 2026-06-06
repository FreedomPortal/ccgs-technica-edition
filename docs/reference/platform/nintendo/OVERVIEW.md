# Nintendo — Platform Overview

| Field | Value |
|-------|-------|
| **Platforms** | Nintendo Switch, Nintendo Switch 2 |
| **Cert Process** | Lotcheck |
| **Last Verified** | 2026-06-06 |
| **LLM Knowledge Cutoff** | August 2025 |
| **Dev Portal** | https://developer.nintendo.com/ |

## NDA Warning

Nintendo Lotcheck requirements are covered by NDA. The `lotcheck.md` file in
this directory is a stub. Fill it from the Nintendo Developer portal after
signing the developer agreement. **Do not commit actual Lotcheck content to
a public repository.**

## Dev Access Requirements

- Nintendo Developer account (apply via developer.nintendo.com)
- Switch devkit hardware
- Nintendo SDK (NintendoSDK — version-pinned per project)
- Submission via Nintendo Developer portal

## Key Submission Milestones

| Milestone | Typical Lead Time |
|-----------|------------------|
| First Lotcheck | 10–15 business days |
| Resubmission | 5–10 business days |

## Platform-Specific Notes

- Switch has strict performance requirements — docked vs handheld modes both tested
- Joy-Con controller support requirements are specific and tested in Lotcheck
- Nintendo does not use IARC — requires separate age rating submission per region
  (ESRB for NA, PEGI for EU, CERO for Japan, USK for Germany, etc.)
- eShop assets have specific requirements distinct from other storefronts
- Physical releases have additional Lotcheck requirements (ROM, packaging)

## Official Sources

- Developer portal: https://developer.nintendo.com/
- SDK and Lotcheck docs: via developer portal (NDA-gated)
