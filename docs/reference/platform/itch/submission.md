# itch.io — Submission Checklist

Last verified: 2026-06-06

## Pre-Submission

- [ ] itch.io account created
- [ ] Project page created (title, description, cover image)
- [ ] Pricing and revenue split configured
- [ ] Content rating set (SFW / Mature)
- [ ] Platform tags set (Windows / Mac / Linux / Web / Android)
- [ ] Genre and tags added
- [ ] Screenshots uploaded (min 3 recommended)
- [ ] Build(s) uploaded and marked as playable
- [ ] Game page visibility set (draft / restricted / public)

## Asset Recommendations

| Asset | Recommended Size | Format |
|-------|-----------------|--------|
| Cover image | 315×250 px (minimum) | JPG/PNG/GIF |
| Screenshots | 1280×720 or 1920×1080 | JPG/PNG |
| Banner | 960×540 px | JPG/PNG |

## Build Upload Methods

### Web Dashboard
1. Go to itch.io/dashboard → Create New Project
2. Fill in project details
3. Upload files under "Uploads" section
4. Set platform tags per upload
5. Save & publish

### butler CLI (Recommended for iterative releases)

```bash
# Install butler: https://itch.io/docs/butler/installing.html
butler login

# Push a build
butler push ./build/windows user/game-name:windows

# Push for multiple platforms
butler push ./build/mac     user/game-name:mac
butler push ./build/linux   user/game-name:linux
```

butler handles delta uploads — only changed files are re-uploaded.

## Pricing Options

| Model | When to use |
|-------|------------|
| Free | Demos, jam entries, free games |
| Pay What You Want (PWYW) | Support-optional, community-first |
| Paid (fixed price) | Commercial release |
| Free with paid DLC | Base game free, premium content paid |

## Post-Release

- Post a devlog to notify followers
- Share itch.io page URL (itch URLs are clean and shareable)
- Monitor comments and respond to feedback
- Use itch.io Analytics for download/view metrics
- For bundles: itch.io Bundle system lets you join community bundles
