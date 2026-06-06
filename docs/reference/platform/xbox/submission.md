# Xbox — Submission Checklist

Last verified: 2026-06-06

## Pre-Submission

- [ ] TCR pass confirmed for all target SKUs
- [ ] Build tested on target retail hardware
- [ ] Achievements configured and verified in Partner Center
- [ ] Age rating obtained (ESRB for NA, PEGI for EU, others as applicable)
- [ ] Store page assets uploaded to Partner Center
- [ ] Pricing configured in all target regions
- [ ] Build package uploaded via Partner Center
- [ ] Submission questionnaire complete

## Build Requirements

- Final package built with release configuration (no debug)
- Package passes certification tools (Xbox Certification Kit / XCK)
- No test content, dev shortcuts, or debug overlays in release build

## Submission Process

1. Run Xbox Certification Kit (XCK) locally — catch common failures early
2. Upload final package to Partner Center
3. Complete submission form
4. Submit for TCR review
5. Monitor certification feedback in Partner Center
6. Address failures and resubmit
7. On approval: set release date, confirm pricing, publish

## Common TCR Failure Areas

- Quick Resume not handled correctly (state corruption on resume)
- Missing or incorrect achievement unlock conditions
- Save data not meeting cloud save requirements
- Suspend/resume cycle crashes
- Network error handling not meeting spec
- Missing accessibility features per current TCR

## Post-Approval

- Download and test from Microsoft Store on retail hardware
- Verify achievements unlock correctly on a standard account
- Confirm pricing in Microsoft Store storefront
