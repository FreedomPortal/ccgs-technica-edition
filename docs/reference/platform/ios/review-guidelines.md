# iOS — App Store Review Guidelines Summary

Last verified: 2026-06-06  
Source: https://developer.apple.com/app-store/review/guidelines/

> **Warning**: These guidelines update frequently. Verify current state before submission.

## Most Commonly Flagged Issues (Games)

### In-App Purchases
- All IAP must use Apple's payment system — no external payment links, no directing users to web purchases
- Loot boxes / randomized items: must disclose odds before purchase
- Subscriptions: must clearly describe what's included and renewal terms

### Privacy
- Privacy manifest (`PrivacyInfo.xcprivacy`) required for any SDK that accesses privacy-sensitive APIs
- Privacy nutrition labels in App Store Connect must accurately reflect data collection
- App Tracking Transparency (ATT): prompt required before any cross-app tracking
- No fingerprinting users via device signals as a tracking workaround

### Content
- Games with user-generated content need moderation and reporting mechanisms
- Violence, sexual content, gambling: age gate and content rating must match actual content
- Realistic violence against real people/animals: rejected

### Age Rating
- Set via App Store Connect questionnaire
- 17+ rating restricts discoverability — avoid over-rating
- Games with IARC rating elsewhere still need App Store Connect questionnaire

### Technical
- No crashes, no placeholder content in release build
- Must function on all declared supported devices
- Game Center: use properly or don't declare it
- Minimum iOS version: set as low as feasible for reach, test accordingly

## Review Rejection Recovery

1. Read the rejection reason carefully in App Store Connect
2. Address the specific issue — do not change unrelated things
3. Reply to the reviewer in App Store Connect with explanation if the rejection seems incorrect
4. Resubmit with a note explaining what changed
5. Escalate via Apple Developer Relations if stuck after 2+ rejections on same issue
