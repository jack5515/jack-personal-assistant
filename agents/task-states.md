# Task States

## Purpose
Provide a shared status model for multi-agent work.

## States

### `collecting`
- primary goal: gather raw material
- common agents: `briefing-scout`, `knowledge-librarian`, `market-watch`

### `interpreting`
- primary goal: convert raw inputs into takeaways
- common agents: `pm-radar`, `market-watch`, `service-designer`

### `validating`
- primary goal: check confidence, remove noise, downgrade weak claims
- common agents: `signal-skeptic`

### `operating`
- primary goal: run, monitor, retry, or recover tasks
- common agents: `automation-operator`

### `designing`
- primary goal: define repeatable workflows or services
- common agents: `workflow-architect`, `service-designer`

### `delivering`
- primary goal: package final output for Jack or a channel
- may involve: primary agent plus `automation-operator`

## State Flow Patterns

### Briefings
`collecting -> interpreting -> validating -> delivering`

### Market watch
`collecting -> interpreting -> validating -> delivering`

### Cron failure
`operating -> validating -> delivering`

### Workflow build
`collecting -> designing -> validating -> operating -> delivering`

## Rule of Thumb
If a task stalls, identify the current state first before changing agents.
