# Google Play — Submission Checklist

Last verified: 2026-06-06

## Pre-Submission

- [ ] Build signed with release keystore (keep keystore backed up securely)
- [ ] Target SDK level meets current Google requirement
- [ ] 64-bit native libraries included
- [ ] Data Safety section completed accurately in Play Console
- [ ] Content rating (IARC) questionnaire completed
- [ ] Store listing assets complete (screenshots, feature graphic, icon)
- [ ] Short and full description written
- [ ] Pricing configured
- [ ] In-app products configured (if applicable)
- [ ] Tested on internal track first

## Asset Requirements

| Asset | Dimensions | Format |
|-------|-----------|--------|
| App icon | 512×512 px | PNG, 32-bit |
| Feature graphic | 1024×500 px | JPG or PNG |
| Phone screenshots (min 2) | 320–3840 px on longest side, 16:9 or 9:16 | JPG or PNG |
| 7" tablet (optional) | Same size rules | JPG or PNG |
| 10" tablet (optional) | Same size rules | JPG or PNG |

## Build Upload

```bash
# Via Gradle
./gradlew bundleRelease
# Then upload the .aab from app/build/outputs/bundle/release/
```

Upload via Play Console → Production → Create new release → Upload AAB

## Testing Tracks

Use in order before production:
1. **Internal testing** — up to 100 testers, instant review
2. **Closed testing (Alpha)** — larger group, opt-in
3. **Open testing (Beta)** — public opt-in
4. **Production** — full release (staged rollout recommended)

## Staged Rollout

Recommended for first release and major updates:
- Start at 10–20% rollout
- Monitor crash rate and ANR rate in Android Vitals
- Expand if metrics are stable
- Halt rollout immediately if crash rate spikes

## Post-Release

- Monitor Android Vitals in Play Console (crashes, ANRs)
- Respond to reviews in Play Console
- Watch for policy warning emails
