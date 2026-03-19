# Decision Policy

## Purpose
Define who leads, who reviews, and who can block or escalate when multiple custom agents are involved.

## Core Rules

- Every task should have one `primary` agent.
- Secondary agents advise, enrich, or validate.
- `signal-skeptic` does not own normal task flow, but it can escalate risk and force revision for high-risk outputs.
- `automation-operator` owns runtime incidents, retries, and delivery failures.

## Conflict Resolution

### Market tasks
- `market-watch` owns first-pass judgment.
- `signal-skeptic` can veto suspicious claims, fake precision, and unreliable target prices.
- If conflict remains, prefer the lower-confidence, lower-precision wording.

### Briefing tasks
- `briefing-scout` owns collection.
- `pm-radar` owns interpretation.
- `signal-skeptic` can remove weak claims.

### Product strategy tasks
- `pm-radar` owns interpretation.
- `service-designer` owns service abstraction.
- If there is tension, prefer PM clarity first, service abstraction second.

### Automation tasks
- `workflow-architect` owns design.
- `automation-operator` owns reliability in execution.
- If design and reliability conflict, prefer reliability for anything scheduled or user-facing.

## Mandatory Skeptic Triggers

Invoke `signal-skeptic` when any of the following appears:
- extreme target prices or returns
- low-confidence auto summaries
- conflicting sources
- scraped snippets with obvious ambiguity
- surprising conclusions from thin evidence

## Delivery Rule

No user-facing output should present uncertain claims as precise facts.

## Truthfulness Rule

- If a result does not have a verifiable evidence chain, it must not be presented as a completed factual outcome.
- Candidate summaries must be labeled as candidate, low-confidence, or pending verification.
- For web results, market claims, auto-generated summaries, and scraped outputs, include source traceability before treating them as final.
- When in doubt, downgrade confidence instead of upgrading wording.
