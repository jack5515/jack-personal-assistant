# Self Application Playbook

Use this playbook when the assistant is applying repo architecture lessons to itself, not just discussing them.

## Goal

Translate a good repository design pattern into durable assistant structure.

The target is not a prettier README. The target is a better-organized workbench with:
- clearer layers
- machine-readable inventory
- honest status labels
- verification entrypoints
- cleaner git boundaries
- summary/status/verify/precommit convergence

## Practical Sequence

1. Inspect current workspace files and scripts.
2. Identify mixed concerns.
3. Create or refine a human-readable manifest.
4. Create or refine a machine-readable manifest.
5. Create or refine these entrypoints so they align on one source of truth:
   - `scripts/render-workbench-summary.py`
   - `scripts/workbench-status.sh`
   - `scripts/workbench-verify.sh`
   - `scripts/workbench-precommit-check.sh`
6. Move rules from memory into operational docs where possible.
7. Validate the new structure with actual commands.
8. Record the architectural lesson in reusable form.

## Minimum Artifacts

A good self-application pass usually leaves behind at least:
- one README or top-level framing improvement
- one human-readable manifest
- one machine-readable manifest
- one summary or status entrypoint
- one verification entrypoint
- one guardrail such as precommit
- one boundary or policy document

## Anti-Patterns

Avoid these mistakes:
- writing only philosophy without changing structure
- creating manifests that no script actually reads
- adding verify commands that do not run
- calling a capability stable just because an entry file exists
- mixing runtime residue into the same commit as durable architecture work
- leaving summary/status/verify/precommit on different schemas

## Recommended Local Checks

Use these when present:

```bash
python3 scripts/render-workbench-summary.py
scripts/workbench-status.sh --json
scripts/workbench-verify.sh all
scripts/workbench-precommit-check.sh
```
