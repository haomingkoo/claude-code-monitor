#!/bin/sh
# Helper: write language preference and trigger SwiftBar refresh
LOG="$HOME/.cache/claude-usage/plugin.log"
mkdir -p "$HOME/.cache/claude-usage"
echo "$(date '+%Y-%m-%d %H:%M:%S') [LANG] set-language.sh called with: '$1'" >> "$LOG"
echo "$1" > "$HOME/.cache/claude-usage/language"
sync
echo "$(date '+%Y-%m-%d %H:%M:%S') [LANG] wrote '$1' to language file, contents: $(cat $HOME/.cache/claude-usage/language)" >> "$LOG"
sleep 0.5
open -g "swiftbar://refreshplugin?name=claude-code-monitor"
echo "$(date '+%Y-%m-%d %H:%M:%S') [LANG] refresh triggered" >> "$LOG"
