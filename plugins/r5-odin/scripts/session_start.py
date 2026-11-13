import json
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from odin_project import is_odin_project


def main():
    raw = sys.stdin.read()
    event = json.loads(raw) if raw.strip() else {}
    if not isinstance(event, dict):
        event = {}
    if not is_odin_project(event):
        return
    plugin_root = os.environ.get("CLAUDE_PLUGIN_ROOT") or os.path.dirname(
        os.path.dirname(os.path.abspath(__file__)))
    with open(os.path.join(plugin_root, "rules", "core.md")) as f:
        rules = f.read()
    print(json.dumps({
        "hookSpecificOutput": {
            "hookEventName": "SessionStart",
            "additionalContext": rules,
        }
    }))


try:
    main()
except Exception:
    sys.exit(0)
