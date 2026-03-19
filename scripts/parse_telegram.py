#!/usr/bin/env python3
"""Parse Telegram getUpdates response and emit shell variables for the receiver workflow."""
import json
import os
import sys
import base64

with open('/tmp/telegram-updates.json') as f:
    try:
        data = json.load(f)
    except json.JSONDecodeError:
        print("NEW_LAST_ID=" + os.environ.get('LAST_ID', '0'))
        print("COMMANDS_B64=")
        sys.exit(0)

authorized = str(os.environ.get('TELEGRAM_CHAT_ID', ''))
results = data.get('result', [])
commands = []
max_id = int(os.environ.get('LAST_ID', '0'))

for update in results:
    uid = update.get('update_id', 0)
    if uid > max_id:
        max_id = uid
    msg = update.get('message', {})
    chat_id = str(msg.get('chat', {}).get('id', ''))
    text = msg.get('text', '').strip()
    if chat_id == authorized and text:
        commands.append(text)

print("NEW_LAST_ID=" + str(max_id))
lines = '\n'.join(commands)
encoded = base64.b64encode(lines.encode()).decode()
print("COMMANDS_B64=" + encoded)
