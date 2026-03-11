#!/bin/bash

# <xbar.title>Claude Code Usage</xbar.title>
# <xbar.version>v5.0</xbar.version>
# <xbar.author>koohaoming</xbar.author>
# <xbar.desc>Shows Claude Code remaining rate limits via OAuth endpoint</xbar.desc>

# ============================================================
# CONFIG
# ============================================================
CACHE_DIR="$HOME/.cache/claude-usage"
CACHE_FILE="$CACHE_DIR/usage.json"
LOG_FILE="$CACHE_DIR/plugin.log"
CACHE_TTL=120  # seconds — don't call API if cache is fresher than this

mkdir -p "$CACHE_DIR"

# ============================================================
# LOGGING
# ============================================================
log() {
  echo "$(date '+%Y-%m-%d %H:%M:%S') [$1] $2" >> "$LOG_FILE"
}

# Keep log file under 200 lines
if [ -f "$LOG_FILE" ] && [ "$(wc -l < "$LOG_FILE")" -gt 200 ]; then
  tail -100 "$LOG_FILE" > "$LOG_FILE.tmp" && mv "$LOG_FILE.tmp" "$LOG_FILE"
fi

log "INFO" "Plugin run started"

# ============================================================
# DEPENDENCIES
# ============================================================
if ! command -v /opt/homebrew/bin/jq &>/dev/null && ! command -v /usr/local/bin/jq &>/dev/null; then
  echo "CC: need jq"
  echo "---"
  echo "Install jq: brew install jq | bash='brew install jq' terminal=true"
  log "ERROR" "jq not found"
  exit 0
fi
JQ=$(/opt/homebrew/bin/jq 2>/dev/null && echo /opt/homebrew/bin/jq || echo /usr/local/bin/jq)

# ============================================================
# AUTH
# ============================================================
CREDS=$(security find-generic-password -s "Claude Code-credentials" -w 2>/dev/null)
if [ -z "$CREDS" ]; then
  echo "CC: no auth"
  echo "---"
  echo "Not logged into Claude Code | size=13"
  log "WARN" "No credentials in Keychain"
  exit 0
fi

TOKEN=$(echo "$CREDS" | $JQ -r '.claudeAiOauth.accessToken // empty' 2>/dev/null)
if [ -z "$TOKEN" ]; then
  echo "CC: no token"
  echo "---"
  echo "Could not parse OAuth token | size=13"
  log "ERROR" "Failed to parse accessToken from credentials"
  exit 0
fi

# ============================================================
# FETCH WITH CACHE
# ============================================================
USE_CACHE=false

if [ -f "$CACHE_FILE" ]; then
  cache_age=$(( $(date +%s) - $(stat -f %m "$CACHE_FILE") ))
  if [ "$cache_age" -lt "$CACHE_TTL" ]; then
    USE_CACHE=true
    log "INFO" "Using cache (age: ${cache_age}s)"
  fi
fi

if [ "$USE_CACHE" = true ]; then
  USAGE=$(cat "$CACHE_FILE")
  FETCH_STATUS="cached (${cache_age}s ago)"
else
  HTTP_CODE=$(curl -s -o "$CACHE_FILE.tmp" -w "%{http_code}" --max-time 10 \
    -H "Accept: application/json" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $TOKEN" \
    -H "anthropic-beta: oauth-2025-04-20" \
    "https://api.anthropic.com/api/oauth/usage" 2>/dev/null)

  if [ "$HTTP_CODE" = "200" ]; then
    mv "$CACHE_FILE.tmp" "$CACHE_FILE"
    USAGE=$(cat "$CACHE_FILE")
    FETCH_STATUS="live"
    log "INFO" "API call success (HTTP $HTTP_CODE)"
  elif [ "$HTTP_CODE" = "429" ]; then
    log "WARN" "Rate limited (HTTP 429) — using stale cache"
    rm -f "$CACHE_FILE.tmp"
    if [ -f "$CACHE_FILE" ]; then
      USAGE=$(cat "$CACHE_FILE")
      FETCH_STATUS="rate limited — showing stale data"
    else
      echo "CC: 429"
      echo "---"
      echo "Rate limited — try again later | size=13 color=#CC7700"
      echo "---"
      echo "Refresh | refresh=true size=13"
      exit 0
    fi
  else
    log "ERROR" "API call failed (HTTP $HTTP_CODE)"
    rm -f "$CACHE_FILE.tmp"
    if [ -f "$CACHE_FILE" ]; then
      USAGE=$(cat "$CACHE_FILE")
      FETCH_STATUS="error (HTTP $HTTP_CODE) — showing stale data"
    else
      echo "CC: error"
      echo "---"
      echo "API error (HTTP $HTTP_CODE) | size=13 color=#CC0000"
      echo "---"
      echo "Open log | bash='open' param1='$LOG_FILE' terminal=false size=13"
      echo "Refresh | refresh=true size=13"
      exit 0
    fi
  fi
fi

# Validate JSON
if ! echo "$USAGE" | $JQ -e '.five_hour' &>/dev/null; then
  log "ERROR" "Invalid JSON response"
  echo "CC: bad data"
  echo "---"
  echo "Invalid response from API | size=13 color=#CC0000"
  echo "---"
  echo "Open log | bash='open' param1='$LOG_FILE' terminal=false size=13"
  echo "Refresh | refresh=true size=13"
  exit 0
fi

# ============================================================
# PARSE
# ============================================================
five_hr_used=$(echo "$USAGE" | $JQ -r '.five_hour.utilization // 0')
five_hr_reset=$(echo "$USAGE" | $JQ -r '.five_hour.resets_at // empty')
seven_day_used=$(echo "$USAGE" | $JQ -r '.seven_day.utilization // 0')
seven_day_reset=$(echo "$USAGE" | $JQ -r '.seven_day.resets_at // empty')
opus_used=$(echo "$USAGE" | $JQ -r '.seven_day_opus.utilization // empty')
opus_reset=$(echo "$USAGE" | $JQ -r '.seven_day_opus.resets_at // empty')

calc_remaining() {
  echo "scale=1; 100 - $1" | bc
}

five_hr_left=$(calc_remaining "$five_hr_used")
seven_day_left=$(calc_remaining "$seven_day_used")

log "INFO" "5h: ${five_hr_left}% left | 7d: ${seven_day_left}% left | source: $FETCH_STATUS"

# ============================================================
# THEME
# ============================================================
DARK_MODE=$(defaults read -g AppleInterfaceStyle 2>/dev/null)
if [ "$DARK_MODE" = "Dark" ]; then
  TEXT_PRIMARY="#EEEEEE"
  TEXT_SECONDARY="#BBBBBB"
  COLOR_GREEN="#2ECC71"
  COLOR_ORANGE="#E67E22"
  COLOR_RED="#E74C3C"
  BAR_FILLED_GREEN="#27AE60"
  BAR_FILLED_ORANGE="#D35400"
  BAR_FILLED_RED="#C0392B"
  BAR_EMPTY="#444444"
else
  TEXT_PRIMARY="#1a1a1a"
  TEXT_SECONDARY="#555555"
  COLOR_GREEN="#006B3F"
  COLOR_ORANGE="#B45309"
  COLOR_RED="#B91C1C"
  BAR_FILLED_GREEN="#006B3F"
  BAR_FILLED_ORANGE="#B45309"
  BAR_FILLED_RED="#B91C1C"
  BAR_EMPTY="#CCCCCC"
fi

color_for_remaining() {
  local r=${1%.*}
  if [ "$r" -le 20 ]; then
    echo "$COLOR_RED"
  elif [ "$r" -le 50 ]; then
    echo "$COLOR_ORANGE"
  else
    echo "$COLOR_GREEN"
  fi
}

bar_color_for_remaining() {
  local r=${1%.*}
  if [ "$r" -le 20 ]; then
    echo "$BAR_FILLED_RED"
  elif [ "$r" -le 50 ]; then
    echo "$BAR_FILLED_ORANGE"
  else
    echo "$BAR_FILLED_GREEN"
  fi
}

progress_bar() {
  local pct=${1%.*}
  local width=20
  local filled=$(( (pct * width) / 100 ))
  local empty=$((width - filled))
  local bar=""
  for ((i=0; i<filled; i++)); do bar+="■"; done
  for ((i=0; i<empty; i++)); do bar+="□"; done
  echo "$bar"
}

status_icon() {
  local r=${1%.*}
  if [ "$r" -le 20 ]; then
    echo "🔴"
  elif [ "$r" -le 50 ]; then
    echo "🟡"
  else
    echo "🟢"
  fi
}

format_reset() {
  local reset_ts="$1"
  if [ -z "$reset_ts" ] || [ "$reset_ts" = "null" ]; then
    echo ""
    return
  fi
  local reset_epoch=$(date -j -f "%Y-%m-%dT%H:%M:%S" "${reset_ts%%.*}" "+%s" 2>/dev/null)
  if [ -z "$reset_epoch" ]; then
    echo ""
    return
  fi
  local now=$(date "+%s")
  local diff=$((reset_epoch - now))
  if [ "$diff" -le 0 ]; then
    echo "soon"
    return
  fi
  local days=$((diff / 86400))
  local hours=$(( (diff % 86400) / 3600 ))
  local mins=$(( (diff % 3600) / 60 ))
  if [ "$days" -gt 0 ]; then
    echo "${days}d ${hours}h"
  elif [ "$hours" -gt 0 ]; then
    echo "${hours}h ${mins}m"
  else
    echo "${mins}m"
  fi
}

# ============================================================
# RENDER
# ============================================================
five_hr_left_int=${five_hr_left%.*}
seven_day_left_int=${seven_day_left%.*}

five_color=$(color_for_remaining "$five_hr_left")
seven_color=$(color_for_remaining "$seven_day_left")

# Menu bar — always show 5-hour session (what you're actively using)
S=14  # base font size

bar_icon=$(status_icon "$five_hr_left_int")
echo "${bar_icon} ${five_hr_left_int}% · 7d:${seven_day_left_int}% | size=13"
echo "---"

# Header
SUB_TYPE=$(echo "$CREDS" | $JQ -r '.claudeAiOauth.subscriptionType // "unknown"' 2>/dev/null)
echo "Claude Code (${SUB_TYPE}) | size=$S color=$TEXT_PRIMARY"
echo "---"

# Section renderer
render_section() {
  local label="$1"
  local left="$2"
  local color="$3"
  local reset_ts="$4"

  local icon=$(status_icon "$left")
  local bar=$(progress_bar "$left")
  local reset_str=$(format_reset "$reset_ts")
  local bar_col=$(bar_color_for_remaining "$left")

  echo "${icon}  ${label} | size=$S color=$TEXT_PRIMARY"
  echo "${bar} | size=$S font=Menlo color=${bar_col}"
  echo "${left}% remaining | size=$S color=$color"
  if [ -n "$reset_str" ]; then
    echo "Refills in ${reset_str} | size=$S color=$TEXT_SECONDARY"
  fi
}

render_section "5-Hour Session" "$five_hr_left" "$five_color" "$five_hr_reset"
echo "---"
render_section "7-Day Window" "$seven_day_left" "$seven_color" "$seven_day_reset"

if [ -n "$opus_used" ] && [ "$opus_used" != "null" ]; then
  echo "---"
  opus_left=$(calc_remaining "$opus_used")
  opus_color=$(color_for_remaining "$opus_left")
  render_section "7-Day Opus" "$opus_left" "$opus_color" "$opus_reset"
fi

echo "---"
echo "Source: ${FETCH_STATUS} | size=$S color=$TEXT_SECONDARY"
echo "---"
echo "Refresh | refresh=true color=$TEXT_SECONDARY size=$S"
echo "Open log | bash='open' param1='$LOG_FILE' terminal=false color=$TEXT_SECONDARY size=$S"
