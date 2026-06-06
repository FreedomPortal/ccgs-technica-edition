# Platform Reference Documentation

Curated, date-stamped platform submission guides for the release-manager agent.
Mirrors the pattern of `docs/engine-reference/` — exists because **LLM training
data has a cutoff** and platform policies change frequently.

## Why This Exists

Platform cert requirements, store policies, and SDK versions shift constantly.
Console TRCs/TCRs/Lotcheck are NDA'd — the model has incomplete knowledge.
These files give the release-manager agent accurate, version-pinned facts
instead of relying on stale training data.

## Structure

```
platform/
├── steam/          — Steamworks, store page, build upload
├── playstation/    — PS4/PS5 TRC (STUB — fill from dev portal)
├── xbox/           — GDK/XDK TCR (STUB — fill from dev portal)
├── nintendo/       — Lotcheck (STUB — fill from dev portal)
├── ios/            — App Store Review Guidelines
├── google-play/    — Google Play Policy
├── epic/           — Epic Games Store requirements
└── itch/           — itch.io upload and publishing
```

## NDA Warning

Console certification docs (PlayStation TRC, Xbox TCR, Nintendo Lotcheck) are
covered by NDA. Stub files mark where to paste requirements from your dev portal
access. **Do not commit actual NDA content to a public repository.**

## Maintenance

- Update `Last verified` date whenever you check a platform's current policy
- Add a changelog note if a requirement changed significantly
- Console stubs: fill from partner portal after signing NDA/dev agreement
- Re-verify all files at the start of each release cycle

## Knowledge Gap

LLM cutoff: August 2025. Anything that changed after that date is unknown to
the model. Always cross-check official sources before cert submission.
