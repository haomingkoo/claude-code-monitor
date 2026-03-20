# Claude Code Monitor

Know exactly how much Claude Code you have left — right from your menu bar.

A lightweight widget that tracks your **remaining** rate limits in real time, tells you when you're burning too fast, and alerts you before you run out. Available for **macOS** (SwiftBar) and **Windows** (system tray).

**New in v10.0:** Get alerts on your phone and smart "tokens refreshing soon" reminders — [see below](#-phone-alerts-optional--macos).

---

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
  Refresh Rate                      >
  Language                          >
  ⏰ Remind Before Reset            >
  📱 Phone Alerts (ntfy)            >
```

### Windows (System Tray)

Two icons **rotate** in the system tray — a **donut ring** for the 5-hour session and a **bar** for the 7-day window. Click for the full dropdown:

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

At a glance: 🟢 >50% left · 🟡 20–50% left · 🔴 <20% left

---

## Features

### See What's Left
- **5-Hour Session** — how much of your rolling 5-hour window remains
- **7-Day Window** — how much of your weekly limit remains
- **7-Day Opus** — Opus-specific quota (shown when applicable)

### Know When It Resets
- Countdown timer + local time — e.g., "Refills in 1h 49m (4:00 PM)"
- No timezone math needed — it's already converted for you

### Know If You're Going Too Fast

| Icon | Pace | What it means |
|------|------|---------------|
| 🐢 | < 0.8x | Chill — you have plenty of headroom |
| ✅ | 0.8–1.3x | Sustainable — you'll make it to reset |
| ⚡ | 1.3–2.0x | Fast — you'll run out before reset at this rate |
| 🔥 | > 2.0x | Way too fast — slow down |

- **Burnout projection** — tells you when you'll hit 0% if you keep going at your current rate

### Get Alerted Before You Run Out
- Desktop notifications at **50%**, **25%**, and **10%** remaining
- macOS: notification center with sound · Windows: balloon tips
- No duplicate alerts — auto-resets when your window refills

### Get Reminded When Tokens Refresh (NEW · macOS)
- Notifies you before your 5-hour or 7-day window resets — so you know when to get back to work
- **Smart** — won't bother you if you're actively coding (pace > 1.3x). Only nudges when you're idle.
- Configurable: 60, 30, and 10 minutes before reset (default). Change from the dropdown menu.

### 📱 Phone Alerts (Optional · macOS)

Get the same alerts on your phone — away from your desk? You'll still know when tokens are low or about to refresh.

Uses [ntfy](https://ntfy.sh), a free and open-source notification service. **No accounts, no API keys, no tokens stored on your computer.**

> Currently macOS-only. Windows support may come in a future release.

**Setup takes 30 seconds:**

1. Install the **ntfy** app — [iOS](https://apps.apple.com/app/ntfy/id1625396347) · [Android](https://play.google.com/store/apps/details?id=io.heckel.ntfy)
2. In the menu bar dropdown, click **📱 Phone Alerts → Set Topic…**
3. A dialog pops up with a random topic name (like a private channel) — click OK
4. On your phone, open ntfy → tap **+** → type the same topic name → Subscribe

Done. Your phone will now receive:

| What you'll get | How it alerts | When |
|----------------|---------------|------|
| **Status check-in** | Silent — just open the app to see it | Periodically (every 30m by default) |
| **"Tokens resetting soon"** | Normal notification | Before your window resets |
| **50% remaining** | Normal notification | When you drop below 50% |
| **25% remaining** | Louder notification | When you drop below 25% |
| **10% remaining** | Urgent notification | When you're almost out |

**What's configurable:**

| Feature | Where to change it | Default |
|---------|-------------------|---------|
| Usage alerts (50/25/10%) | Always on when phone alerts are enabled | On |
| Reset reminders | ⏰ Remind Before Reset menu | 60 · 30 · 10 min |
| Status check-ins | 📱 Phone Alerts → Status Push | Every 30m (options: 10m / 30m / 1h / 2h / Off) |

Desktop alerts (notifications on your Mac) work regardless of whether you set up phone alerts. Phone alerts just extend them to your pocket.

**Privacy:** Nothing sensitive is stored. The topic name is just a word you pick — not a password. Even if someone guessed it, all they'd see is "Claude Code at 25%." You can also [self-host ntfy](https://docs.ntfy.sh/install/) for full control.

**Fully optional** — skip this section entirely and everything else works exactly the same.

### Multi-Language — 6 Languages

Switch from the dropdown menu. No restart needed.

| Language | |
|----------|--|
| English | 🇺🇸 |
| 中文 (Chinese) | 🇨🇳 |
| 日本語 (Japanese) | 🇯🇵 |
| 한국어 (Korean) | 🇰🇷 |
| தமிழ் (Tamil) | 🇮🇳 |
| Bahasa Melayu (Malay) | 🇲🇾 |

### Dual Rotating Icons (Windows)
The system tray alternates between two icon shapes:
- **Donut ring** — 5-hour session
- **Horizontal bar** — 7-day window

Rotation speed is adjustable from **Settings > Icon Rotation Speed**.

---

## Why the 7-Day Window Matters

The 5-hour session resets often, but the **7-day window is the real limit**. It resets once per week — and if you burn through it early, you're locked out until it resets.

| What to know | |
|---|---|
| Resets all at once — not gradually | Plan around the reset date |
| Claude.ai web chat shares the same quota | Both count toward your weekly limit |
| 🔥 2.0x pace = burning a week's worth in ~3.5 days | Watch your pace indicator |

**Tip:** Keep the 7-day pace at ✅ 1.0x or below. If you see ⚡ or 🔥, ease off.

---

## Installation

### macOS

**What you need:**

| Requirement | Install |
|---|---|
| [SwiftBar](https://github.com/swiftbar/SwiftBar) | `brew install --cask swiftbar` |
| [jq](https://jqlang.github.io/jq/) | `brew install jq` |
| python3 (recommended) | `brew install python3` or Xcode CLT |
| [Claude Code](https://docs.anthropic.com/en/docs/claude-code) | `brew install claude-code` or `npm install -g @anthropic-ai/claude-code` |

You must have **logged into Claude Code** at least once (`claude` in terminal → authenticate).

**Step 1:** Install dependencies

```bash
brew install --cask swiftbar
brew install jq
```

**Step 2:** Get the plugin

```bash
git clone https://github.com/haomingkoo/claude-code-monitor.git ~/SwiftBarPlugins
```

Or just download the script:

```bash
curl -o ~/SwiftBarPlugins/claude-code-monitor.2m.sh \
  https://raw.githubusercontent.com/haomingkoo/claude-code-monitor/main/claude-code-monitor.2m.sh
chmod +x ~/SwiftBarPlugins/claude-code-monitor.2m.sh
```

**Step 3:** Point SwiftBar to the plugin folder

1. Open SwiftBar → it asks for a **Plugin Folder**
2. Press **Cmd + Shift + G**, type `~/SwiftBarPlugins`, click **Open**

You should see **🟢 XX% · 7d:XX%** in your menu bar. Everything else (helper scripts, cache) is created automatically.

### Windows

**What you need:**

| Requirement | Notes |
|---|---|
| Windows 10/11 | |
| PowerShell 5.1+ | Comes with Windows |
| [Claude Code](https://docs.anthropic.com/en/docs/claude-code) | `npm install -g @anthropic-ai/claude-code` |

You must have **logged into Claude Code** at least once.

**Step 1:** Get the code

```powershell
git clone https://github.com/haomingkoo/claude-code-monitor.git
```

**Step 2:** Run it

Double-click `windows\launch-monitor.bat` — or from terminal:

```powershell
powershell -ExecutionPolicy Bypass -WindowStyle Hidden -File windows\claude-code-monitor.ps1
```

Two icons appear in your system tray. Click for the full dropdown.

**Auto-start on login (optional):** Press **Win + R** → type `shell:startup` → copy `launch-monitor.bat` into that folder.

---

## Configuration

All settings are accessible from the **dropdown menu** — no file editing required. But if you prefer the terminal:

### Language

```bash
# macOS
echo "zh" > ~/.cache/claude-usage/language

# Windows (PowerShell)
"zh" | Set-Content ~\.cache\claude-usage\language
```

### Refresh Rate (macOS)

How often the API is checked. Options: 2m (default), 5m, 10m.

```bash
echo "5m" > ~/.cache/claude-usage/refresh_rate
```

> **Important:** Don't rename the `.2m.sh` file — SwiftBar needs that exact filename.

**Windows:** Right-click tray icon → **Settings** → **Data Refresh Interval**.

### Reset Reminders (macOS)

```bash
echo "60 30 10" > ~/.cache/claude-usage/remind_before   # minutes before reset
echo "" > ~/.cache/claude-usage/remind_before            # turn off
```

### Phone Alerts (macOS)

```bash
echo "my-topic-name" > ~/.cache/claude-usage/ntfy_topic
echo "true" > ~/.cache/claude-usage/ntfy_enabled
echo "30" > ~/.cache/claude-usage/ntfy_status_interval   # minutes (0 = off)
```

### Notification Thresholds

Edit in the script:

```bash
# macOS
NOTIFY_THRESHOLDS="50 25 10"

# Windows
$script:NotifyThresholds = @(50, 25, 10)
```

---

## How It Works

```
Credentials ──→ Anthropic API ──→ Menu Bar / System Tray
(Keychain /      /api/oauth/usage    (render + notify)
 .json file)     (cached locally)
```

1. Reads your Claude Code OAuth token from your system (macOS Keychain / Windows credentials file)
2. Checks `api.anthropic.com/api/oauth/usage` for current usage
3. Caches the response locally to avoid hitting rate limits
4. Calculates remaining %, pace, and burnout projection
5. Renders in the menu bar / system tray
6. Sends alerts when thresholds are crossed
7. Falls back to cached data if the API is unavailable

---

## Security

- Your OAuth token **never leaves your machine** — it's only sent to Anthropic's servers
- No tokens are written to disk or logged
- The cache only stores usage percentages and reset times
- Phone alerts (ntfy) don't involve any tokens — just a topic name

---

## Troubleshooting

### macOS

| What you see | What's wrong | How to fix it |
|---|---|---|
| `CC: no auth` | Not logged into Claude Code | Run `claude` in terminal and log in |
| `CC: no token` | Keychain issue | Run `claude logout` then `claude` |
| `CC: error` | API error | Click **Open log** for details |
| `CC: 429` | Rate limited | Wait a few minutes — it backs off automatically |
| Widget not showing | SwiftBar not configured | Open SwiftBar → set folder to `~/SwiftBarPlugins` |

### Windows

| What you see | What's wrong | How to fix it |
|---|---|---|
| CMD window stays open | Outdated launcher | Update to latest version |
| No tray icon | Script not running | Run `launch-monitor.bat` |
| "No data" | Not logged into Claude Code | Run `claude` in terminal and log in |

### Stuck on 429?

This means you've been rate limited by Anthropic's API.

1. **Wait 5 minutes** — the plugin backs off automatically
2. **Still stuck?** Re-authenticate: `claude auth logout` → `claude auth login`
3. **Reduce refresh rate** — try 5m or 10m from the menu
4. **Last resort** — clear everything: `rm -rf ~/.cache/claude-usage` then re-authenticate and restart SwiftBar

### Logs

```bash
# macOS
tail -20 ~/.cache/claude-usage/plugin.log

# Windows
Get-Content ~\.cache\claude-usage\monitor.log -Tail 20
```

### Reset Cache

```bash
# macOS
rm -rf ~/.cache/claude-usage

# Windows
Remove-Item ~\.cache\claude-usage -Recurse -Force
```

The plugin recreates everything on the next run.

---

## Version History

| Version | What changed |
|---------|-------------|
| **v10.0** | Phone alerts via ntfy (optional, no API keys). Smart reset reminders that only nudge when you're idle. Configurable from dropdown menu. |
| **v9.2** | Auto-create helper scripts. Add MIT LICENSE. Fix jq detection. |
| **v9.0** | Fix rate limit death spiral. Configurable refresh rate. Dynamic cache TTL. |
| **v8.1** | Windows: fix CMD window staying open on launch. |
| **v8.0** | Windows feature parity: dual icons, pace/burnout, 6 languages, notifications. |
| **v7.0** | Pace indicator, burnout projection, notifications, multi-language. |
| **v6.0** | Null-safe 7-day, robust timezone parsing, multi-language. |
| **v5.0** | Initial release. |

## License

MIT
