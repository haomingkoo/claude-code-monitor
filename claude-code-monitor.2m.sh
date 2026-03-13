#!/bin/bash

# <xbar.title>Claude Code Usage</xbar.title>
# <xbar.version>v9.0</xbar.version>
# <xbar.author>koohaoming</xbar.author>
# <xbar.desc>Shows Claude Code remaining rate limits via OAuth endpoint</xbar.desc>

# ============================================================
# CONFIG
# ============================================================
CACHE_DIR="$HOME/.cache/claude-usage"
CACHE_FILE="$CACHE_DIR/usage.json"
LOG_FILE="$CACHE_DIR/plugin.log"
NOTIFY_STATE="$CACHE_DIR/notify_state"

# Language: saved in config file, changeable from dropdown menu
LANG_FILE="$CACHE_DIR/language"
if [ -f "$LANG_FILE" ]; then
  LANGUAGE=$(cat "$LANG_FILE")
else
  LANGUAGE="${LANGUAGE:-en}"
fi

# Refresh rate: saved in config file, changeable from dropdown menu
RATE_FILE="$CACHE_DIR/refresh_rate"
if [ -f "$RATE_FILE" ]; then
  REFRESH_RATE=$(cat "$RATE_FILE")
else
  REFRESH_RATE="2m"
fi

# Set CACHE_TTL based on refresh rate (minimum 120s to avoid API rate limits)
case "$REFRESH_RATE" in
  30s) CACHE_TTL=120 ;;
  1m)  CACHE_TTL=120 ;;
  2m)  CACHE_TTL=180 ;;
  5m)  CACHE_TTL=600 ;;
  10m) CACHE_TTL=900 ;;
  *)   CACHE_TTL=600 ;;
esac

# Notification thresholds (remaining %) — alerts when crossing below these
NOTIFY_THRESHOLDS="50 25 10"

mkdir -p "$CACHE_DIR"

# ============================================================
# TRANSLATIONS
# ============================================================
case "$LANGUAGE" in
  zh)
    L_SESSION_5H="5小时会话"; L_WINDOW_7D="7天窗口"; L_WINDOW_7D_OPUS="7天 Opus"
    L_REMAINING="剩余"; L_REFILLS="重置于"; L_BURNS="预计耗尽"
    L_RESETS_AT="重置时间"; L_PACE="速率"
    L_SOURCE="数据来源"; L_REFRESH="刷新"; L_OPEN_LOG="打开日志"
    L_NOT_AVAIL="暂无数据 — 使用后更新"; L_RATE_LIMITED="请求受限 — 请稍后再试"
    L_NO_AUTH="未登录 Claude Code"; L_NO_TOKEN="无法解析 OAuth 令牌"
    L_BAD_DATA="API 返回数据无效"; L_API_ERROR="API 错误"
    L_NEED_JQ="需要安装 jq"; L_INSTALL_JQ="安装 jq"
    L_NOTIFY_TITLE="Claude Code 用量警告"; L_REFRESH_RATE="刷新频率"
    fmt_remaining() { echo "${1}% $L_REMAINING"; }
    fmt_refills() { echo "$L_REFILLS ${1}"; }
    fmt_burns() { echo "$L_BURNS ~${1}"; }
    fmt_resets_at() { echo "$L_RESETS_AT: ${1}"; }
    fmt_pace() { echo "$L_PACE: ${1}x"; }
    fmt_notify() { echo "${1}: ${2}% $L_REMAINING"; }
    ;;
  ja)
    L_SESSION_5H="5時間セッション"; L_WINDOW_7D="7日間ウィンドウ"; L_WINDOW_7D_OPUS="7日間 Opus"
    L_REMAINING="残り"; L_REFILLS="リセットまで"; L_BURNS="消費予測"
    L_RESETS_AT="リセット時刻"; L_PACE="ペース"
    L_SOURCE="ソース"; L_REFRESH="更新"; L_OPEN_LOG="ログを開く"
    L_NOT_AVAIL="データなし — 使用後に更新されます"; L_RATE_LIMITED="レート制限中"
    L_NO_AUTH="Claude Code 未ログイン"; L_NO_TOKEN="OAuthトークン解析失敗"
    L_BAD_DATA="APIレスポンスが無効"; L_API_ERROR="APIエラー"
    L_NEED_JQ="jqが必要です"; L_INSTALL_JQ="jqをインストール"
    L_NOTIFY_TITLE="Claude Code 使用量警告"; L_REFRESH_RATE="更新頻度"
    fmt_remaining() { echo "$L_REMAINING ${1}%"; }
    fmt_refills() { echo "$L_REFILLS ${1}"; }
    fmt_burns() { echo "$L_BURNS ~${1}"; }
    fmt_resets_at() { echo "$L_RESETS_AT: ${1}"; }
    fmt_pace() { echo "$L_PACE: ${1}x"; }
    fmt_notify() { echo "${1}: $L_REMAINING ${2}%"; }
    ;;
  ko)
    L_SESSION_5H="5시간 세션"; L_WINDOW_7D="7일 윈도우"; L_WINDOW_7D_OPUS="7일 Opus"
    L_REMAINING="남음"; L_REFILLS="리셋까지"; L_BURNS="소진 예상"
    L_RESETS_AT="리셋 시각"; L_PACE="속도"
    L_SOURCE="소스"; L_REFRESH="새로고침"; L_OPEN_LOG="로그 열기"
    L_NOT_AVAIL="데이터 없음 — 사용 후 업데이트됩니다"; L_RATE_LIMITED="요청 제한 — 잠시 후 다시 시도"
    L_NO_AUTH="Claude Code 미로그인"; L_NO_TOKEN="OAuth 토큰 파싱 실패"
    L_BAD_DATA="API 응답 오류"; L_API_ERROR="API 오류"
    L_NEED_JQ="jq 필요"; L_INSTALL_JQ="jq 설치"
    L_NOTIFY_TITLE="Claude Code 사용량 경고"; L_REFRESH_RATE="새로고침 주기"
    fmt_remaining() { echo "${1}% $L_REMAINING"; }
    fmt_refills() { echo "$L_REFILLS ${1}"; }
    fmt_burns() { echo "$L_BURNS ~${1}"; }
    fmt_resets_at() { echo "$L_RESETS_AT: ${1}"; }
    fmt_pace() { echo "$L_PACE: ${1}x"; }
    fmt_notify() { echo "${1}: ${2}% $L_REMAINING"; }
    ;;
  ta)
    L_SESSION_5H="5-மணி அமர்வு"; L_WINDOW_7D="7-நாள் சாளரம்"; L_WINDOW_7D_OPUS="7-நாள் Opus"
    L_REMAINING="மீதம்"; L_REFILLS="மீட்டமைப்பு"; L_BURNS="தீர்ந்துவிடும்"
    L_RESETS_AT="மீட்டமைப்பு நேரம்"; L_PACE="வேகம்"
    L_SOURCE="மூலம்"; L_REFRESH="புதுப்பி"; L_OPEN_LOG="பதிவைத் திற"
    L_NOT_AVAIL="தரவு இல்லை — பயன்பாட்டிற்குப் பின் புதுப்பிக்கப்படும்"; L_RATE_LIMITED="வரம்பு — பின்னர் முயற்சிக்கவும்"
    L_NO_AUTH="Claude Code உள்நுழையவில்லை"; L_NO_TOKEN="OAuth டோக்கன் பிழை"
    L_BAD_DATA="API பதில் தவறானது"; L_API_ERROR="API பிழை"
    L_NEED_JQ="jq தேவை"; L_INSTALL_JQ="jq நிறுவு"
    L_NOTIFY_TITLE="Claude Code பயன்பாட்டு எச்சரிக்கை"; L_REFRESH_RATE="புதுப்பிப்பு வீதம்"
    fmt_remaining() { echo "${1}% $L_REMAINING"; }
    fmt_refills() { echo "$L_REFILLS ${1}"; }
    fmt_burns() { echo "$L_BURNS ~${1}"; }
    fmt_resets_at() { echo "$L_RESETS_AT: ${1}"; }
    fmt_pace() { echo "$L_PACE: ${1}x"; }
    fmt_notify() { echo "${1}: ${2}% $L_REMAINING"; }
    ;;
  ms)
    L_SESSION_5H="Sesi 5-Jam"; L_WINDOW_7D="Tetingkap 7-Hari"; L_WINDOW_7D_OPUS="7-Hari Opus"
    L_REMAINING="baki"; L_REFILLS="Ditetapkan dalam"; L_BURNS="Habis dalam"
    L_RESETS_AT="Masa tetapan"; L_PACE="Kadar"
    L_SOURCE="Sumber"; L_REFRESH="Muat semula"; L_OPEN_LOG="Buka log"
    L_NOT_AVAIL="Belum tersedia — dikemas kini selepas penggunaan"; L_RATE_LIMITED="Had kadar — cuba lagi nanti"
    L_NO_AUTH="Belum log masuk Claude Code"; L_NO_TOKEN="Tidak dapat menghurai token OAuth"
    L_BAD_DATA="Respons API tidak sah"; L_API_ERROR="Ralat API"
    L_NEED_JQ="Perlu jq"; L_INSTALL_JQ="Pasang jq"
    L_NOTIFY_TITLE="Amaran Penggunaan Claude Code"; L_REFRESH_RATE="Kadar muat semula"
    fmt_remaining() { echo "${1}% $L_REMAINING"; }
    fmt_refills() { echo "$L_REFILLS ${1}"; }
    fmt_burns() { echo "$L_BURNS ~${1}"; }
    fmt_resets_at() { echo "$L_RESETS_AT: ${1}"; }
    fmt_pace() { echo "$L_PACE: ${1}x"; }
    fmt_notify() { echo "${1}: ${2}% $L_REMAINING"; }
    ;;
  *)
    L_SESSION_5H="5-Hour Session"; L_WINDOW_7D="7-Day Window"; L_WINDOW_7D_OPUS="7-Day Opus"
    L_REMAINING="remaining"; L_REFILLS="Refills in"; L_BURNS="Burns out in"
    L_RESETS_AT="Resets at"; L_PACE="Pace"
    L_SOURCE="Source"; L_REFRESH="Refresh"; L_OPEN_LOG="Open log"
    L_NOT_AVAIL="Not available yet — updates after usage"; L_RATE_LIMITED="Rate limited — try again later"
    L_NO_AUTH="Not logged into Claude Code"; L_NO_TOKEN="Could not parse OAuth token"
    L_BAD_DATA="Invalid response from API"; L_API_ERROR="API error"
    L_NEED_JQ="Need jq"; L_INSTALL_JQ="Install jq"
    L_NOTIFY_TITLE="Claude Code Usage Warning"; L_REFRESH_RATE="Refresh Rate"
    fmt_remaining() { echo "${1}% $L_REMAINING"; }
    fmt_refills() { echo "$L_REFILLS ${1}"; }
    fmt_burns() { echo "$L_BURNS ~${1}"; }
    fmt_resets_at() { echo "$L_RESETS_AT ${1}"; }
    fmt_pace() { echo "$L_PACE: ${1}x"; }
    fmt_notify() { echo "${1}: ${2}% $L_REMAINING"; }
    ;;
esac

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
  echo "CC: $L_NEED_JQ"
  echo "---"
  echo "$L_INSTALL_JQ: brew install jq | bash='brew install jq' terminal=true"
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
  echo "$L_NO_AUTH | size=13"
  log "WARN" "No credentials in Keychain"
  exit 0
fi

TOKEN=$(echo "$CREDS" | $JQ -r '.claudeAiOauth.accessToken // empty' 2>/dev/null)
if [ -z "$TOKEN" ]; then
  echo "CC: no token"
  echo "---"
  echo "$L_NO_TOKEN | size=13"
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
      touch "$CACHE_FILE"  # refresh mtime so CACHE_TTL prevents further API calls
      USAGE=$(cat "$CACHE_FILE")
      FETCH_STATUS="rate limited — showing stale data"
    else
      echo "CC: 429"
      echo "---"
      echo "$L_RATE_LIMITED | size=13 color=#CC7700"
      echo "---"
      echo "$L_REFRESH | refresh=true size=13"
      exit 0
    fi
  else
    log "ERROR" "API call failed (HTTP $HTTP_CODE)"
    rm -f "$CACHE_FILE.tmp"
    if [ -f "$CACHE_FILE" ]; then
      touch "$CACHE_FILE"  # refresh mtime so CACHE_TTL prevents further API calls
      USAGE=$(cat "$CACHE_FILE")
      FETCH_STATUS="error (HTTP $HTTP_CODE) — showing stale data"
    else
      echo "CC: error"
      echo "---"
      echo "$L_API_ERROR (HTTP $HTTP_CODE) | size=13 color=#CC0000"
      echo "---"
      echo "$L_OPEN_LOG | bash='open' param1='$LOG_FILE' terminal=false size=13"
      echo "$L_REFRESH | refresh=true size=13"
      exit 0
    fi
  fi
fi

# Validate JSON
if ! echo "$USAGE" | $JQ -e '.five_hour' &>/dev/null; then
  log "ERROR" "Invalid JSON response"
  echo "CC: bad data"
  echo "---"
  echo "$L_BAD_DATA | size=13 color=#CC0000"
  echo "---"
  echo "$L_OPEN_LOG | bash='open' param1='$LOG_FILE' terminal=false size=13"
  echo "$L_REFRESH | refresh=true size=13"
  exit 0
fi

# ============================================================
# PARSE
# ============================================================
five_hr_used=$(echo "$USAGE" | $JQ -r 'if .five_hour then .five_hour.utilization // 0 else empty end')
five_hr_reset=$(echo "$USAGE" | $JQ -r 'if .five_hour then .five_hour.resets_at // empty else empty end')
seven_day_used=$(echo "$USAGE" | $JQ -r 'if .seven_day then .seven_day.utilization // 0 else empty end')
seven_day_reset=$(echo "$USAGE" | $JQ -r 'if .seven_day then .seven_day.resets_at // empty else empty end')
opus_used=$(echo "$USAGE" | $JQ -r 'if .seven_day_opus then .seven_day_opus.utilization // empty else empty end')
opus_reset=$(echo "$USAGE" | $JQ -r 'if .seven_day_opus then .seven_day_opus.resets_at // empty else empty end')

calc_remaining() {
  echo "scale=1; 100 - $1" | bc
}

five_hr_left=$(calc_remaining "${five_hr_used:-0}")

HAS_SEVEN_DAY=true
if [ -z "$seven_day_used" ]; then
  HAS_SEVEN_DAY=false
  seven_day_left=""
else
  seven_day_left=$(calc_remaining "$seven_day_used")
fi

log "INFO" "5h: ${five_hr_left}% left | 7d: ${seven_day_left:-N/A}% left | source: $FETCH_STATUS"

# ============================================================
# THEME
# ============================================================
DARK_MODE=$(defaults read -g AppleInterfaceStyle 2>/dev/null)
if [ "$DARK_MODE" = "Dark" ]; then
  TEXT_PRIMARY="#EEEEEE"
  TEXT_SECONDARY="#BBBBBB"
  TEXT_MUTED="#888888"
  COLOR_GREEN="#2ECC71"
  COLOR_ORANGE="#E67E22"
  COLOR_RED="#E74C3C"
  BAR_FILLED_GREEN="#27AE60"
  BAR_FILLED_ORANGE="#D35400"
  BAR_FILLED_RED="#C0392B"
  BAR_EMPTY="#444444"
else
  TEXT_PRIMARY="#2a2a2a"
  TEXT_SECONDARY="#2a2a2a"
  TEXT_MUTED="#2a2a2a"
  COLOR_GREEN="#004D2C"
  COLOR_ORANGE="#8B4000"
  COLOR_RED="#8B0000"
  BAR_FILLED_GREEN="#004D2C"
  BAR_FILLED_ORANGE="#8B4000"
  BAR_FILLED_RED="#8B0000"
  BAR_EMPTY="#999999"
fi

# Helper: only emit "color=X" when X is non-empty; omitting lets macOS use native text color
c() { [ -n "$1" ] && echo "color=$1" || echo ""; }

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

# ============================================================
# TIME HELPERS
# ============================================================
format_duration() {
  local diff="$1"
  if [ "$diff" -le 0 ] 2>/dev/null; then
    echo ""
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

parse_reset_epoch() {
  local reset_ts="$1"
  if [ -z "$reset_ts" ] || [ "$reset_ts" = "null" ]; then
    echo ""
    return
  fi
  # Try python3 first — handles any ISO 8601 timezone correctly
  if command -v python3 &>/dev/null; then
    local epoch=$(python3 -c "
from datetime import datetime, timezone
ts = '$reset_ts'
dt = datetime.fromisoformat(ts)
print(int(dt.astimezone(timezone.utc).timestamp()))
" 2>/dev/null)
    if [ -n "$epoch" ]; then
      echo "$epoch"
      return
    fi
  fi
  # macOS fallback: strip offset, parse as UTC (works if API returns +00:00/Z)
  local clean_ts=$(echo "$reset_ts" | sed 's/\.[0-9]*//; s/[+-][0-9][0-9]:[0-9][0-9]$//; s/Z$//')
  local epoch=$(date -j -u -f "%Y-%m-%dT%H:%M:%S" "$clean_ts" "+%s" 2>/dev/null)
  if [ -n "$epoch" ]; then
    echo "$epoch"
    return
  fi
  # Nothing worked
  log "WARN" "Could not parse timestamp: $reset_ts"
  echo ""
}

format_reset() {
  local reset_ts="$1"
  local epoch=$(parse_reset_epoch "$reset_ts")
  if [ -z "$epoch" ]; then
    echo ""
    return
  fi
  local now=$(date "+%s")
  local diff=$((epoch - now))
  format_duration "$diff"
}

# Convert reset timestamp to local time string (e.g., "3:49 PM" or "Mar 15 3:49 PM")
format_local_reset_time() {
  local reset_ts="$1"
  local epoch=$(parse_reset_epoch "$reset_ts")
  if [ -z "$epoch" ]; then
    echo ""
    return
  fi
  local now=$(date "+%s")
  local diff=$((epoch - now))
  if [ "$diff" -le 0 ]; then
    echo ""
    return
  fi
  # If reset is today, show just time; if another day, include date
  local reset_date=$(date -r "$epoch" "+%Y-%m-%d" 2>/dev/null)
  local today=$(date "+%Y-%m-%d")
  if [ "$reset_date" = "$today" ]; then
    date -r "$epoch" "+%I:%M %p" 2>/dev/null | sed 's/^0//'
  else
    date -r "$epoch" "+%b %d %I:%M %p" 2>/dev/null | sed 's/  / /g; s/ 0/ /g'
  fi
}

# Project when tokens will run out based on current burn rate
format_burnout() {
  local utilization="$1"
  local reset_ts="$2"
  local window_seconds="$3"

  local used_int=${utilization%.*}
  if [ "$used_int" -le 0 ] 2>/dev/null; then
    echo ""
    return
  fi

  local reset_epoch=$(parse_reset_epoch "$reset_ts")
  if [ -z "$reset_epoch" ]; then
    echo ""
    return
  fi

  local now=$(date "+%s")
  local secs_until_reset=$((reset_epoch - now))
  if [ "$secs_until_reset" -le 0 ]; then
    echo ""
    return
  fi

  local elapsed=$((window_seconds - secs_until_reset))
  if [ "$elapsed" -le 0 ]; then
    echo ""
    return
  fi

  # seconds until 100% = (100 - utilization) * elapsed / utilization
  local remaining=$(echo "scale=1; 100 - $utilization" | bc)
  local remaining_int=${remaining%.*}
  if [ "$remaining_int" -le 0 ] 2>/dev/null; then
    echo "now"
    return
  fi

  local secs_to_burnout=$(echo "scale=0; $remaining * $elapsed / $utilization" | bc)
  local burnout_str=$(format_duration "$secs_to_burnout")
  if [ -n "$burnout_str" ]; then
    echo "$burnout_str"
  fi
}

# Calculate pace: how fast you're burning vs sustainable linear rate
# Returns: multiplier (e.g., "1.5" means 1.5x faster than sustainable)
calc_pace() {
  local utilization="$1"
  local reset_ts="$2"
  local window_seconds="$3"

  local used_int=${utilization%.*}
  if [ "$used_int" -le 0 ] 2>/dev/null; then
    echo ""
    return
  fi

  local reset_epoch=$(parse_reset_epoch "$reset_ts")
  if [ -z "$reset_epoch" ]; then
    echo ""
    return
  fi

  local now=$(date "+%s")
  local secs_until_reset=$((reset_epoch - now))
  if [ "$secs_until_reset" -le 0 ]; then
    echo ""
    return
  fi

  local elapsed=$((window_seconds - secs_until_reset))
  if [ "$elapsed" -le 0 ]; then
    echo ""
    return
  fi

  # ideal usage at this point = (elapsed / window) * 100
  # pace = actual / ideal
  local pace=$(echo "scale=1; ($utilization * $window_seconds) / (100 * $elapsed)" | bc)
  # Ensure leading zero (bc outputs ".5" not "0.5")
  case "$pace" in
    .*) pace="0${pace}" ;;
  esac
  echo "$pace"
}

pace_icon() {
  local pace="$1"
  # Compare as integers (pace * 10) to avoid float issues in bash
  local pace_x10=$(echo "scale=0; $pace * 10 / 1" | bc)
  if [ "$pace_x10" -ge 20 ]; then
    echo "🔥"  # >2x — burning way too fast
  elif [ "$pace_x10" -ge 13 ]; then
    echo "⚡"  # >1.3x — faster than sustainable
  elif [ "$pace_x10" -ge 8 ]; then
    echo "✅"  # 0.8-1.3x — on pace
  else
    echo "🐢"  # <0.8x — conservative
  fi
}

# ============================================================
# NOTIFICATIONS
# ============================================================
check_and_notify() {
  local label="$1"
  local remaining="$2"
  local key="$3"  # unique key for this window (e.g., "5h" or "7d")

  local remaining_int=${remaining%.*}
  local state_file="${NOTIFY_STATE}_${key}"

  # Read last notified threshold
  local last_threshold=100
  if [ -f "$state_file" ]; then
    last_threshold=$(cat "$state_file" 2>/dev/null)
    # Reset if usage has recovered above the last threshold (window reset)
    if [ "$remaining_int" -gt "$last_threshold" ] 2>/dev/null; then
      last_threshold=100
      echo "100" > "$state_file"
    fi
  fi

  for threshold in $NOTIFY_THRESHOLDS; do
    if [ "$remaining_int" -le "$threshold" ] && [ "$last_threshold" -gt "$threshold" ] 2>/dev/null; then
      # Crossed below this threshold — notify
      local msg=$(fmt_notify "$label" "$remaining_int")
      osascript -e "display notification \"$msg\" with title \"$L_NOTIFY_TITLE\" sound name \"Funk\"" 2>/dev/null
      echo "$threshold" > "$state_file"
      log "INFO" "Notification sent: $label at ${remaining_int}% (threshold: ${threshold}%)"
      return
    fi
  done
}

# ============================================================
# RENDER
# ============================================================
five_hr_left_int=${five_hr_left%.*}

five_color=$(color_for_remaining "$five_hr_left")

S=14  # base font size

# Menu bar
bar_icon=$(status_icon "$five_hr_left_int")
if [ "$HAS_SEVEN_DAY" = true ]; then
  seven_day_left_int=${seven_day_left%.*}
  seven_color=$(color_for_remaining "$seven_day_left")
  echo "${bar_icon} ${five_hr_left_int}% · 7d:${seven_day_left_int}% | size=13"
else
  echo "${bar_icon} ${five_hr_left_int}% · 7d:N/A | size=13"
fi
echo "---"

# Header
SUB_TYPE=$(echo "$CREDS" | $JQ -r '.claudeAiOauth.subscriptionType // "unknown"' 2>/dev/null)
echo "Claude Code (${SUB_TYPE}) | size=$S $(c "$TEXT_PRIMARY") bash='true' terminal=false"
echo "---"

# Section renderer
render_section() {
  local label="$1"
  local left="$2"
  local color="$3"
  local reset_ts="$4"
  local window_secs="$5"
  local utilization="$6"
  local available="$7"  # "true" or "false"

  # bash='true' on info lines forces macOS to render at full opacity (not vibrancy-faded)
  local NOP="bash='true' terminal=false"

  if [ "$available" = "false" ]; then
    echo "⚪  ${label} | size=$S $(c "$TEXT_MUTED") $NOP"
    echo "$L_NOT_AVAIL | size=$S $(c "$TEXT_MUTED") $NOP"
    return
  fi

  local icon=$(status_icon "$left")
  local bar=$(progress_bar "$left")
  local reset_str=$(format_reset "$reset_ts")
  local local_time=$(format_local_reset_time "$reset_ts")
  local bar_col=$(bar_color_for_remaining "$left")

  echo "${icon}  ${label} | size=$S $(c "$TEXT_PRIMARY") $NOP"
  echo "${bar} | size=$S font=Menlo color=${bar_col} $NOP"
  echo "$(fmt_remaining "$left") | size=$S color=$color $NOP"

  # Refill countdown + local reset time
  if [ -n "$reset_str" ] && [ -n "$local_time" ]; then
    echo "$(fmt_refills "$reset_str") (${local_time}) | size=$S $(c "$TEXT_SECONDARY") $NOP"
  elif [ -n "$reset_str" ]; then
    echo "$(fmt_refills "$reset_str") | size=$S $(c "$TEXT_SECONDARY") $NOP"
  fi

  # Pace indicator + burnout projection
  if [ -n "$window_secs" ] && [ -n "$utilization" ]; then
    local pace=$(calc_pace "$utilization" "$reset_ts" "$window_secs")
    if [ -n "$pace" ]; then
      local picon=$(pace_icon "$pace")
      echo "${picon} $(fmt_pace "$pace") | size=$S $(c "$TEXT_SECONDARY") $NOP"
    fi

    local burnout=$(format_burnout "$utilization" "$reset_ts" "$window_secs")
    if [ -n "$burnout" ]; then
      echo "$(fmt_burns "$burnout") | size=$S $(c "$TEXT_SECONDARY") $NOP"
    fi
  fi
}

render_section "$L_SESSION_5H" "$five_hr_left" "$five_color" "$five_hr_reset" "18000" "$five_hr_used" "true"
echo "---"

if [ "$HAS_SEVEN_DAY" = true ]; then
  render_section "$L_WINDOW_7D" "$seven_day_left" "$seven_color" "$seven_day_reset" "604800" "$seven_day_used" "true"
else
  render_section "$L_WINDOW_7D" "" "" "" "" "" "false"
fi

if [ -n "$opus_used" ] && [ "$opus_used" != "null" ]; then
  echo "---"
  opus_left=$(calc_remaining "$opus_used")
  opus_color=$(color_for_remaining "$opus_left")
  render_section "$L_WINDOW_7D_OPUS" "$opus_left" "$opus_color" "$opus_reset" "604800" "$opus_used" "true"
fi

echo "---"
echo "$L_SOURCE: ${FETCH_STATUS} | size=$S $(c "$TEXT_SECONDARY") bash='true' terminal=false"
echo "---"
echo "$L_REFRESH | refresh=true $(c "$TEXT_SECONDARY") size=$S"
echo "$L_OPEN_LOG | bash='open' param1='$LOG_FILE' terminal=false $(c "$TEXT_SECONDARY") size=$S"
echo "---"
# Refresh rate — flyout submenu
RD="$HOME/.cache/claude-usage/scripts"
rate_mark() { [ "$REFRESH_RATE" = "$1" ] && echo "✓ " || echo ""; }
echo "⏱ $L_REFRESH_RATE: ${REFRESH_RATE} | size=$S $(c "$TEXT_SECONDARY")"
echo "--$(rate_mark 30s)30s | bash='$RD/set-rate-30s.sh' terminal=false refresh=true size=$S"
echo "--$(rate_mark 1m)1m | bash='$RD/set-rate-1m.sh' terminal=false refresh=true size=$S"
echo "--$(rate_mark 2m)2m | bash='$RD/set-rate-2m.sh' terminal=false refresh=true size=$S"
echo "--$(rate_mark 5m)5m | bash='$RD/set-rate-5m.sh' terminal=false refresh=true size=$S"
echo "--$(rate_mark 10m)10m | bash='$RD/set-rate-10m.sh' terminal=false refresh=true size=$S"
# Language — flyout submenu
lang_mark() { [ "$LANGUAGE" = "$1" ] && echo "✓ " || echo ""; }
LD="$HOME/.cache/claude-usage/scripts"
echo "🌐 Language | size=$S $(c "$TEXT_SECONDARY")"
echo "--$(lang_mark en)English | bash='$LD/set-lang-en.sh' terminal=false refresh=true size=$S"
echo "--$(lang_mark zh)中文 | bash='$LD/set-lang-zh.sh' terminal=false refresh=true size=$S"
echo "--$(lang_mark ja)日本語 | bash='$LD/set-lang-ja.sh' terminal=false refresh=true size=$S"
echo "--$(lang_mark ko)한국어 | bash='$LD/set-lang-ko.sh' terminal=false refresh=true size=$S"
echo "--$(lang_mark ta)தமிழ் | bash='$LD/set-lang-ta.sh' terminal=false refresh=true size=$S"
echo "--$(lang_mark ms)Bahasa Melayu | bash='$LD/set-lang-ms.sh' terminal=false refresh=true size=$S"

# ============================================================
# NOTIFICATIONS (run after render so UI updates immediately)
# ============================================================
check_and_notify "$L_SESSION_5H" "$five_hr_left" "5h"
if [ "$HAS_SEVEN_DAY" = true ]; then
  check_and_notify "$L_WINDOW_7D" "$seven_day_left" "7d"
fi
