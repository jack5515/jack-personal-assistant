# Runtime Bindings

## Purpose
Bind custom agents to real files, scripts, logs, and cloned repositories in the workspace.

## Operational Bindings

### `automation-operator`
- cron entries: system crontab entries for briefing/news/report jobs
- scripts:
  - `/root/.openclaw/workspace/scripts/china-news-summary.sh`
  - `/root/.openclaw/workspace/scripts/us-stock-report.sh`
  - `/root/.openclaw/workspace/scripts/us-stock-report.py`
  - `/root/.openclaw/workspace/scripts/daily-news-summary.sh`
  - `/root/.openclaw/workspace/scripts/interesting-briefing-weekly.sh`
- logs:
  - `/root/.openclaw/workspace/daily-reports/cron.log`
  - `/root/.openclaw/workspace/daily-news/cron.log`
  - `/root/.openclaw/workspace/logs/interesting-briefing.log`
- heartbeat:
  - `/root/.openclaw/workspace/HEARTBEAT.md`

### `market-watch`
- reports:
  - `/root/.openclaw/workspace/daily-reports/us-stock-*.md`
  - `/root/.openclaw/workspace/mag7-report/*.md`
- scripts:
  - `/root/.openclaw/workspace/scripts/us-stock-report.py`
  - `/root/.openclaw/workspace/scripts/mag7-bxtrender-report.py`

### `briefing-scout`
- reports:
  - `/root/.openclaw/workspace/interesting-briefing-*.md`
  - `/root/.openclaw/workspace/daily-news/*.md`
- scripts:
  - `/root/.openclaw/workspace/scripts/interesting-briefing-weekly.sh`
  - `/root/.openclaw/workspace/scripts/daily-news-summary.sh`

### `knowledge-librarian`
- knowledge repos:
  - `/root/.openclaw/workspace/external-knowledge/lennys-newsletterpodcastdata`
  - `/root/.openclaw/workspace/agency-agents-zh`
  - `/root/.openclaw/workspace/jack-personal-assistant/agency-agents-zh`
- memory files:
  - `/root/.openclaw/workspace/MEMORY.md`
  - `/root/.openclaw/workspace/memory/`

## Cloned Agent Repo Bindings

### `knowledge-librarian`
- organizes the cloned agent and knowledge repos
- maintains reference maps, summaries, and durable notes

### `pm-radar`
- extracts product and competitive meaning from:
  - `agency-agents-zh`
  - `external-knowledge/lennys-newsletterpodcastdata`

### `workflow-architect`
- reuses patterns from cloned repos when designing local CLI workflows
- especially relevant for future Twitter and Zhihu automation

### `service-designer`
- uses cloned repos as examples of packaging, service boundaries, and reusable capability layers

## Priority Rule
When a task touches a cloned repo, use `knowledge-librarian` first unless the task is explicitly about strategy, workflow design, or product meaning.
