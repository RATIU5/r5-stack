import json
import os
import sys

MARKERS = ("mise.toml", ".mise.toml", "knope.toml")


def has_marker_above(root):
    directory = os.path.abspath(root)
    while True:
        if any(os.path.isfile(os.path.join(directory, m)) for m in MARKERS):
            return True
        if os.path.exists(os.path.join(directory, ".git")):
            return False
        parent = os.path.dirname(directory)
        if parent == directory:
            return False
        directory = parent


def main():
    raw = sys.stdin.read()
    event = json.loads(raw) if raw.strip() else {}
    if not isinstance(event, dict):
        event = {}
    cwd = event.get("cwd")
    root = cwd if isinstance(cwd, str) and cwd else os.getcwd()
    if not has_marker_above(root):
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
