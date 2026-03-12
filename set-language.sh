#!/bin/sh
# Helper: write language preference and trigger SwiftBar refresh
echo "$1" > "$HOME/.cache/claude-usage/language"
sleep 0.3
open -g "swiftbar://refreshplugin?name=claude-code-monitor"
