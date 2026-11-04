import glob
import json
import os
import re
import subprocess
import sys
import tempfile

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
PLUGIN = os.path.join(ROOT, "plugins", "r5-pipeline")
SKILL = os.path.join(PLUGIN, "skills", "r5-pipeline")
failures = []


def expect(name, ok):
    print("%s %s" % ("ok  " if ok else "FAIL", name))
    if not ok:
        failures.append(name)


for md in glob.glob(os.path.join(SKILL, "**", "*.md"), recursive=True):
    text = open(md, encoding="utf-8").read()
    rel = os.path.relpath(md, SKILL)
    expect(rel + ": at most 200 lines", len(text.splitlines()) <= 200)
    expect(rel + ": no version or date text", not re.search(r"\b\d{4}-\d\d-\d\d\b|verified|checked \d", text, re.I))

for path in glob.glob(os.path.join(SKILL, "templates", "**", "*"), recursive=True):
    if not os.path.isfile(path):
        continue
    rel = os.path.relpath(path, SKILL)
    lines = open(path, encoding="utf-8").read().splitlines()
    expect(rel + ": no comments", not any(l.lstrip().startswith("#") for l in lines))
    expect(rel + ": at most 80 lines", len(lines) <= 80)

for wf in glob.glob(os.path.join(SKILL, "templates", "workflows", "*.yml")):
    text = open(wf, encoding="utf-8").read()
    expect(os.path.basename(wf) + ": actions use @SHA token", all(u.endswith("@SHA") for u in re.findall(r"uses: (\S+)", text)))
    done = subprocess.run(["ruby", "-ryaml", "-e", "YAML.load_file(ARGV[0])", wf], capture_output=True)
    expect(os.path.basename(wf) + ": parses as YAML", done.returncode == 0)

hook = os.path.join(PLUGIN, "scripts", "session_start.py")


def run_hook(cwd):
    done = subprocess.run([sys.executable, "-I", hook], input=json.dumps({"cwd": cwd}), capture_output=True, text=True,
                          env={"CLAUDE_PLUGIN_ROOT": PLUGIN})
    return done.stdout


with tempfile.TemporaryDirectory() as empty, tempfile.TemporaryDirectory() as marked:
    open(os.path.join(marked, "mise.toml"), "w").close()
    expect("hook: silent without mise.toml or knope.toml", run_hook(empty) == "")
    out = run_hook(marked)
    expect("hook: injects rules with mise.toml", "r5-pipeline core rules" in out)

sys.exit(1 if failures else 0)
