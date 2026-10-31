import json
import os
import subprocess
import sys
import tempfile

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
GUARD = os.path.join(ROOT, "scripts", "guard.py")
START = os.path.join(ROOT, "scripts", "session_start.py")
failures = []


def run(script, event, cwd=None):
    env = dict(os.environ, CLAUDE_PLUGIN_ROOT=ROOT)
    proc = subprocess.run(
        ["python3", "-I", script], input=json.dumps(event), capture_output=True,
        text=True, env=env, cwd=cwd,
    )
    return proc.returncode, proc.stdout


def decision(event):
    code, out = run(GUARD, event)
    if code != 0:
        return "crash:%d" % code
    if not out.strip():
        return "allow"
    return json.loads(out)["hookSpecificOutput"]["permissionDecision"]


def expect(name, got, want):
    status = "ok  " if got == want else "FAIL"
    if got != want:
        failures.append(name)
    print("%s %s -> %s" % (status, name, got))


def bash(command):
    return {"tool_name": "Bash", "tool_input": {"command": command}}


def edit(path, old, new):
    return {"tool_name": "Edit", "tool_input": {"file_path": path, "old_string": old, "new_string": new}}


for name, cmd, want in [
    ("git status", "git status", "allow"),
    ("git log grep", "git log --grep commit", "allow"),
    ("echo quoted", 'echo "git commit"', "allow"),
    ("git commit", "git commit -m x", "deny"),
    ("git push", "git push origin main", "deny"),
    ("chained merge", "cd x && git merge main", "deny"),
    ("git -C commit", "git -C . commit -am x", "deny"),
    ("subshell push", "(git push)", "deny"),
]:
    expect("bash: " + name, decision(bash(cmd)), want)

for name, tool_input, want in [
    ("sonnet", {"model": "sonnet"}, "allow"),
    ("no model", {}, "allow"),
    ("fable", {"model": "fable"}, "deny"),
    ("Fable caps", {"model": "Fable"}, "deny"),
]:
    expect("agent: " + name, decision({"tool_name": "Agent", "tool_input": tool_input}), want)

for name, ev, want in [
    ("add comment", edit("a.odin", "x := 1", "x := 1 // one"), "deny"),
    ("add block comment", edit("a.odin", "x := 1", "/* hi */\nx := 1"), "deny"),
    ("add line comment", edit("a.odin", "x := 1", "// why\nx := 1"), "deny"),
    ("todo-update ok", edit("a.odin", "// old\nx := 1", "// TODO-UPDATE-COMMENT: changed\n// ---\nx := 1"), "allow"),
    ("kept comment ok", edit("a.odin", "// old\nx := 1", "// old\nx := 2"), "allow"),
    ("string slashes ok", edit("a.odin", "x := 1", 'url := "http://x"'), "allow"),
    ("non-odin ok", edit("a.md", "x", "// c"), "allow"),
]:
    expect("edit: " + name, decision(ev), want)

with tempfile.TemporaryDirectory() as tmp:
    existing = os.path.join(tmp, "e.odin")
    with open(existing, "w") as f:
        f.write("// keep\nx := 1\n")
    write = lambda path, content: {"tool_name": "Write", "tool_input": {"file_path": path, "content": content}}
    expect("write: new with comment", decision(write(os.path.join(tmp, "n.odin"), "// c\n")), "deny")
    expect("write: new clean", decision(write(os.path.join(tmp, "n.odin"), "x := 1\n")), "allow")
    expect("write: kept comment", decision(write(existing, "// keep\nx := 2\n")), "allow")
    expect("write: added comment", decision(write(existing, "// keep\n// new\nx := 2\n")), "deny")
    multi = {"tool_name": "MultiEdit", "tool_input": {"file_path": "a.odin", "edits": [
        {"old_string": "a", "new_string": "a"}, {"old_string": "b", "new_string": "b // c"}]}}
    expect("multiedit: added comment", decision(multi), "deny")

ignore = "// odx:ignore transmute reason\nx := 1"
with tempfile.TemporaryDirectory() as plain, tempfile.TemporaryDirectory() as proj:
    with open(os.path.join(proj, "odx.json"), "w") as f:
        f.write("{}")
    os.makedirs(os.path.join(proj, "src", "deep"))
    plain_file = os.path.join(plain, "a.odin")
    proj_file = os.path.join(proj, "src", "deep", "a.odin")
    expect("odx: ignore without odx.json denied", decision(edit(plain_file, "x := 1", ignore)), "deny")
    expect("odx: ignore with odx.json allowed", decision(edit(proj_file, "x := 1", ignore)), "allow")
    expect("odx: other comment with odx.json denied", decision(edit(proj_file, "x := 1", "// why\nx := 1")), "deny")
    expect("odx: trailing ignore with odx.json denied", decision(edit(proj_file, "x := 1", "x := 1 // odx:ignore transmute r")), "deny")

with tempfile.TemporaryDirectory() as odin_dir,tempfile.TemporaryDirectory() as empty_dir:
    with open(os.path.join(odin_dir, "m.odin"), "w") as f:
        f.write("package m\n")
    code, out = run(START, {"cwd": odin_dir})
    ctx = json.loads(out)["hookSpecificOutput"]["additionalContext"] if out.strip() else ""
    expect("start: odin project injects rules", code == 0 and "r5-odin core rules" in ctx, True)
    code, out = run(START, {"cwd": empty_dir})
    expect("start: non-odin dir is silent", (code, out.strip()), (0, ""))

sys.exit(1 if failures else 0)
