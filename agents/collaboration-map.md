# Collaboration Map

## Core Patterns

### Scout -> Interpret -> Skeptic -> Operate
Used for recurring briefings and monitored outputs.

- `briefing-scout` collects and shortlists
- `pm-radar` interprets implications when needed
- `signal-skeptic` checks for noisy claims and weak evidence
- `automation-operator` runs, retries, and monitors delivery

### Watch -> Skeptic -> Report
Used for market observation.

- `market-watch` forms the main trend/risk view
- `signal-skeptic` filters fake precision and suspicious claims
- final output goes to daily watch reports

### Architect -> Operate -> Designer
Used for automation and service building.

- `workflow-architect` designs the workflow
- `automation-operator` keeps it reliable in production
- `service-designer` turns repeated flows into durable services

### Librarian -> Radar -> Designer
Used for knowledge-heavy strategic work.

- `knowledge-librarian` organizes the knowledge base
- `pm-radar` extracts product meaning
- `service-designer` decides whether the pattern should become a service

## Priority Agents

For Jack's current workflow, default priority is:
1. `automation-operator`
2. `signal-skeptic`
3. `market-watch`
4. `pm-radar`
5. `briefing-scout`
6. `workflow-architect`
7. `knowledge-librarian`
8. `service-designer`

## Escalation Guidance

- If a task is failing repeatedly, involve `automation-operator` first.
- If a conclusion feels too clean or too extreme, involve `signal-skeptic`.
- If the task relates to product meaning, involve `pm-radar`.
- If the task may become a repeatable system, involve `workflow-architect` and `service-designer`.
