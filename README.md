# Claude Code Monitor

A macOS menu bar widget that shows your **remaining** Claude Code rate limits in real time.

> **Platform:** macOS only. This plugin uses [SwiftBar](https://github.com/swiftbar/SwiftBar) (macOS menu bar app) and reads credentials from the macOS Keychain. It is not compatible with Linux or Windows.

## What It Looks Like

```
🟢 CC 52% left                  ← menu bar
┌──────────────────────────────┐
│ Claude Code (max)            │
│──────────────────────────────│
│ 🟢  5-Hour Session           │
│ ■■■■■■■■■■□□□□□□□□□□         │
│ 52.0% remaining              │
│ Refills in 3h 42m            │
│──────────────────────────────│
│ 🟢  7-Day Window             │
│ ■■■■■■■■■■■■■■■■□□□□         │
│ 81.0% remaining              │
│ Refills in 4d 12h            │
│──────────────────────────────│
│ Source: live                 │
│──────────────────────────────│
│ Refresh                      │
│ Open log                     │
└──────────────────────────────┘
```

## Features

- **5-Hour Session** — remaining % of your rolling 5-hour window
- **7-Day Window** — remaining % of your weekly limit
- **7-Day Opus** — remaining Opus-specific quota (if applicable)
- **Plan type** — shows your subscription tier (Pro/Max)
- **Adaptive theme** — auto-detects light/dark mode
- **Smart caching** — avoids API rate limits (429) with local cache + graceful fallback
- **Logging** — debug log at `~/.cache/claude-usage/plugin.log`

Color-coded at a glance: 🟢 >50% left · 🟡 20–50% left · 🔴 <20% left

## Prerequisites

| Requirement | Install |
|---|---|
| macOS | — |
| [SwiftBar](https://github.com/swiftbar/SwiftBar) | `brew install --cask swiftbar` |
| [jq](https://jqlang.github.io/jq/) | `brew install jq` |
| [Claude Code](https://docs.anthropic.com/en/docs/claude-code) | `brew install claude-code` or `npm install -g @anthropic-ai/claude-code` |

You must be **logged into Claude Code** via OAuth (i.e., you've run `claude` at least once and authenticated). The plugin reads your OAuth token from the macOS Keychain — no API key needed.

## Installation

### Step 1: Install dependencies

```bash
brew install --cask swiftbar
brew install jq
```

### Step 2: Clone this repo

```bash
git clone https://github.com/YOUR_USERNAME/claude-code-monitor.git ~/SwiftBarPlugins
```

Or if you already have a SwiftBar plugins folder, copy just the script:

```bash
curl -o ~/SwiftBarPlugins/claude-code-monitor.1m.sh \
  https://raw.githubusercontent.com/YOUR_USERNAME/claude-code-monitor/main/claude-code-monitor.1m.sh
chmod +x ~/SwiftBarPlugins/claude-code-monitor.1m.sh
```

### Step 3: Configure SwiftBar

1. Open SwiftBar:
   ```bash
   open -a SwiftBar
   ```
2. SwiftBar will ask you to choose a **Plugin Folder**
3. In the folder picker, press **Cmd + Shift + G** and type `~/SwiftBarPlugins`
4. Click **Open**

You should now see **🟢 CC XX% left** in your menu bar.

## How It Works

```
┌─────────────┐     ┌──────────────────┐     ┌─────────────┐
│ macOS        │     │ Anthropic API    │     │ SwiftBar    │
│ Keychain     │────>│ /api/oauth/usage │────>│ Menu Bar    │
│ (OAuth token)│     │ (GET, cached)    │     │ (render)    │
└─────────────┘     └──────────────────┘     └─────────────┘
```

1. **Auth** — Reads your Claude Code OAuth token from the macOS Keychain (`security find-generic-password`)
2. **Fetch** — Calls `GET https://api.anthropic.com/api/oauth/usage` with Bearer token auth
3. **Cache** — Stores the response at `~/.cache/claude-usage/usage.json` to avoid repeated API calls
4. **Parse** — Extracts `five_hour.utilization` and `seven_day.utilization`, computes remaining (`100 - used`)
5. **Render** — Outputs SwiftBar-formatted text with progress bars, colors, and status icons
6. **Fallback** — On 429 or network error, displays the last cached data instead of crashing

### API Response Format

The plugin reads from an unofficial (but widely used) Anthropic endpoint:

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

## Configuration

### Refresh Interval

The refresh rate is controlled by the **filename**. Rename to change it:

```bash
cd ~/SwiftBarPlugins

# Every 1 minute (default)
# claude-code-monitor.1m.sh

# Every 2 minutes
mv claude-code-monitor.1m.sh claude-code-monitor.2m.sh

# Every 5 minutes (conservative, recommended if you hit 429s)
mv claude-code-monitor.1m.sh claude-code-monitor.5m.sh
```

### Cache TTL

The plugin caches API responses to prevent excessive calls. Edit the `CACHE_TTL` variable at the top of the script:

```bash
CACHE_TTL=120  # seconds — API is called at most once every 2 minutes
```

> Even at a 1-minute SwiftBar refresh, the API is only called when the cache expires. Between cache refreshes, the plugin re-renders from cached data.

## Security

- Your OAuth token is read **locally** from your own macOS Keychain
- It is **only** sent to `api.anthropic.com` (Anthropic's own servers)
- No tokens are written to disk or logged
- Cache (`~/.cache/claude-usage/usage.json`) contains only usage percentages and reset timestamps
- Log (`~/.cache/claude-usage/plugin.log`) contains only debug metadata (timestamps, status codes)

## Troubleshooting

| Symptom | Cause | Fix |
|---|---|---|
| `CC: no auth` | Not logged into Claude Code | Run `claude` in terminal and authenticate |
| `CC: no token` | Keychain entry is corrupted | Run `claude logout` then `claude` to re-authenticate |
| `CC: error` | API returned an error | Click **Open log** to see details |
| `CC: 429` | Rate limited by Anthropic | Plugin shows stale cache automatically. Increase `CACHE_TTL` if persistent |
| Widget not showing | SwiftBar not pointing to plugin folder | Open SwiftBar preferences and set folder to `~/SwiftBarPlugins` |
| README errors in SwiftBar | SwiftBar tried to execute README.md | Ensure `.swiftbarignore` file exists with `README.md` listed |

### Viewing Logs

```bash
# View recent log entries
tail -20 ~/.cache/claude-usage/plugin.log

# Watch live
tail -f ~/.cache/claude-usage/plugin.log
```

### Clearing Cache

```bash
rm -rf ~/.cache/claude-usage
```

The plugin will recreate the cache directory on the next run.

## License

MIT
