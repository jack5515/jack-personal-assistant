import json
from pathlib import Path
from heartbeat_state_builder import build_state, LAST_UPDATE_FILE, STATE_DIR
from heartbeat_rl_lite import score_action
from heartbeat_feedback_log import append_log

STATE_DIR.mkdir(parents=True, exist_ok=True)


def main() -> None:
    state = build_state()
    decision = score_action(state)
    record = {
        'state': state,
        'decision': decision,
        'result': None,
        'user_feedback': None
    }
    append_log(record)

    if decision['final_action'] in {'brief_update', 'urgent_alert'}:
        LAST_UPDATE_FILE.write_text(json.dumps({'ts': state['ts'], 'action': decision['final_action']}, ensure_ascii=False))

    print(json.dumps(record, ensure_ascii=False, indent=2))


if __name__ == '__main__':
    main()
