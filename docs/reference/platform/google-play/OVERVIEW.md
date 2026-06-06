# Google Play — Platform Overview

| Field | Value |
|-------|-------|
| **Platform** | Android (Google Play Store) |
| **Cert Process** | Google Play Policy review (automated + manual) |
| **Last Verified** | 2026-06-06 |
| **LLM Knowledge Cutoff** | August 2025 |
| **Dev Portal** | https://play.google.com/console/ |
| **Policy Center** | https://support.google.com/googleplay/android-developer/answer/9899234 |

## Knowledge Gap Warning

Google Play policies update regularly, especially around data safety, permissions,
and target API level requirements. API level requirements increase annually —
verify the current minimum target SDK before starting a release cycle.

## Dev Access Requirements

- Google Play Developer account ($25 USD one-time fee as of last verification)
- Android SDK / build toolchain
- Signing keystore (keep safe — losing it blocks future updates to your app)
- Submission via Google Play Console

## Key Submission Milestones

| Milestone | Typical Lead Time |
|-----------|------------------|
| New app review | 3–7 business days |
| Update review | 1–3 business days |
| Policy violation review | Varies widely |

## Platform-Specific Notes

- Target API level: Google raises the required minimum annually (usually August)
  Verify current requirement at: https://developer.android.com/google/play/requirements/target-sdk
- Data Safety section: mandatory, must accurately reflect data practices
- Permissions: declare only what you use; over-requesting permissions triggers review
- 64-bit requirement: all apps must include 64-bit native libs
- Android App Bundle (AAB) is now required (not APK) for new apps
- Internal/Closed/Open testing tracks available before production release

## Official Sources

- Play Console: https://play.google.com/console/
- Policy Center: https://support.google.com/googleplay/android-developer/
- Target API level requirements: https://developer.android.com/google/play/requirements/target-sdk
- Data Safety: https://support.google.com/googleplay/android-developer/answer/10787469
