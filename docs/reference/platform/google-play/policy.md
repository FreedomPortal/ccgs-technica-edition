# Google Play — Policy Summary

Last verified: 2026-06-06  
Source: https://support.google.com/googleplay/android-developer/answer/9899234

> **Warning**: Google Play policies update regularly. Verify before each release cycle.

## Most Commonly Flagged Issues (Games)

### Permissions
- Declare only permissions actually used
- Dangerous permissions (camera, location, contacts) require in-app rationale shown to user
- No requesting permissions in background without user-visible reason

### Data Safety
- Data Safety section in Play Console must accurately describe all data collected
- Applies to third-party SDKs too — you are responsible for what SDKs collect
- Categories: Location, Personal info, Financial info, Health, Messages, Photos/Files, etc.

### In-App Purchases
- Loot boxes / randomized purchases: must disclose odds in-game and on store page
- Real-money gambling apps have additional requirements and regional restrictions
- Subscriptions: must clearly describe benefits, pricing, and cancellation policy

### Content Rating
- IARC questionnaire via Play Console — free, automated
- Rating applies globally (some regions use IARC mappings to local systems)
- Accurately reflect violence, sexual content, language, controlled substances

### Target API Level
- Must meet Google's current minimum target SDK (raises annually, usually August)
- Check: https://developer.android.com/google/play/requirements/target-sdk
- Non-compliant apps are removed from new device discovery

### Technical
- 64-bit native libraries required
- AAB format required (not APK) for new apps
- No deceptive behavior, hidden functionality, or dynamic code loading from untrusted sources

## Policy Violation Recovery

1. Read the policy violation email carefully
2. Fix the specific issue
3. If unclear: submit a policy inquiry via Play Console
4. Resubmit the update
5. Repeated violations can result in account termination — do not ignore warnings
