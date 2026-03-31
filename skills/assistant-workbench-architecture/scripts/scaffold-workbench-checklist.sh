#!/usr/bin/env bash
set -euo pipefail

cat <<'EOF'
Assistant Workbench Architecture Checklist

- Revise README to describe the workspace honestly
- Split files into execution / state / knowledge / delivery layers
- Create a human-readable manifest
- Create a machine-readable manifest
- Add status and verify entrypoints
- Add a summary renderer over the manifest
- Define git-boundary rules
- Add a precommit-style runtime residue check
- Validate docs and entrypoints before claiming success
EOF
