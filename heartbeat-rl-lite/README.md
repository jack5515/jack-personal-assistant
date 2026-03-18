# Heartbeat RL Lite

Phase 1 shadow-mode decision helper for the running OpenClaw instance.

This module does not replace heartbeat behavior. It builds a lightweight state,
scores a suggested action, applies simple guardrails, and appends a JSONL log for
later evaluation.

## Files

- `config.json` - Thresholds and guardrails
- `heartbeat_state_builder.py` - Build a structured heartbeat state
- `heartbeat_rl_lite.py` - Score an action from the state
- `heartbeat_feedback_log.py` - Append decision records to JSONL
- `run_shadow.py` - End-to-end shadow-mode runner
- `logs/heartbeat_rl_shadow.jsonl` - Decision log output

## Usage

```bash
python3 heartbeat-rl-lite/run_shadow.py
```

This prints a suggested action and appends a record to the JSONL log.
