import json
import os
import subprocess
import sys
import tempfile

REPO = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
ROOT = os.path.join(REPO, "plugins", "r5-odin")
GUARD = os.path.join(ROOT, "scripts", "guard.py")
START = os.path.join(ROOT, "scripts", "session_start.py")
failures = []


def run(script, event, cwd=None):
    env = dict(os.environ, CLAUDE_PLUGIN_ROOT=ROOT)
    payload = event if isinstance(event, (bytes, str)) else json.dumps(event)
    proc = subprocess.run(
        ["python3", "-I", script], input=payload, capture_output=True,
        text=isinstance(payload, str), env=env, cwd=cwd,
    )
    out = proc.stdout if isinstance(proc.stdout, str) else proc.stdout.decode()
    return proc.returncode, out


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
    ("env", "env git commit -m x", "deny"),
    ("command", "command git commit -m x", "deny"),
    ("assignment", "GIT_DIR=.git git commit -m x", "deny"),
    ("sudo", "sudo git push", "deny"),
    ("time", "time git push", "deny"),
    ("bang", "! git push", "deny"),
    ("xargs", "xargs git push", "deny"),
    ("eval escaped", "eval git\\ push", "deny"),
    ("ansi newline", "$'true\\ngit commit -m x'", "deny"),
    ("sh -c", "sh -c 'git commit -m x'", "deny"),
    ("here-string", 'bash <<< "git push"', "deny"),
    ("quoted git", '"git" commit', "deny"),
    ("quoted sub", "git 'commit'", "deny"),
    ("escaped git", "g\\it push", "deny"),
    ("alias commit", "git -c alias.ci=commit ci -m x", "deny"),
    ("quoted -c value", 'git -c "a=b c" push', "deny"),
    ("-P flag", "git -P push", "deny"),
    ("git-dir", "git --git-dir .git commit", "deny"),
    ("work-tree", "git --work-tree . push", "deny"),
    ("brace group", "{ git push; }", "deny"),
    ("if then", "if true; then git push; fi", "deny"),
    ("full path", "/usr/bin/git commit", "deny"),
    ("echo word", "echo git push", "allow"),
    ("grep word", "grep -r 'git commit' .", "allow"),
    ("git diff", "git diff --stat", "allow"),
    ("git -c harmless", "git -c core.pager=cat log", "allow"),
    ("pull", "git pull", "deny"),
    ("pull rebase", "git pull --rebase origin main", "deny"),
    ("rebase", "git rebase main", "deny"),
    ("cherry-pick", "git cherry-pick abc", "deny"),
    ("revert", "git revert HEAD", "deny"),
    ("am", "git am x.patch", "deny"),
    ("gh pr merge", "gh pr merge 3 --squash", "deny"),
    ("gh pr create", "gh pr create --fill", "deny"),
    ("sudo gh pr merge", "sudo gh pr merge 3", "deny"),
    ("gh pr view", "gh pr view 3", "allow"),
    ("gh pr list", "gh pr list", "allow"),
    ("git log", "git log --oneline", "allow"),
    ("git fetch", "git fetch origin", "allow"),
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
    ("trailing todo-update denied", edit("a.odin", "x := 1", "x := 1 // --- trailing"), "deny"),
    ("trailing todo-update marker denied", edit("a.odin", "x := 1", "x := 1 // TODO-UPDATE-COMMENT: r"), "deny"),
    ("nested block hidden", edit("a.odin", "/* o\n/* i */", "/* o\n/* i */\nhidden text"), "deny"),
    ("block reopened", edit("a.odin", "x := 1", "x := 1 /* a */ + y /* b\nhidden"), "deny"),
    ("multiline raw string ok", edit("a.odin", "x := 1", "s := `l1\n// inside raw\n`"), "allow"),
    ("rune slash ok", edit("a.odin", "x := 1", "r := '/'"), "allow"),
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
    moved = {"tool_name": "MultiEdit", "tool_input": {"file_path": "a.odin", "edits": [
        {"old_string": "// keep\nx", "new_string": "x"}, {"old_string": "y", "new_string": "// keep\ny"}]}}
    expect("multiedit: moved comment ok", decision(moved), "allow")
    with open(os.path.join(tmp, "bad.odin"), "wb") as f:
        f.write(b"x := \xff\n")
    expect("write: non-utf8 existing", decision(write(os.path.join(tmp, "bad.odin"), "x := 1\n")), "allow")

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

for name, raw in [
    ("empty stdin", ""),
    ("json list", "[1]"),
    ("tool_input string", '{"tool_name":"Bash","tool_input":"git push"}'),
    ("command null", '{"tool_name":"Bash","tool_input":{"command":null}}'),
    ("file_path null", '{"tool_name":"Edit","tool_input":{"file_path":null,"new_string":null}}'),
    ("edits null", '{"tool_name":"MultiEdit","tool_input":{"file_path":"a.odin","edits":null}}'),
    ("edits junk", '{"tool_name":"MultiEdit","tool_input":{"file_path":"a.odin","edits":["x"]}}'),
]:
    code, out = run(GUARD, raw)
    expect("robust guard: " + name, (code, out.strip()), (0, ""))
expect("robust start: empty stdin", run(START, "")[0], 0)

with tempfile.TemporaryDirectory() as proj:
    os.makedirs(os.path.join(proj, "docs", "deep"))
    os.makedirs(os.path.join(proj, "src"))
    with open(os.path.join(proj, "odx.json"), "w") as f:
        f.write("{}")
    with open(os.path.join(proj, "src", "main.odin"), "w") as f:
        f.write("package main\n")
    code, out = run(START, {"cwd": os.path.join(proj, "docs", "deep")})
    expect("start: subdirectory of project injects", code == 0 and "additionalContext" in out, True)

sys.exit(1 if failures else 0)
