import json
from pathlib import Path

CONFIG = json.loads(Path('/root/.openclaw/workspace/heartbeat-rl-lite/config.json').read_text())


def score_action(state: dict) -> dict:
    weights = CONFIG['weights']
    score = 0

    if state.get('has_running_task'):
        score += weights['running_task']
    if state.get('stalled_task'):
        score += weights['stalled_task']
    if state.get('has_new_user_message'):
        score += weights['new_user_message']
    if state.get('minutes_since_last_update', 999) < CONFIG['brief_update_cooldown_minutes']:
        score += weights['recent_update_penalty']
    if state.get('severity') == 'high':
        score += weights['high_severity']
    elif state.get('severity') == 'medium':
        score += weights['medium_severity']

    quiet_start, quiet_end = CONFIG['quiet_hours']
    hour = state.get('hour', 12)
    if hour >= quiet_start or hour < quiet_end:
        score += weights['quiet_hours_penalty']

    if not state.get('findings'):
        score += CONFIG['no_change_bias']

    model_action = 'silent'
    if state.get('stalled_task'):
        model_action = 'check_codex_first'
    elif state.get('severity') == 'high' or score >= 4:
        model_action = 'urgent_alert'
    elif score >= 1:
        model_action = 'brief_update'

    final_action = model_action
    if (hour >= quiet_start or hour < quiet_end) and final_action == 'brief_update':
        final_action = 'silent'
    if state.get('severity') == 'high' and final_action == 'silent':
        final_action = 'urgent_alert'

    return {
        'score': score,
        'model_action': model_action,
        'final_action': final_action
    }


if __name__ == '__main__':
    sample = {
        'hour': 15,
        'has_running_task': True,
        'stalled_task': False,
        'severity': 'low',
        'findings': ['demo'],
        'minutes_since_last_update': 60,
        'has_new_user_message': False
    }
    print(json.dumps(score_action(sample), ensure_ascii=False, indent=2))
