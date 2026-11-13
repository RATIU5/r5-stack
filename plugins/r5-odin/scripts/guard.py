import json
import os
import re
import shlex
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from odin_project import is_odin_project

BLOCKED_SUBCOMMANDS = ("commit", "push", "merge", "pull", "cherry-pick", "revert", "am", "rebase")
GH_BLOCKED = (("pr", "merge"),)
HEREDOC = re.compile(r"<<(-?)\s*(?:'([^']*)'|\"([^\"]*)\"|\\?\w+)")
WRAPPERS = {
    "env", "command", "sudo", "doas", "time", "nohup", "exec", "builtin", "xargs",
    "eval", "nice", "timeout", "!", "then", "do", "else", "if", "while", "until",
}
SHELLS = {"sh", "bash", "zsh", "dash", "ksh", "eval"}
GIT_VALUE_OPTIONS = {"-C", "-c", "--git-dir", "--work-tree", "--namespace", "--exec-path"}
COMMENT_EXEMPT = ("// TODO-UPDATE-COMMENT", "// ---")
ODX_IGNORE = "// odx:ignore"


def deny(reason):
    print(json.dumps({
        "hookSpecificOutput": {
            "hookEventName": "PreToolUse",
            "permissionDecision": "deny",
            "permissionDecisionReason": "r5-odin: " + reason,
        }
    }))
    sys.exit(0)


def text_of(value):
    return value if isinstance(value, str) else ""


def git_subcommand(args):
    aliases = {}
    i = 0
    while i < len(args):
        arg = args[i]
        if arg == "-c" and i + 1 < len(args):
            name, _, value = args[i + 1].partition("=")
            if name.startswith("alias."):
                aliases[name[len("alias."):]] = value.split()[0] if value.split() else ""
            i += 2
        elif arg in GIT_VALUE_OPTIONS:
            i += 2
        elif arg.startswith("-"):
            i += 1
        else:
            return aliases.get(arg, arg)
    return ""


def blocked_in_tokens(tokens, depth):
    while tokens and re.match(r"^\w+=", tokens[0]):
        tokens = tokens[1:]
    if not tokens:
        return None
    first = os.path.basename(tokens[0])
    if first in SHELLS and depth < 4:
        for token in tokens[1:]:
            if re.search(r"\s", token):
                found = blocked_command(token, depth + 1)
                if found:
                    return found
    if first in ("git", "gh"):
        start = 0
    elif first in WRAPPERS:
        start = next((i for i, t in enumerate(tokens) if os.path.basename(t) in ("git", "gh")), None)
    else:
        return None
    if start is None:
        return None
    if os.path.basename(tokens[start]) == "gh":
        words = tuple([t for t in tokens[start + 1:] if not t.startswith("-")][:2])
        return "gh " + " ".join(words) if words in GH_BLOCKED else None
    sub = git_subcommand(tokens[start + 1:])
    return "git " + sub if sub in BLOCKED_SUBCOMMANDS else None


def split_segments(command):
    segments = []
    current = []
    quote = None
    skip = None
    i = 0
    n = len(command)

    def flush():
        segments.append("".join(current))
        current.clear()

    while i < n:
        c = command[i]
        if quote == "'":
            current.append(c)
            if c == "'":
                quote = None
            i += 1
        elif c == "\\" and i + 1 < n:
            current.append(command[i:i + 2])
            i += 2
        elif quote == '"':
            if c == '"':
                quote = None
                current.append(c)
                i += 1
            elif c == "`":
                flush()
                i += 1
            elif command.startswith("$(", i):
                flush()
                i += 2
            else:
                current.append(c)
                i += 1
        elif c in "'\"":
            quote = c
            current.append(c)
            i += 1
        elif command.startswith("<<<", i):
            current.append("<<<")
            i += 3
        elif command.startswith("<<", i):
            match = HEREDOC.match(command, i)
            if match is None:
                current.append("<<")
                i += 2
                continue
            delimiter = match.group(2) if match.group(2) is not None else match.group(3)
            if delimiter is not None:
                skip = (match.group(1) == "-", delimiter)
            current.append(match.group(0))
            i = match.end()
        elif c == "\n":
            flush()
            i += 1
            if skip:
                dash, delimiter = skip
                skip = None
                while i < n:
                    end = command.find("\n", i)
                    line = command[i:end if end != -1 else n]
                    i = end + 1 if end != -1 else n
                    if (line.lstrip("\t") if dash else line) == delimiter:
                        break
        elif command.startswith("$(", i):
            flush()
            i += 2
        elif c in ";&|(){}`":
            flush()
            i += 1
        else:
            current.append(c)
            i += 1
    flush()
    return segments


def blocked_command(command, depth=0):
    if depth:
        command = command.replace("\\n", "\n")
    for segment in split_segments(command):
        try:
            tokens = shlex.split(segment)
        except ValueError:
            tokens = segment.replace("'", "").replace('"', "").split()
        found = blocked_in_tokens([t.rstrip(")") for t in tokens], depth)
        if found:
            return found
    return None


def comment_lines(text, odx):
    found = []
    depth = 0
    quote = None
    for line in text.splitlines():
        stripped = line.lstrip()
        if depth == 0 and quote is None:
            if odx and stripped.startswith(ODX_IGNORE):
                continue
            if stripped.startswith(COMMENT_EXEMPT):
                continue
        in_block = depth > 0
        start = None
        i = 0
        while i < len(line):
            c = line[i]
            if depth:
                if line.startswith("/*", i):
                    depth += 1
                    i += 2
                elif line.startswith("*/", i):
                    depth -= 1
                    i += 2
                else:
                    i += 1
            elif quote:
                if c == "\\" and quote != "`":
                    i += 2
                    continue
                if c == quote:
                    quote = None
                i += 1
            elif c in "\"'`":
                quote = c
                i += 1
            elif line.startswith("//", i):
                if start is None:
                    start = i
                break
            elif line.startswith("/*", i):
                if start is None:
                    start = i
                depth += 1
                i += 2
            else:
                i += 1
        if quote and quote != "`":
            quote = None
        if in_block:
            found.append(line.strip())
        elif start is not None:
            found.append(line[start:].strip())
    return found


def in_odx_project(path):
    directory = os.path.dirname(os.path.abspath(path))
    while True:
        if os.path.isfile(os.path.join(directory, "odx.json")):
            return True
        parent = os.path.dirname(directory)
        if parent == directory:
            return False
        directory = parent


def added_comments(old, new, odx):
    remaining = comment_lines(old, odx)
    added = []
    for comment in comment_lines(new, odx):
        if comment in remaining:
            remaining.remove(comment)
        else:
            added.append(comment)
    return added


def read_file(path):
    try:
        with open(path, encoding="utf-8", errors="replace") as f:
            return f.read()
    except (OSError, ValueError):
        return ""


def check_bash(tool_input):
    found = blocked_command(text_of(tool_input.get("command")))
    if found:
        deny(found + " is blocked; the user does this themselves")


def check_agent(tool_input):
    if "fable" in text_of(tool_input.get("model")).lower():
        deny("the fable model is never allowed; use haiku, sonnet or opus")


def edit_pairs(tool_name, tool_input):
    path = text_of(tool_input.get("file_path"))
    if tool_name == "Write":
        return [(read_file(path), text_of(tool_input.get("content")))]
    if tool_name == "MultiEdit":
        edits = tool_input.get("edits")
        edits = [e for e in edits if isinstance(e, dict)] if isinstance(edits, list) else []
        return [(text_of(e.get("old_string")), text_of(e.get("new_string"))) for e in edits]
    return [(text_of(tool_input.get("old_string")), text_of(tool_input.get("new_string")))]


def check_edit(tool_name, tool_input):
    path = text_of(tool_input.get("file_path"))
    if not path.endswith(".odin"):
        return
    pairs = edit_pairs(tool_name, tool_input)
    old = "\n".join(p[0] for p in pairs)
    new = "\n".join(p[1] for p in pairs)
    added = added_comments(old, new, in_odx_project(path))
    if added:
        deny("new comment lines in .odin code are not allowed (the human writes comments): "
             + " | ".join(added[:3]))


def main():
    event = json.load(sys.stdin)
    if not isinstance(event, dict):
        return
    tool_name = text_of(event.get("tool_name"))
    tool_input = event.get("tool_input")
    if not isinstance(tool_input, dict):
        return
    if tool_name == "Bash":
        if is_odin_project(event):
            check_bash(tool_input)
    elif tool_name in ("Agent", "Task"):
        check_agent(tool_input)
    elif tool_name in ("Edit", "Write", "MultiEdit"):
        check_edit(tool_name, tool_input)


try:
    main()
except Exception:
    sys.exit(0)
