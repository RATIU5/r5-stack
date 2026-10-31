import json
import os
import sys

MARKERS = ("ols.json", "odinfmt.json", "odx.json")
MAX_DEPTH = 3


def is_odin_project(root):
    base_depth = root.rstrip(os.sep).count(os.sep)
    for dirpath, dirnames, filenames in os.walk(root):
        if dirpath.count(os.sep) - base_depth >= MAX_DEPTH:
            dirnames[:] = []
        dirnames[:] = [d for d in dirnames if not d.startswith(".")]
        for name in filenames:
            if name.endswith(".odin") or name in MARKERS:
                return True
    return False


def main():
    event = json.load(sys.stdin)
    if not is_odin_project(event.get("cwd") or os.getcwd()):
        return
    plugin_root = os.environ["CLAUDE_PLUGIN_ROOT"]
    with open(os.path.join(plugin_root, "rules", "core.md")) as f:
        rules = f.read()
    print(json.dumps({
        "hookSpecificOutput": {
            "hookEventName": "SessionStart",
            "additionalContext": rules,
        }
    }))


main()
