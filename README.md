# Claude Code Monitor

A menu bar / system tray widget that shows your **remaining** Claude Code rate limits in real time. Available for **macOS** and **Windows**.

## What It Looks Like

### macOS (SwiftBar)

```
🟢 52% · 7d:81%                 ← menu bar (5h session · 7-day window)
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

### Windows (System Tray)

A color-coded progress arc icon appears in your system tray — the arc fills based on remaining %. Right-click for details:

```
┌──────────────────────────────┐
│ Claude Code (max)            │
│──────────────────────────────│
│ 🟢  5-Hour Session           │
│ ■■■■■■■■■■□□□□□□□□□□         │
│ 52% remaining                │
│ Refills in 3h 42m            │
│──────────────────────────────│
│ 🟢  7-Day Window             │
│ ■■■■■■■■■■■■■■■■□□□□         │
│ 81% remaining                │
│ Refills in 4d 12h            │
│──────────────────────────────│
│ Source: live                 │
│──────────────────────────────│
│ Refresh Now                  │
│ Open Log                     │
│ Exit                         │
└──────────────────────────────┘
```

## Features

- **5-Hour Session** — remaining % of your rolling 5-hour window
- **7-Day Window** — remaining % of your weekly limit
- **7-Day Opus** — remaining Opus-specific quota (if applicable)
- **Plan type** — shows your subscription tier (Pro/Max)
- **Smart caching** — avoids API rate limits (429) with local cache + graceful fallback
- **Logging** — debug log for troubleshooting

Color-coded at a glance: 🟢 >50% left · 🟡 20–50% left · 🔴 <20% left

---

## macOS Installation

### Prerequisites

| Requirement | Install |
|---|---|
| macOS | — |
| [SwiftBar](https://github.com/swiftbar/SwiftBar) | `brew install --cask swiftbar` |
| [jq](https://jqlang.github.io/jq/) | `brew install jq` |
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

Or if you already have a SwiftBar plugins folder, copy just the script:

```bash
curl -o ~/SwiftBarPlugins/claude-code-monitor.1m.sh \
  https://raw.githubusercontent.com/haomingkoo/claude-code-monitor/main/macos/claude-code-monitor.1m.sh
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

A color-coded progress arc icon will appear in your system tray. Hover for a quick summary, right-click for full details.

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
3. **Cache** — Stores the response at `~/.cache/claude-usage/usage.json` to avoid repeated API calls
4. **Parse** — Extracts `five_hour.utilization` and `seven_day.utilization`, computes remaining (`100 - used`)
5. **Render** — Displays the data (macOS: SwiftBar menu bar, Windows: system tray icon + context menu)
6. **Fallback** — On 429 or network error, displays the last cached data instead of crashing

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

## Configuration

### Refresh Interval

**macOS:** The refresh rate is controlled by the **filename**. Rename to change it:

```bash
cd ~/SwiftBarPlugins

# Every 1 minute (default)
# claude-code-monitor.1m.sh

# Every 5 minutes (conservative, recommended if you hit 429s)
mv claude-code-monitor.1m.sh claude-code-monitor.5m.sh
```

**Windows:** Edit `$script:PollInterval` at the top of `claude-code-monitor.ps1` (default: 60 seconds).

### Cache TTL

Both versions cache API responses to prevent excessive calls. Edit the `CACHE_TTL` / `$script:CacheTTL` variable at the top of the script:

```
CACHE_TTL=120          # macOS (seconds)
$script:CacheTTL = 120 # Windows (seconds)
```

> Even at a 1-minute refresh, the API is only called when the cache expires. Between cache refreshes, the monitor re-renders from cached data.

## Security

- Your OAuth token is read **locally** from your own system (macOS Keychain / Windows credentials file)
- It is **only** sent to `api.anthropic.com` (Anthropic's own servers)
- No tokens are written to disk or logged
- Cache (`~/.cache/claude-usage/usage.json`) contains only usage percentages and reset timestamps
- Logs contain only debug metadata (timestamps, status codes)

## Troubleshooting

### macOS

| Symptom | Cause | Fix |
|---|---|---|
| `CC: no auth` | Not logged into Claude Code | Run `claude` in terminal and authenticate |
| `CC: no token` | Keychain entry is corrupted | Run `claude logout` then `claude` to re-authenticate |
| `CC: error` | API returned an error | Click **Open log** to see details |
| `CC: 429` | Rate limited by Anthropic | Plugin shows stale cache automatically. Increase `CACHE_TTL` if persistent |
| Widget not showing | SwiftBar not pointing to plugin folder | Open SwiftBar preferences and set folder to `~/SwiftBarPlugins` |
| README errors in SwiftBar | SwiftBar tried to execute README.md | Ensure `.swiftbarignore` file exists with `README.md` listed |

### Windows

| Symptom | Cause | Fix |
|---|---|---|
| No tray icon | Script not running | Run via `launch-monitor.bat` or PowerShell command above |
| "No data" tooltip | Not logged into Claude Code | Run `claude` in terminal and authenticate |
| "Already running" popup | Another instance exists | Check system tray for existing icon |
| Icon stuck on old data | Cache not expired | Right-click tray icon → **Refresh Now** |

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

## License

MIT
