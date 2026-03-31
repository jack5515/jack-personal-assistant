# Repo Lessons To Workbench

## Purpose

This reference captures a specific architecture pattern:
learn from a well-structured repository, then push that structure into the assistant's own workspace.

## Main Lessons

### 1. Separate the active implementation surface from background material

Do not let notes, exposed snapshots, experiments, and current implementation live in one undifferentiated tree.

For the assistant, the practical split is:
- `scripts/` -> execution layer
- `memory/` -> state layer
- `docs/` and `MEMORY.md` -> knowledge layer
- `workfiles/` -> delivery layer

### 2. Describe the system honestly

A strong README says what is active now, what is partial, and what still needs work.
It does not pretend the workspace is a polished product if it is really an operating workbench.

### 3. Introduce manifests

A manifest turns hidden system knowledge into explicit structure.
Useful manifest fields include:
- capability name
- status
- entrypoint
- verify command
- log paths
- failure modes

Keep both:
- a human-readable manifest for explanation
- a machine-readable manifest for tooling

### 4. Add convergent entrypoints

If the repo has a summary or manifest command, mirror that idea.
For the assistant, good entrypoints are:
- `render-workbench-summary.py`
- `workbench-status.sh`
- `workbench-verify.sh`
- `workbench-precommit-check.sh`

The important part is not the filenames. The important part is that they converge on one manifest instead of drifting onto separate schemas.

### 5. Keep runtime residue out of the durable architecture

Architecture cleanup fails if runtime state, logs, and latest outputs keep polluting the repo view.
Pair docs with `.gitignore` and a precommit-style check.

## Recommended Sequence

1. revise README
2. create human-readable manifest
3. create machine-readable manifest
4. create summary renderer
5. create verify entrypoint
6. create precommit guardrail
7. create git-boundary rules
8. validate the structure
9. only then consider commit packaging
