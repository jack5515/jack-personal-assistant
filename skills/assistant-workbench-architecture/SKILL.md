---
name: assistant-workbench-architecture
description: Apply repository architecture lessons to the assistant itself. Use when the task is to make the assistant more like a clear, maintainable workbench by separating implementation from background material, introducing a manifest-driven structure, adding honest status labels, defining summary/status/verify/precommit entrypoints, or restructuring the assistant's own repo/workspace after learning from another repository's design.
---

# Assistant Workbench Architecture

Apply repository-architecture lessons to the assistant itself.

This skill is specifically for the pattern: learn from another repo's structure, then refactor the assistant's own workspace so the improvement becomes operational instead of staying as commentary.

## Core Idea

Do not stop at "this repo has good ideas".

Translate the idea into the assistant's own system in four moves:

1. separate tracked implementation from background material
2. make current capabilities explicit in manifests
3. define honest status labels and convergent entrypoints
4. keep runtime residue out of the durable architecture

## What To Build

When applying this skill, prefer creating or updating these artifacts:

- `README` that describes the workbench honestly
- a machine-readable manifest
- a human-readable manifest
- `summary`, `status`, `verify`, and `precommit` entrypoints
- git-boundary rules
- collaboration / handoff rules
- a small summary renderer or query tool over the manifest

## Translation Pattern

Map lessons from an external repo into the assistant like this:

- `clear source tree` -> split execution, state, knowledge, delivery
- `manifest / models` -> create workbench manifest files
- `CLI summary` -> create `status` / summary entrypoints
- `tests / verification` -> create non-destructive verify commands
- `honest README` -> describe current maturity without pretending completeness
- `single source of truth` -> make summary/status/verify/precommit converge on one manifest

## Status Rule

Use explicit maturity labels:

- `已验证`
- `部分可用`
- `待整理`
- `仅设想`

Do not equate documentation or script presence with system reliability.

## Verification Rule

Validate in layers:

1. file exists
2. entry is executable
3. dependency files exist
4. output shape is valid
5. live evidence exists

For automation, keep `ack` separate from `client visibility`.

## Git Rule

Do not commit local runtime residue while doing architecture cleanup.

Keep local-only by default:
- logs
- state files
- handoff snapshots
- latest generated outputs
- manual resend artifacts

## References

Read `references/repo-lessons-to-workbench.md` for the concrete mapping from an external repository pattern into assistant architecture.

Use `scripts/scaffold-workbench-checklist.sh` when you want a compact checklist for applying the pattern in a new workspace.
