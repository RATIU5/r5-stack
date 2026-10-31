import json
import os
import re
import sys

GIT_BLOCKED = re.compile(
    r"(?:^|[;&|(`]|\$\()\s*(?:\S+/)?git"
    r"(?:\s+(?:-C\s+\S+|-c\s+\S+|--[\w-]+(?:=\S+)?))*"
    r"\s+(commit|push|merge)\b"
)
COMMENT_EXEMPT = ("// TODO-UPDATE-COMMENT", "// ---")


def deny(reason):
    print(json.dumps({
        "hookSpecificOutput": {
            "hookEventName": "PreToolUse",
            "permissionDecision": "deny",
            "permissionDecisionReason": "r5-odin: " + reason,
        }
    }))
    sys.exit(0)


def comment_of(line):
    quote = None
    i = 0
    while i < len(line):
        c = line[i]
        if quote:
            if c == "\\" and quote != "`":
                i += 2
                continue
            if c == quote:
                quote = None
        elif c in "\"'`":
            quote = c
        elif line.startswith("//", i) or line.startswith("/*", i):
            return line[i:].strip()
        i += 1
    return None


def comment_lines(text):
    found = []
    in_block = False
    for line in text.splitlines():
        if in_block:
            found.append(line.strip())
            in_block = "*/" not in line
            continue
        comment = comment_of(line)
        if comment is None:
            continue
        found.append(comment)
        if comment.startswith("/*") and "*/" not in comment:
            in_block = True
    return [c for c in found if not c.startswith(COMMENT_EXEMPT)]


def added_comments(old, new):
    remaining = comment_lines(old)
    added = []
    for comment in comment_lines(new):
        if comment in remaining:
            remaining.remove(comment)
        else:
            added.append(comment)
    return added


def read_file(path):
    try:
        with open(path) as f:
            return f.read()
    except OSError:
        return ""


def check_bash(tool_input):
    command = tool_input.get("command", "")
    match = GIT_BLOCKED.search(command)
    if match:
        deny("git " + match.group(1) + " is blocked; the user does this themselves")


def check_agent(tool_input):
    if "fable" in str(tool_input.get("model", "")).lower():
        deny("the fable model is never allowed; use haiku, sonnet or opus")


def edit_pairs(tool_name, tool_input):
    path = tool_input.get("file_path", "")
    if tool_name == "Write":
        return [(read_file(path), tool_input.get("content", ""))]
    if tool_name == "MultiEdit":
        return [(e.get("old_string", ""), e.get("new_string", ""))
                for e in tool_input.get("edits", [])]
    return [(tool_input.get("old_string", ""), tool_input.get("new_string", ""))]


def check_edit(tool_name, tool_input):
    if not tool_input.get("file_path", "").endswith(".odin"):
        return
    added = []
    for old, new in edit_pairs(tool_name, tool_input):
        added += added_comments(old, new)
    if added:
        deny("new comment lines in .odin code are not allowed (the human writes comments): "
             + " | ".join(added[:3]))


def main():
    event = json.load(sys.stdin)
    tool_name = event.get("tool_name", "")
    tool_input = event.get("tool_input") or {}
    if tool_name == "Bash":
        check_bash(tool_input)
    elif tool_name in ("Agent", "Task"):
        check_agent(tool_input)
    elif tool_name in ("Edit", "Write", "MultiEdit"):
        check_edit(tool_name, tool_input)


main()
