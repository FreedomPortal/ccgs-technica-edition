# PlayStation — Submission Checklist

Last verified: 2026-06-06

## Pre-Submission

- [ ] TRC pass confirmed for all target SKUs (PS4 / PS5)
- [ ] Build tested on retail-equivalent devkit hardware
- [ ] Trophy set complete and verified
- [ ] Age rating obtained (ESRB, PEGI, or region-appropriate body)
- [ ] Store page assets submitted to partner portal
- [ ] Pricing set in all target regions
- [ ] Build uploaded via partner submission system
- [ ] Submission form completed (content descriptors, feature declarations)

## Build Requirements

- Final build must be built with release SDK (not debug)
- Build size must fit within declared storage requirement
- No debug symbols, dev console output, or test content in release build

## Submission Process

1. Upload build via PlayStation partner submission portal
2. Complete submission questionnaire (features used, content flags)
3. Submit for TRC review
4. Monitor feedback in partner portal
5. Address any TRC failures and resubmit
6. On approval: set release date, confirm pricing, publish

## Common TRC Failure Areas

These are commonly flagged — verify before first submission:
- Missing or malformed save data handling
- Trophy unlock conditions not met in all code paths
- Crash on suspend/resume cycle
- Missing accessibility features required by current TRC version
- Network error handling not meeting spec

## Post-Approval

- Download and test the approved build from PSN (not local)
- Verify trophy unlocks on a standard user account (not devkit account)
- Confirm pricing displays correctly in PlayStation Store
