# Epic Games Store — Submission Checklist

Last verified: 2026-06-06

## Pre-Submission

- [ ] EGS application approved (one-time — Epic must accept your title)
- [ ] EOS SDK integrated (Auth + Achievements minimum)
- [ ] All achievements obtainable and verified
- [ ] IARC age rating questionnaire completed
- [ ] Store page assets complete (key art, screenshots, trailer)
- [ ] Short and long descriptions written
- [ ] System requirements filled in
- [ ] Pricing configured
- [ ] Build uploaded to dev portal
- [ ] Build tested launching via Epic Games Launcher (not just executable)

## Build Upload

1. In Epic dev portal: navigate to your product → Artifacts
2. Create a new artifact for the release build
3. Upload via BuildPatch Tool (BPT) — Epic's build distribution tool
4. Assign artifact to the appropriate branch

## Submission Process

1. Complete store page in dev portal (all required fields)
2. Submit store page for review
3. Upload final build, assign to artifact
4. Submit build for review
5. Monitor review status (1–2 weeks)
6. Address any feedback from Epic review team
7. On approval: set release date, confirm pricing
8. Epic publishes at scheduled time

## Common Rejection Reasons

- EOS SDK not integrated or Auth not working
- Achievements configured in portal but not implementing in-game
- Store page assets not meeting size specs
- Game crashes on launch from Epic Launcher (test this specifically)
- Third-party account required to play

## Post-Release

- Monitor EGS reviews (via dev portal)
- Check EOS backend metrics in dev portal
- Monitor crash reports from any crash reporting SDK
