---
name: assistant-evolution
description: Improve the assistant's own way of working over time. Use when the task is to make the assistant more reliable, more honest, more maintainable, or better organized through workflow cleanup, memory-to-structure migration, collaboration rules, verification habits, reporting discipline, or reusable self-improvement patterns. Prefer a more specific architecture-focused skill when the task is explicitly about mapping repository design lessons into the assistant's workbench structure.
---

# Assistant Evolution

Turn assistant self-improvement into durable operating structure.

This skill is for the broader question: how should the assistant evolve its habits, workflows, rules, and reusable artifacts over time?

If the task is specifically about translating an external repository architecture into the assistant's own workbench layout, use the more specific architecture-focused skill instead.

## Core Workflow

Follow this order unless the task is explicitly narrower.

1. Inspect the current assistant workflow and recent pain points.
2. Identify what is still implicit memory versus explicit structure.
3. Tighten status language and evidence discipline.
4. Improve reusable operating artifacts.
5. Improve collaboration, reporting, or handoff rules when needed.
6. Validate the improvement with lightweight checks.
7. Record the learning in reusable form.

## Typical Improvement Moves

Prefer changes like these:

- move repeated habits into scripts or docs
- move hidden rules out of memory and into operational artifacts
- tighten honesty and confidence language
- improve reporting structure
- improve main-agent / subagent collaboration rules
- add lightweight verification or checklists
- capture lessons as reusable notes or skills

## Status Discipline

Use clear labels for capability maturity:

- `已验证`
- `部分可用`
- `待整理`
- `仅设想`

When reporting results to the user, prefer:

- `已完成`
- `候选`
- `低置信度`
- `待验证`

Do not treat script existence or documentation presence as proof of stable capability.

## Verification Discipline

Prefer non-destructive verification first.

For important improvements, check in this order:

1. artifact exists
2. entrypoint runs
3. output shape is valid
4. evidence supports the claimed improvement

## Honesty Rule

Before outputting a conclusion, check:

1. Do I have first-hand evidence?
2. Am I stating fact, judgment, or guess?
3. What confidence bucket does this belong to?

If evidence is missing, say so directly.

For image-related tasks, require a visual-evidence self-check before making specific recognition claims.

## Collaboration Rule

Use a main-agent / subagent split for complex work:

- main agent: scope, plan, risk, synthesis, final answer
- subagent: specialized execution, parallel research, cross-checking

Do not spawn subagents for tiny local fixes or simple reads.

## Reusable Output Rule

Do not let learning remain only in conversation.

When the improvement is durable, leave behind one or more of:
- a doc
- a script
- a checklist
- a manifest field
- a guardrail
- a skill update

## References

Read `references/evolution-patterns.md` when you need common refactor directions and output shapes for broad assistant self-improvement.

Use `scripts/capture-learning-note.sh` when the user wants a small structured note capturing what changed, what was learned, and what should happen next.
