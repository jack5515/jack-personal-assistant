# Task Routing

This file maps recurring Jack workflows to the most appropriate custom agents.

## Daily and Weekly Briefings

### Weekly interesting briefing
- Primary: `briefing-scout`
- Secondary: `pm-radar`
- Validation: `signal-skeptic`
- Operations: `automation-operator`

### Daily global news summary
- Primary: `briefing-scout`
- Secondary: `pm-radar`
- Validation: `signal-skeptic`

## Market Monitoring

### US stock morning watch
- Primary: `market-watch`
- Validation: `signal-skeptic`
- Operations: `automation-operator`

### Event-driven stock review
- Primary: `market-watch`
- Validation: `signal-skeptic`

## Product and Strategy Work

### AI product analysis
- Primary: `pm-radar`
- Secondary: `service-designer`
- Validation: `signal-skeptic`

### Agent productization and service design
- Primary: `service-designer`
- Secondary: `workflow-architect`
- Secondary: `pm-radar`

## Operations and Reliability

### Heartbeat checks
- Primary: `automation-operator`
- Secondary: `signal-skeptic`

### Cron and script failures
- Primary: `automation-operator`
- Secondary: `workflow-architect`
- Validation: `signal-skeptic`

## Knowledge Work

### External repo and document organization
- Primary: `knowledge-librarian`
- Secondary: `pm-radar`

### Long-term memory curation
- Primary: `knowledge-librarian`
- Secondary: `signal-skeptic`

## Workflow Design

### Twitter or Zhihu local CLI automation
- Primary: `workflow-architect`
- Secondary: `automation-operator`
- Validation: `signal-skeptic`

### New internal automation chains
- Primary: `workflow-architect`
- Secondary: `automation-operator`
- Secondary: `service-designer`
