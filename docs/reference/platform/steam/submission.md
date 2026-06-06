# Steam — Submission Checklist

Last verified: 2026-06-06

## Pre-Submission

- [ ] App ID created in Steamworks partner portal
- [ ] SteamPipe depots configured (one per platform/architecture)
- [ ] Build uploaded and set on the `default` branch
- [ ] Store page assets complete (see `requirements.md`)
- [ ] IARC age rating questionnaire completed
- [ ] Pricing set for all target regions
- [ ] System requirements filled in
- [ ] Release date set or "Coming Soon" page live

## Build Upload (SteamPipe)

```bash
# Upload via steamcmd
steamcmd +login <username> +run_app_build <app_build.vdf> +quit
```

Key VDF fields:
- `appid` — your Steam App ID
- `desc` — build description (internal, shown in partner portal)
- `buildoutput` — local path for build logs
- `depots` — one entry per depot with `FileMapping` rules

## Branch Management

| Branch | Purpose |
|--------|---------|
| `default` | Public release build |
| `beta` | Opt-in public beta |
| `internal` | Internal QA (password-protected) |

Always test from the `internal` branch before promoting to `default`.

## Release Steps

1. Upload final build to `internal` branch
2. QA downloads and tests from Steam (not local)
3. Set build on `default` branch
4. Set release date/time in partner portal
5. Confirm pricing is correct in all regions
6. Click "Release App" — cannot be undone

## Post-Release

- Monitor Reviews tab (first 72h)
- Check crash reports via Steamworks Analytics
- Verify achievements and cloud save are functioning
- Respond to review bombing policy if applicable
