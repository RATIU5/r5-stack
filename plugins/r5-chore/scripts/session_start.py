import json
import os
import sys


def main():
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
