import glob
import json
import os
import re
import subprocess
import sys
import tempfile

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
PLUGIN = os.path.join(ROOT, "plugins", "r5-bootstrap")
SKILL = os.path.join(PLUGIN, "skills", "r5-bootstrap")
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
    if not path.endswith(".md"):
        expect(rel + ": no comments", not any(l.lstrip().startswith("#") and not l.startswith("#!") for l in lines))
    expect(rel + ": at most 80 lines", len(lines) <= 80)

for wf in glob.glob(os.path.join(SKILL, "templates", "workflows", "*.yml")):
    text = open(wf, encoding="utf-8").read()
    expect(os.path.basename(wf) + ": actions use @SHA token", all(u.endswith("@SHA") for u in re.findall(r"uses: (\S+)", text)))
    top = text.split("\njobs:")[0]
    expect(os.path.basename(wf) + ": no workflow-level write permissions", ": write" not in top)
    done = subprocess.run(["ruby", "-ryaml", "-e", "YAML.load_file(ARGV[0])", wf], capture_output=True)
    expect(os.path.basename(wf) + ": parses as YAML", done.returncode == 0)

def read(*parts):
    return open(os.path.join(SKILL, *parts), encoding="utf-8").read()


doc = read("templates", "docs", "WORKFLOW.md")
ci = read("templates", "workflows", "ci.yml")
mise_md = read("references", "mise.md")
expect("WORKFLOW.md: at most 100 lines", len(doc.splitlines()) <= 100)
expect("WORKFLOW.md: no dates", not re.search(r"\b\d{4}-\d\d-\d\d\b|verified", doc, re.I))
for task in set(re.findall(r"mise run ([\w:-]+)", doc)):
    expect("WORKFLOW.md: task %s is defined" % task, task in mise_md or task in ("lint", "test"))
for job in re.findall(r"^\| `([\w-]+)` \|", doc, re.M):
    expect("WORKFLOW.md: check %s is a ci.yml job" % job, re.search(r"^  %s:" % job, ci, re.M) is not None)
for job in re.findall(r"^  ([\w-]+):\n    (?:if|runs-on)", ci, re.M):
    expect("ci.yml: job %s is in WORKFLOW.md" % job, "`%s`" % job in doc)
release_msg = "chore: prepare release"
for name in ("templates/knope.toml", "templates/workflows/prepare-release.yml"):
    expect(name + ": release commit message", release_msg in read(*name.split("/")))
expect("SKILL.md: every template and script it names exists",
       all(os.path.exists(os.path.join(SKILL, p)) for p in
           ("templates/scripts/lint-commit.sh", "templates/scripts/check-changeset.sh", "templates/scripts/label-pr.sh",
            "templates/docs/WORKFLOW.md", "references/migrate.md", "templates/workflows/label-pr.yml", "templates/workflows/stale.yml")))

ignore = [l for l in read("templates", "gitignore").splitlines() if l]
expect("gitignore: only * , !*/ and anchored ! lines", all(l in ("*", "!*/") or l.startswith("!/") for l in ignore))
expect("cog.toml: hook does not skip without mise", "command -v" not in read("templates", "cog.toml"))

hook = os.path.join(PLUGIN, "scripts", "session_start.py")


def run_hook(cwd):
    done = subprocess.run([sys.executable, "-I", hook], input=json.dumps({"cwd": cwd}), capture_output=True, text=True,
                          env={"CLAUDE_PLUGIN_ROOT": PLUGIN})
    return done.stdout


with tempfile.TemporaryDirectory() as empty, tempfile.TemporaryDirectory() as marked:
    open(os.path.join(marked, "mise.toml"), "w").close()
    expect("hook: injects rules in an empty directory", "r5-bootstrap core rules" in run_hook(empty))
    expect("hook: injects rules with mise.toml", "r5-bootstrap core rules" in run_hook(marked))
    expect("hook: output is valid additionalContext JSON",
           json.loads(run_hook(empty))["hookSpecificOutput"]["hookEventName"] == "SessionStart")

sys.exit(1 if failures else 0)
