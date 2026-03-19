# Activation Guide

## Quick Defaults

- briefing and scanning -> `briefing-scout`
- stock and market observation -> `market-watch`
- suspicious outputs or noisy summaries -> `signal-skeptic`
- cron, logs, heartbeat, failures -> `automation-operator`
- AI product and competitor interpretation -> `pm-radar`
- repo and knowledge organization -> `knowledge-librarian`
- automation workflow design -> `workflow-architect`
- service/system packaging -> `service-designer`

## Multi-Agent Defaults

- briefing jobs: `briefing-scout` + `signal-skeptic`
- stock jobs: `market-watch` + `signal-skeptic`
- cron recovery: `automation-operator` + `workflow-architect`
- product strategy: `pm-radar` + `service-designer`
- external knowledge processing: `knowledge-librarian` + `pm-radar`

## Anti-Patterns

- Do not send noisy financial claims directly without `signal-skeptic`.
- Do not treat `service-designer` as a general analyst.
- Do not use `briefing-scout` for final judgment-heavy recommendations.
- Do not use `automation-operator` for strategic interpretation.
- Do not present candidate or unverifiable outputs as completed factual results.
