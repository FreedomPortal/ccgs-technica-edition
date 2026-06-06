# iOS — Submission Checklist

Last verified: 2026-06-06

## Pre-Submission

- [ ] Build signed with distribution certificate and provisioning profile
- [ ] Privacy manifest (`PrivacyInfo.xcprivacy`) complete and accurate
- [ ] Privacy nutrition labels filled in App Store Connect
- [ ] Age rating questionnaire completed
- [ ] App Store screenshots prepared (all required sizes)
- [ ] App preview video (optional but recommended)
- [ ] Short and full description written
- [ ] Keywords set (100 char limit)
- [ ] Pricing configured
- [ ] In-app purchase items configured (if applicable)
- [ ] TestFlight beta test completed

## Screenshot Requirements

| Device | Size |
|--------|------|
| iPhone 6.9" (required) | 1320×2868 or 1290×2796 |
| iPhone 6.5" (required) | 1242×2688 |
| iPad 13" (if iPad supported) | 2064×2752 |
| iPad 12.9" (if iPad supported) | 2048×2732 |

All screenshots: PNG or JPEG, no alpha channel on JPG.

## Build Upload

```bash
# Via Xcode: Product → Archive → Distribute App → App Store Connect
# Or via Transporter app / altool CLI
xcrun altool --upload-app -f MyGame.ipa -t ios -u <apple-id> -p <app-specific-password>
```

## Submission Process

1. Upload build via Xcode or Transporter
2. In App Store Connect: select build for submission
3. Complete all metadata (description, screenshots, age rating, privacy labels)
4. Submit for Review
5. Monitor status in App Store Connect (1–3 business days)
6. Address any rejection, resubmit
7. On approval: release manually or set auto-release date

## Post-Release

- Monitor crash reports in Xcode Organizer and App Store Connect Analytics
- Respond to reviews in App Store Connect
- Check TestFlight for any beta feedback on the live build
