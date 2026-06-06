# iOS / App Store — Platform Overview

| Field | Value |
|-------|-------|
| **Platform** | iOS, iPadOS (Apple App Store) |
| **Cert Process** | App Store Review (Apple Review Guidelines) |
| **Last Verified** | 2026-06-06 |
| **LLM Knowledge Cutoff** | August 2025 |
| **Dev Portal** | https://developer.apple.com/ |
| **Review Guidelines** | https://developer.apple.com/app-store/review/guidelines/ |

## Knowledge Gap Warning

Apple App Store Review Guidelines update frequently, often without major announcements.
Always check the current guidelines before submission. Policy on in-app purchases,
privacy, and age ratings changes most often.

## Dev Access Requirements

- Apple Developer Program ($99 USD/year as of last verification)
- Xcode (current version — macOS required for builds)
- Provisioning profiles and signing certificates via Xcode / developer portal
- Submission via App Store Connect

## Key Submission Milestones

| Milestone | Typical Lead Time |
|-----------|------------------|
| App Review (first submission) | 1–3 business days |
| Resubmission | 1–2 business days |
| Expedited review | Request via App Store Connect (not guaranteed) |

## Platform-Specific Notes

- Apple Silicon and older device support: set minimum iOS version carefully
- In-app purchases must use Apple IAP system (no third-party payment, no links to external purchase)
- Privacy manifest and privacy nutrition labels required since iOS 17 SDK
- App Tracking Transparency (ATT) prompt required if using any tracking
- TestFlight available for beta distribution (up to 10,000 testers)
- iPad-specific layout testing required if supporting iPadOS

## Official Sources

- Developer portal: https://developer.apple.com/
- App Store Connect: https://appstoreconnect.apple.com/
- Review Guidelines: https://developer.apple.com/app-store/review/guidelines/
- Privacy requirements: https://developer.apple.com/documentation/bundleresources/privacy_manifest_files
