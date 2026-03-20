# claude-queue

AI-powered issue implementation queue for GitHub repos, controlled via Telegram. Send a message, get a PR.

Built on [Claude Code](https://github.com/anthropics/claude-code) + GitHub Actions.

## How it works

1. You send `queue 42 43 44` to your Telegram bot
2. The bot adds those issue numbers to `QUEUE.md` in your repo
3. A GitHub Actions workflow picks them up one by one, runs Claude Code to implement each, creates a PR, and notifies you
4. You review and reply `merge 42` — bot merges and moves to the next issue

## Setup

### 1. Add secrets to your repo

Go to **Settings → Secrets → Actions** and add:

| Secret | Description |
|--------|-------------|
| `ANTHROPIC_API_KEY` | Your Anthropic API key |
| `TELEGRAM_BOT_TOKEN` | Bot token from [@BotFather](https://t.me/BotFather) |
| `TELEGRAM_CHAT_ID` | Your chat ID (see below) |
| `GH_PAT` | GitHub Personal Access Token with `repo` + `actions:write` scopes |
| `FLY_API_TOKEN` | *(Optional)* Fly.io API token, only needed if using deploy hooks |

**Getting your chat ID:** Message your bot, then visit:
```
https://api.telegram.org/bot<BOT_TOKEN>/getUpdates
```
Look for `"chat": {"id": <YOUR_CHAT_ID>}`.

### 2. Add workflow files to your repo

Copy the three files from [`examples/`](examples/) into your repo's `.github/workflows/`:

```
.github/workflows/
├── queue-processor.yml    ← copy from examples/
├── implement-issue.yml    ← copy from examples/
└── telegram-receiver.yml  ← copy from examples/
```

Each example file is a thin wrapper that calls the shared logic in this repo via `workflow_call` and passes secrets through with `secrets: inherit`.

### 3. Add QUEUE.md

Create a `QUEUE.md` at your repo root:

```markdown
# Agent Issue Queue

## Queue

<!-- Add issues below — one per line, highest priority first -->
```

### 4. Customize the implement prompt (optional)

By default, claude-queue uses [`prompts/implement-default.txt`](prompts/implement-default.txt) — a generic prompt that works for most projects.

To customize for your project, create `.github/prompts/implement.txt` in your repo. Reference your own docs, conventions, and rules. claude-queue will automatically use your file if it exists.

### 5. Add project hooks (optional)

To enable the `deploy`, `staging`, and `health` Telegram commands, create `scripts/claude-queue-hooks.sh` in your repo and define one or more of these shell functions:

```bash
deploy_production() {
  # your production deploy logic here
  fly deploy --app my-app
}

deploy_staging() {
  # your staging deploy logic here
  fly deploy --app my-app-staging
}

health_check() {
  # return health status as a string
  curl -sf https://my-app.fly.dev/healthz && echo "healthy" || echo "unhealthy"
}

staging_health_check() {
  curl -sf https://my-app-staging.fly.dev/healthz && echo "healthy" || echo "unhealthy"
}
```

The hooks file is sourced at the start of every Telegram receiver run. Only define the functions you need — undefined commands will respond with a helpful error.

## Telegram commands

| Command | Description |
|---------|-------------|
| `queue 42 43 44` | Add issues to the queue |
| `queue` | Trigger the queue runner immediately |
| `merge 42` | Merge PR #42 and advance the queue |
| `rev 42` | Re-review and fix PR #42 |
| `implement 42` | Implement a single issue outside the queue |
| `status` | Show queue status (pending/done/next) |
| `pause` | Pause the queue |
| `resume` | Resume the queue |
| `deploy` | Deploy to production (requires hook) |
| `staging` | Deploy to staging (requires hook) |
| `health` | Check production health (requires hook) |
| `staging-health` | Check staging health (requires hook) |
| `help` | Show command list |

## Architecture

```
Your repo
├── .github/workflows/
│   ├── queue-processor.yml     (thin wrapper → calls claude-queue)
│   ├── implement-issue.yml     (thin wrapper → calls claude-queue)
│   └── telegram-receiver.yml   (thin wrapper → calls claude-queue)
├── .github/prompts/
│   └── implement.txt           (optional: your custom prompt)
├── scripts/
│   └── claude-queue-hooks.sh   (optional: deploy/health hooks)
├── QUEUE.md                    (the issue queue)
└── .telegram-last-id           (persists Telegram poll offset)

WordenPond/claude-queue         (this repo — shared logic)
├── .github/workflows/
│   ├── queue-processor.yml     (reusable workflow)
│   ├── implement-issue.yml     (reusable workflow)
│   └── telegram-receiver.yml   (reusable workflow)
├── scripts/
│   ├── notify-telegram.sh
│   └── parse_telegram.py
└── prompts/
    └── implement-default.txt
```

## Requirements

- GitHub Actions enabled on your repo
- `GITHUB_TOKEN` permissions: `contents: write`, `pull-requests: write`, `issues: write`
- The `GH_PAT` token needs `actions:write` to trigger `workflow_dispatch` (the default `GITHUB_TOKEN` cannot trigger other workflows)

## License

MIT
