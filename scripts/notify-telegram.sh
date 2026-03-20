#!/usr/bin/env bash
# notify-telegram.sh — Send a Telegram message via Bot API
#
# Required env vars:
#   TELEGRAM_BOT_TOKEN  — bot token from BotFather
#   TELEGRAM_CHAT_ID    — recipient chat ID
#
# Usage: ./scripts/notify-telegram.sh "Your message here"

set -euo pipefail

MESSAGE="${1:-}"
if [[ -z "$MESSAGE" ]]; then
  echo "Usage: $0 \"message\"" >&2
  exit 1
fi

TOKEN="${TELEGRAM_BOT_TOKEN:-}"
CHAT_ID="${TELEGRAM_CHAT_ID:-}"
TIMEOUT="${TELEGRAM_TIMEOUT:-10}"

if [[ -z "$TOKEN" || -z "$CHAT_ID" ]]; then
  echo "⚠️  TELEGRAM_BOT_TOKEN or TELEGRAM_CHAT_ID not set — skipping notification." >&2
  echo "   Message would have been: $MESSAGE" >&2
  exit 0
fi

# Use python3 to safely build JSON payload (handles special characters)
PAYLOAD=$(python3 -c "
import json, os, sys
print(json.dumps({'chat_id': os.environ['TELEGRAM_CHAT_ID'], 'text': sys.argv[1]}))
" "$MESSAGE")

HTTP_STATUS=$(curl -s -o /tmp/tg-response.json -w "%{http_code}" \
  --max-time "$TIMEOUT" \
  -X POST \
  -H "Content-Type: application/json" \
  -d "$PAYLOAD" \
  "https://api.telegram.org/bot${TOKEN}/sendMessage")

if [[ "$HTTP_STATUS" -ge 200 && "$HTTP_STATUS" -lt 300 ]]; then
  echo "✅ Telegram notification sent (HTTP $HTTP_STATUS)"
  exit 0
else
  echo "❌ Telegram notification failed (HTTP $HTTP_STATUS)" >&2
  cat /tmp/tg-response.json >&2
  exit 1
fi
