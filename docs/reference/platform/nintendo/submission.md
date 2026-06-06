# Nintendo — Submission Checklist

Last verified: 2026-06-06

## Pre-Submission

- [ ] Lotcheck pass confirmed
- [ ] Build tested on retail Switch hardware (not just devkit)
- [ ] Both docked and handheld modes tested
- [ ] Age ratings obtained for all target regions (no IARC — must apply separately)
- [ ] eShop assets submitted (see asset specs in developer portal)
- [ ] Pricing configured per region
- [ ] Build uploaded via Nintendo developer portal

## Build Requirements

- Final build compiled with release SDK configuration
- No debug content, dev menus, or test shortcuts
- Memory usage validated (Switch has strict RAM limits)
- ROM size within declared limits
- No references to competitor platforms in any UI text or metadata

## Submission Process

1. Upload build via Nintendo developer portal
2. Submit Lotcheck materials (build + metadata + age ratings)
3. Wait for Lotcheck feedback (~10–15 business days first submission)
4. Address any failures, resubmit
5. On approval: set release date in eShop, confirm pricing
6. Nintendo publishes at scheduled time

## Common Lotcheck Failure Areas

- Missing or incorrect behavior in sleep/wake cycle
- Joy-Con gyro/rumble not handled correctly when controllers disconnect
- UI not scaling correctly between docked (1080p) and handheld (720p)
- Missing regional age ratings
- Incorrect handling of NSO (Nintendo Switch Online) requirements if network features present
- Save data corruption on abrupt power loss not handled gracefully

## Post-Approval

- Download and test from eShop on retail hardware
- Test both docked and handheld modes from the downloaded build
- Verify save data on a standard user account
