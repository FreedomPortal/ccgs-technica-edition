# Player Retention Benchmarks — Genre Reference

**Last updated:** 2026-06-10
**Data coverage:** 2024–2025 (most recent published reports)
**Compiled from:** 6 primary sources (see Source Inventory)
**Maintained by:** `growth-analyst` via `/retention-analysis` → Option B (WebSearch refresh)

---

## Critical Context — Read Before Using Numbers

These benchmarks diverge between sources because each source measures a **different population**:

| Source | Population measured | Bias direction |
|--------|--------------------|-|
| **GameAnalytics** | All SDK-integrated games (11,600+ apps), organic + paid | Most inclusive — includes hobbyist/long-tail games. **Most realistic baseline for an indie game.** |
| **Adjust / AppsFlyer** | UA-campaign–managed installs | Skews toward professionally published titles with active ad spend. Higher D1, lower D30. |
| **Mistplay** | Reward-motivated players on Mistplay network | Loyalty-biased; overstates typical retention. Their benchmarks are aspirational targets, not medians. |
| **Sensor Tower / Stepico** | Top-25 revenue-chart titles (US market) | Elite tier only. Describes best-in-class, not average. |
| **Admiral Media** | UA-managed campaign cohorts | Similar to Adjust; selection effect toward performing titles. |

**Rule of thumb:**
- Use **GameAnalytics median** as your honest baseline (where most games sit)
- Use **GameAnalytics top-25%** as a healthy performance target
- Use **Sensor Tower / Mistplay** figures as aspirational stretch targets
- Treat all numbers as ±5pp — methodology variance is real

---

## Mobile Retention Benchmarks (2024–2025)

### All-Genre Percentile Bands
Source: GameAnalytics 2025 report (2024 data, 11,600+ apps)

| Percentile | D1 | D7 | D30 |
|-----------|----|----|-----|
| Top 1% | 64–68% | 25–28% | — |
| Top 10% | ~40% | 11–12% | ~2.5% |
| **Top 25% (healthy target)** | **26–28%** | **7–8%** | **~1.6–1.8%** |
| **Median (50%)** | **~15%** | **3.4–3.9%** | **<3%** |
| Bottom 25% | 10–11.5% | ~1.5% | — |

Platform split at top-25% level: iOS D1 ~31–33%, Android D1 ~25–27%

### Cross-Source D1/D30 Comparison (All Genres)

| Source | D1 | D7 | D30 | Notes |
|--------|----|----|-----|-------|
| GameAnalytics 2025 (median) | ~15% | 3.4–3.9% | <3% | All games, most inclusive |
| GameAnalytics 2025 (top 25%) | 26–28% | 7–8% | ~1.6–1.8% | Healthy performance |
| Adjust 2025 | ~27% | — | ~5% | UA cohorts; iOS ~27%, Android ~24% |
| AppsFlyer 2024 | ~29.5% | ~8.7% | ~3.2% | UA + organic, 21.2B installs |
| Mistplay 2025 ("good game" target) | 40% | 20% | 10% | Aspirational — top 10–15% by GA data |

### Genre-Level Benchmarks (Mobile)
Sources: GameAnalytics via maf.ad compilation (D1/D30); Sensor Tower/Stepico (D7, top titles only)

| Genre | D1 | D7 | D30 | Source | Notes |
|-------|----|----|-----|--------|-------|
| Match-3 | 32.65% | — | 7.15% | GameAnalytics/maf.ad | |
| Puzzle | 31.85% | — | 5.35% | GameAnalytics/maf.ad | |
| Tabletop / Board | 31.30% | — | 5.51% | GameAnalytics/maf.ad | |
| RPG | 30.54% | — | 3.48% | GameAnalytics/maf.ad | |
| Simulation | 30.10% | — | — | GameAnalytics/maf.ad | |
| Casino | — | — | 4.10% | GameAnalytics/maf.ad | |
| Mid-core (top titles) | 44–45% | 20–21% | 11–12% | Sensor Tower/Stepico | Top-25 revenue charts only |
| Casual (top titles) | ~30% | 14–15% | 7–8% | Sensor Tower/Stepico | Top-25 revenue charts only |
| Hypercasual (top titles) | 38–40% | — | — | Sensor Tower/Stepico | Top-25 revenue charts only |
| Strategy (sessions/day: 4.0 — highest) | — | — | — | Mistplay 2025 | Retention % not available |
| Match-3 (D30 highest by loyalty) | — | — | 6.6% | Mistplay 2025 | Loyalty-biased sample |

**D7 by genre gap:** Genre-level D7 data is the most practically useful metric but the least publicly available. Full genre-by-genre D7 breakdowns exist in GameAnalytics' gated full report and the full Mistplay report. Public summaries do not include them.

### Trend Direction (2022–2025)
- D1 mobile retention declining ~1–2pp per year as competition increases
- Hybrid-casual surpassed casual on D7 by 2025 (Sensor Tower)
- AppsFlyer notes D30 declining ~20% year-over-year across mobile gaming category
- Puzzle and match genres show strongest D30 relative to D1 (stickiness advantage)

---

## PC / Steam Benchmarks (2025)

Source: GameAnalytics 2026 report (2025 data, 3,582 PC games with 100+ MAU) — **first systematic PC benchmark dataset from a major analytics provider**

| Percentile | D1 | D7 | D30 |
|-----------|----|----|-----|
| Top 1% | 50–60% | 20%+ | 13–15% |
| Top 10% | — | ~10–11% | ~2.5% |
| **Top 25%** | **15–16%** | **6–7%** | **~1.6–1.8%** |
| **Median** | — | **<4%** | **~0.7%** |

**PC median D30 of ~0.7% context:** PC games are typically played in irregular bursts rather than daily sessions. A player who plays 3x/week misses D30 if they happen to not play on that exact day. Session length is a better health indicator for PC: median 32–33 min/day, top-10% 120 min/day.

**DAU/MAU ratio (PC):** Median 4–5%. Top 10%: 13–15%. This is the healthier ongoing engagement metric for PC/Steam games.

**No public Steam-specific genre breakdown exists.** Valve does not publish cohort retention by genre. Per-game postmortems (GDC Vault, Gamediscoverco newsletter) are the closest available source for indie PC retention data.

---

## "Good" Retention Targets by Tier

Use these as directional targets, not pass/fail gates. Context always matters.

| Tier | D1 | D7 | D30 |
|------|----|----|-----|
| Strong indie (mobile) | 30%+ | 10%+ | 5%+ |
| Healthy indie (mobile) | 20–30% | 6–10% | 2–5% |
| Median mobile game | ~15% | ~3–4% | ~1–3% |
| Strong indie (PC/Steam) | 20%+ | 8%+ | 3%+ |
| Healthy indie (PC/Steam) | 12–20% | 4–7% | 1–2% |
| Median PC game | — | <4% | ~0.7% |

---

## Source Inventory

| Source | Report | Date | Platform | URL |
|--------|--------|------|----------|-----|
| GameAnalytics | 2025 Mobile Gaming Benchmarks | Feb 2025 (2024 data) | Mobile | https://www.gameanalytics.com/reports/2025-mobile-gaming-benchmarks |
| GameAnalytics | 2026 Mobile & PC Gaming Benchmarks | Jan 2026 (2025 data) | Mobile + PC | https://www.gameanalytics.com/reports/2026-mobile-pc-gaming-benchmarks |
| GameDevReports Substack | GA 2025 summary | Feb 2025 | Mobile | https://gamedevreports.substack.com/p/gameanalytics-mobile-gaming-benchmarks |
| GameDevReports Substack | GA 2026 summary | Jan 2026 | Mobile + PC | https://gamedevreports.substack.com/p/gameanalytics-mobile-and-pc-game |
| Adjust | Gaming App Insights 2025 | 2025 | Mobile | https://www.adjust.com/resources/ebooks/gaming-app-insights-2025/ |
| AppsFlyer | State of Gaming App Marketing 2024 | 2024 | Mobile | https://www.appsflyer.com/resources/reports/gaming-app-marketing-2024-report/ |
| AppsFlyer | App Retention Benchmarks infogram | 2024 | Mobile | https://www.appsflyer.com/infograms/app-retention-benchmarks/ |
| Mistplay | 2025 Mobile Gaming Loyalty Index | Mar 2025 | Mobile | https://business.mistplay.com/resources/mobile-gaming-trends-2025-report |
| Mistplay | Big list of retention benchmarks | 2025 | Mobile | https://business.mistplay.com/resources/mobile-game-retention-benchmarks |
| Sensor Tower / Stepico | Mobile Gaming Retention Era analysis | 2025 | Mobile | https://stepico.com/blog/mobile-gaming-has-entered-its-retention-era-what-sensor-tower-data-means/ |
| Liftoff | 2025 Casual Gaming Apps Report | 2025 | Mobile | https://liftoff.ai/2025-casual-gaming-apps-report/ |
| maf.ad | Mobile retention benchmark compilation | 2025 | Mobile | https://maf.ad/en/blog/mobile-game-retention-benchmarks/ |
| Admiral Media | Mobile Game Marketing Benchmarks 2025 | 2025 | Mobile | https://admiral.media/mobile-game-marketing-benchmarks/ |
| Gamediscoverco newsletter | Ongoing Steam ecosystem analysis | Ongoing | PC/Steam | https://newsletter.gamediscover.co |

---

## Refresh Notes

This file is the data source for `/retention-analysis` benchmark comparisons.

- **Refresh cadence:** Annually, or when a major new report is published (GameAnalytics typically releases in Jan–Feb each year)
- **How to refresh:** Run `/retention-analysis` and choose option B (WebSearch for updated data)
- **Last WebSearch performed:** 2026-06-10
- **Known gaps:** Genre-level D7 for mobile not publicly available (gated in full reports); Steam genre-level retention not available from any public source
