# 2026-03-19 Progress Summary

## What Improved Today

### 1. Stronger truthfulness discipline
- Reinforced that factual accuracy and evidence-chain integrity are the first principle.
- Added hard constraints so unverifiable outputs cannot be presented as completed results.
- Explicitly downgraded candidate or weakly verified outputs to `candidate`, `low-confidence`, or `pending verification`.

### 2. Better execution transparency
- Adopted a clearer working style during tasks:
  - explain the plan before acting
  - state which custom agent is being used
  - explain why that agent is involved
  - separate completed work from unverified or paused work
- This reduced the chance of polished but weakly supported output.

### 3. Better result formatting for research-style outputs
- Added a preference to include one representative link and its publication time for each topic when summarizing findings.
- Established a more concrete update format instead of vague topical summaries.

### 4. Custom agent system established
- Built a Jack-specific custom agent layer under `agents/`.
- Defined the first working set:
  - `briefing-scout`
  - `pm-radar`
  - `market-watch`
  - `signal-skeptic`
  - `automation-operator`
  - `knowledge-librarian`
  - `workflow-architect`
  - `service-designer`
- Added routing, collaboration, activation, decision, task-state, and runtime-binding documentation.

### 5. Better safety on noisy outputs
- Recognized that weak search chains can produce convincing but non-verifiable summaries.
- Corrected the workflow so `signal-skeptic` can hard-stop outputs that look finished but lack a traceable evidence chain.

### 6. Group-mode thinking became more precise
- Moved from a one-size-fits-all speaking policy to group-level mode switching.
- Defined a `feedback-silent` operating mode for a designated feedback group:
  - do not speak by default
  - do not react
  - only speak if Jack explicitly @ mentions the assistant
  - otherwise only monitor and privately summarize

### 7. Better boundary handling on repos and pushes
- Clarified that only the `jack-personal-assistant` repository should be pushed by default.
- Stopped assuming the workspace root repo should also be pushed.
- Correctly handled the repo/submodule boundary when committing and pushing changes.

## What Was Learned
- A polished summary is not the same as a verified result.
- Evidence-chain discipline must apply before delivery, not after correction.
- Silent monitoring behavior must be configured at the group level, not as a global rule.
- Progress reporting is more useful when split into: completed, unverified, and paused.

## Current Defaults Going Forward
- Truthfulness first.
- No evidence chain -> no final-result wording.
- Explain execution thinking during work.
- Mention which custom agent is being used and why.
- Include a representative link and publish time when summarizing topics.
- Default push target: `jack-personal-assistant` only.
