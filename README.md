# Claude Code Monitor

A menu bar / system tray widget that shows your **remaining** Claude Code rate limits in real time — with pace tracking, burnout projections, and native notifications. Available for **macOS** and **Windows**.

## What It Looks Like

### macOS (SwiftBar)

```
  52% · 7d:81%                         <- menu bar

  Claude Code (max)
  ---------------------------------
  5-Hour Session
  ||||||||||||..........
  52.0% remaining
  Refills in 3h 42m (4:00 PM)
  Pace: 1.0x
  Burns out in ~5h 12m
  ---------------------------------
  7-Day Window
  ||||||||||||||||....
  81.0% remaining
  Refills in 4d 12h (Mar 16)
  Pace: 0.7x
  Burns out in ~6d 11h
  ---------------------------------
  Source: live
  ---------------------------------
  Refresh
  Open log
  ---------------------------------
  Language                          >
  Refresh Rate                      >
```

### Windows (System Tray)

Two icon shapes **rotate** in the system tray — a **donut ring** for the 5-hour session and a **horizontal bar** for the 7-day window. Left-click or right-click for the full dropdown:

```
  Claude Code (max)
  ---------------------------------
  5-Hour Session  [donut icon]
  ||||||||||||..........
  52% remaining
  Refills in 3h 42m (3:49 PM)
  Pace: 1.0x
  Burns out in ~5h 12m
  ---------------------------------
  7-Day Window  [bar icon]
  ||||||||||||||||....
  81% remaining
  Refills in 4d 12h (Mar 16)
  Pace: 0.7x
  Burns out in ~6d 11h
  ---------------------------------
  Source: live
  ---------------------------------
  Refresh Now
  Open Log
  Language                          >
  Settings                          >
  Exit
```

## Features

### Rate Limit Monitoring
- **5-Hour Session** — remaining % of your rolling 5-hour window
- **7-Day Window** — remaining % of your weekly limit
- **7-Day Opus** — Opus-specific quota (shown when applicable)
- **Null-safe** — shows "Not available yet" when data is missing instead of hiding or faking values

### Smart Analytics (macOS + Windows)
- **Local reset time** — countdown + local time (e.g., "Refills in 1h 49m (4:00 PM)")
- **Pace indicator** — are you burning faster than sustainable?

  | Icon | Pace | Meaning |
  |------|------|---------|
  | 🐢 | < 0.8x | Conservative — plenty of headroom |
  | ✅ | 0.8–1.3x | On pace — sustainable usage |
  | ⚡ | 1.3–2.0x | Fast — will run out before reset |
  | 🔥 | > 2.0x | Burning way too fast |

- **Burnout projection** — "Burns out in ~12h" based on your current rate

### Notifications (macOS + Windows)
- Native alerts at **50%**, **25%**, and **10%** remaining
- macOS: notification center alerts with sound · Windows: balloon tip notifications
- Auto-resets when the window refills — no duplicate alerts
- Configurable thresholds

### Dual Rotating Icons (Windows)
The system tray alternates between two icon shapes for at-a-glance monitoring:
- **Donut ring** — 5-hour session remaining %
- **Horizontal bar** — 7-day window remaining %

Rotation speed is adjustable from **Settings > Icon Rotation Speed** (2s / 4s / 8s / 15s).

### Multi-Language — 6 Languages (macOS + Windows)
Switch from the dropdown menu — no script editing needed.

| Code | Language |
|------|----------|
| `en` | English |
| `zh` | 中文 (Chinese) |
| `ja` | 日本語 (Japanese) |
| `ko` | 한국어 (Korean) |
| `ta` | தமிழ் (Tamil) |
| `ms` | Bahasa Melayu (Malay) |

### Reliability
- **Timezone-safe** — python3 ISO 8601 parsing handles any timezone offset; macOS `date -u` fallback
- **Smart caching** — avoids API rate limits (429) with local cache + graceful stale data fallback
- **Adaptive theme** — auto-detects light/dark mode with optimized color contrast (macOS)
- **Logging** — debug log for troubleshooting

### At a Glance
🟢 >50% left · 🟡 20–50% left · 🔴 <20% left

---

## Important: 7-Day Window Risk

The **7-day window is the real constraint** for heavy users. While the 5-hour session resets frequently, the weekly limit is a hard ceiling that only resets once per week.

| Risk | Impact |
|------|--------|
| **No partial reset** | Resets all at once on a fixed schedule, not rolling |
| **Shared quota** | Claude.ai web chat + Claude Code share the same weekly limit |
| **Pace matters** | 🔥 2.0x pace = exhausting a week's quota in ~3.5 days |
| **Pro limits are tighter** | Heavy sessions can burn through Pro weekly limits in 2–3 days |
| **Null data possible** | Some accounts show `null` for 7-day — plugin displays "Not available yet" |

**Recommendation:** Keep the 7-day pace at ✅ 1.0x or below. If you see ⚡ or 🔥 on the 7-day window, slow down to avoid a mid-week lockout.

---

## macOS Installation

### Prerequisites

| Requirement | Install |
|---|---|
| macOS | — |
| [SwiftBar](https://github.com/swiftbar/SwiftBar) | `brew install --cask swiftbar` |
| [jq](https://jqlang.github.io/jq/) | `brew install jq` |
| python3 (recommended) | `brew install python3` or Xcode CLT |
| [Claude Code](https://docs.anthropic.com/en/docs/claude-code) | `brew install claude-code` or `npm install -g @anthropic-ai/claude-code` |

You must be **logged into Claude Code** via OAuth (i.e., you've run `claude` at least once and authenticated). The plugin reads your OAuth token from the macOS Keychain — no API key needed.

### Step 1: Install dependencies

```bash
brew install --cask swiftbar
brew install jq
```

### Step 2: Clone this repo

```bash
git clone https://github.com/haomingkoo/claude-code-monitor.git ~/SwiftBarPlugins
```

Or if you already have a SwiftBar plugins folder, copy the script:

```bash
curl -o ~/SwiftBarPlugins/claude-code-monitor.2m.sh \
  https://raw.githubusercontent.com/haomingkoo/claude-code-monitor/main/claude-code-monitor.2m.sh
chmod +x ~/SwiftBarPlugins/claude-code-monitor.2m.sh
```

> Helper scripts for language and refresh rate selection are auto-created in `~/.cache/claude-usage/scripts/` on first run — no manual setup needed.

### Step 3: Configure SwiftBar

1. Open SwiftBar:
   ```bash
   open -a SwiftBar
   ```
2. SwiftBar will ask you to choose a **Plugin Folder**
3. In the folder picker, press **Cmd + Shift + G** and type `~/SwiftBarPlugins`
4. Click **Open**

You should now see **🟢 XX% · 7d:XX%** in your menu bar.

---

## Windows Installation

### Prerequisites

| Requirement | Notes |
|---|---|
| Windows 10/11 | — |
| PowerShell 5.1+ | Ships with Windows |
| .NET Framework | Ships with Windows |
| [Claude Code](https://docs.anthropic.com/en/docs/claude-code) | `npm install -g @anthropic-ai/claude-code` |

You must be **logged into Claude Code** via OAuth (i.e., you've run `claude` at least once and authenticated). The monitor reads your OAuth token from `~/.claude/.credentials.json` — no API key needed.

### Step 1: Clone this repo

```powershell
git clone https://github.com/haomingkoo/claude-code-monitor.git
```

### Step 2: Run the monitor

**Option A** — Double-click `windows\launch-monitor.bat`

**Option B** — Run from terminal:

```powershell
powershell -ExecutionPolicy Bypass -WindowStyle Hidden -File windows\claude-code-monitor.ps1
```

> **Note:** The `.bat` launcher runs PowerShell completely in the background — no CMD window will remain open.

Two alternating icons will appear in your system tray — a donut ring (5h) and a bar (7d). Left-click or right-click for the full dropdown with pace, burnout, and language options.

### Auto-start on login (optional)

1. Press **Win + R**, type `shell:startup`, press Enter
2. Copy `windows\launch-monitor.bat` into that folder (edit the path inside if needed)

---

## How It Works

```
┌─────────────┐     ┌──────────────────┐     ┌─────────────┐
│ Credentials │     │ Anthropic API    │     │ Menu Bar /  │
│ (Keychain / │────>│ /api/oauth/usage │────>│ System Tray │
│  .json file)│     │ (GET, cached)    │     │ (render)    │
└─────────────┘     └──────────────────┘     └─────────────┘
```

1. **Auth** — Reads your Claude Code OAuth token (macOS: Keychain, Windows: `~/.claude/.credentials.json`)
2. **Fetch** — Calls `GET https://api.anthropic.com/api/oauth/usage` with Bearer token auth
3. **Cache** — Stores the response at `~/.cache/claude-usage/usage.json` (TTL: varies by refresh rate)
4. **Parse** — Extracts utilization percentages, computes remaining, pace, and burnout
5. **Render** — Displays the data (macOS: SwiftBar menu bar, Windows: system tray icon + context menu)
6. **Notify** — Sends native alerts when thresholds are crossed (macOS + Windows)
7. **Fallback** — On 429 or network error, displays the last cached data

### API Response Format

The monitor reads from an unofficial (but widely used) Anthropic endpoint:

```json
{
  "five_hour": {
    "utilization": 48.0,
    "resets_at": "2026-03-11T20:00:00+00:00"
  },
  "seven_day": {
    "utilization": 19.0,
    "resets_at": "2026-03-15T08:00:00+00:00"
  },
  "seven_day_opus": {
    "utilization": 5.0,
    "resets_at": null
  }
}
```

### Pace Calculation

```
ideal_usage = (elapsed / window_size) × 100%
pace = actual_usage / ideal_usage
```

A pace of **1.0x** means you're using tokens exactly evenly across the window. Above 1.0x and you'll run out before reset.

### Burnout Projection

```
time_to_burnout = (remaining% / used%) × elapsed_time
```

Simple linear projection — "if you keep doing what you're doing, when do you hit 100%?"

## Configuration

### Language (macOS + Windows)

Click **Language** in the dropdown menu to switch. No restart needed.

Or set it manually:

```bash
# macOS
echo "zh" > ~/.cache/claude-usage/language

# Windows (PowerShell)
"zh" | Set-Content ~\.cache\claude-usage\language
```

### Refresh Rate (macOS)

Select from the **⏱ Refresh Rate** flyout submenu in the dropdown. Options: 2m, 5m, 10m. Default: **2m**.

This controls the cache TTL (how often the API is called). The plugin filename stays fixed at `.2m.sh` — do **not** rename it, as SwiftBar will lose track of the plugin.

Or set it manually:

```bash
echo "5m" > ~/.cache/claude-usage/refresh_rate
```

**Windows:** Right-click tray icon → **Settings** → **Data Refresh Interval** (30s / 1m / 2m / 5m). Or edit `$script:PollInterval` in the script.

### Notification Thresholds (macOS + Windows)

```bash
# macOS — edit in script
NOTIFY_THRESHOLDS="50 25 10"

# Windows — edit in script
$script:NotifyThresholds = @(50, 25, 10)
```

### Cache TTL

Cache TTL is set automatically based on your refresh rate. The API is only called when the cache expires, and on errors the cache timestamp is refreshed to prevent repeated failing calls.

```
$script:CacheTTL = 120 # Windows (seconds) — edit in claude-code-monitor.ps1
```

| Refresh Rate | Cache TTL | API calls/hour |
|---|---|---|
| 2m | 120s | ~30 |
| 5m | 300s | ~12 |
| 10m | 600s | ~6 |

> **Note:** The plugin file is `.2m.sh`, so SwiftBar runs the script every 2 minutes. The Cache TTL controls how often the API is actually called — if the cache hasn't expired, the run uses cached data.

## Security

- OAuth token is read **locally** from your own system (macOS Keychain / Windows credentials file)
- Token is **only** sent to `api.anthropic.com` (Anthropic's servers)
- No tokens written to disk or logged
- Cache contains only usage percentages and reset timestamps
- Logs contain only debug metadata (timestamps, status codes)

## Troubleshooting

### macOS

| Symptom | Cause | Fix |
|---|---|---|
| `CC: no auth` | Not logged into Claude Code | Run `claude` in terminal and authenticate |
| `CC: no token` | Keychain entry corrupted | Run `claude logout` then `claude` to re-authenticate |
| `CC: error` | API returned an error | Click **Open log** to see details |
| `CC: 429` | Rate limited by Anthropic | Wait a few minutes — the plugin backs off automatically. If persistent, see [Rate Limit Death Spiral](#rate-limit-death-spiral-fixed-in-v90) below |
| Widget not showing | SwiftBar not configured | Open SwiftBar preferences → set folder to `~/SwiftBarPlugins` |
| Faint text | macOS vibrancy | Already fixed in v8.0 — update to latest version |

### Windows

| Symptom | Cause | Fix |
|---|---|---|
| CMD window stays open | Using old `.bat` without VBS | Update to v8.1 — the `.bat` now delegates to `launch-monitor.vbs` for silent launch |
| No tray icon | Script not running | Run via `launch-monitor.bat` or PowerShell command above |
| "No data" tooltip | Not logged into Claude Code | Run `claude` in terminal and authenticate |
| "Already running" popup | Another instance exists | Check system tray for existing icon |
| Icon stuck on old data | Cache not expired | Right-click tray icon → **Refresh Now** |

### Rate Limit Death Spiral (Fixed in v9.0)

**Symptom:** The widget permanently shows `CC: 429` or `Source: rate limited — showing stale data`, and never recovers — even after waiting.

**Root cause (v8.0 and earlier):** When the Anthropic API returned 429 (rate limited), the plugin retried on every run without backing off. Each failed retry counted against the rate limit, creating an infinite loop:

```
API call → 429 → no backoff → next run → API call → 429 → repeat forever
```

This was caused by a bug where the cache file's timestamp was never updated on errors, so the cache-TTL check always saw "cache expired" and made another API call.

**Fix (v9.0):** The plugin now refreshes the cache timestamp on 429/error responses, so subsequent runs serve cached data instead of hammering the API. The rate limit recovers naturally.

**If you're stuck on 429:**

1. **Wait 5 minutes** — the v9.0 backoff logic will recover automatically
2. **If still stuck after 10+ minutes**, your OAuth token's rate limit may be exhausted. Re-authenticate to get a fresh token:
   ```bash
   claude auth logout
   claude auth login
   ```
3. **Reduce refresh rate** — select a slower rate from the ⏱ Refresh Rate menu (5m or 10m recommended)
4. **Nuclear option** — clear everything and start fresh:
   ```bash
   rm -rf ~/.cache/claude-usage
   claude auth logout
   claude auth login
   ```
   Then restart SwiftBar.

> **Note:** If you recently logged into Claude Code on another device, your existing token may still be valid but could have a depleted rate limit quota. Re-authenticating on your current device is the quickest fix.

### Viewing Logs

```bash
# macOS
tail -20 ~/.cache/claude-usage/plugin.log

# Windows (PowerShell)
Get-Content ~\.cache\claude-usage\monitor.log -Tail 20
```

### Clearing Cache

```bash
# macOS
rm -rf ~/.cache/claude-usage

# Windows (PowerShell)
Remove-Item ~\.cache\claude-usage -Recurse -Force
```

The monitor will recreate the cache directory on the next run.

## Version History

| Version | Changes |
|---------|---------|
| **v9.2** | Auto-create helper scripts on first run (zero manual setup). Add MIT LICENSE. Clean up repo structure. Fix jq detection and cache TTL values. |
| **v9.0** | **Critical fix:** rate limit death spiral (backoff on 429). Configurable refresh rate via flyout submenu (2m/5m/10m). Language + refresh rate now use compact flyout submenus. Dynamic cache TTL based on refresh rate. |
| **v8.1** | Windows: fix CMD window staying open on launch — use VBS silent launcher for zero-window startup |
| **v8.0** | Full feature parity: Windows gets dual rotating icons (donut/bar), pace/burnout, 6 languages, notifications, settings menu, left-click support. macOS: fix text legibility, add Tamil, clickable language selector |
| **v7.0** | Fix timezone bug, add pace indicator, local reset time, burnout projection, notifications, multi-language (en/zh/ja/ko/ms) |
| **v6.0** | Add null-safe 7-day handling, robust ISO 8601 parsing with python3, multi-language support |
| **v5.0** | Initial release: 5h/7d/Opus monitoring, progress bars, adaptive theme, smart caching |

## License

MIT
