import glob
import json
import os
import re
import sys

REPO = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
failures = []


def expect(name, ok):
    print("%s %s" % ("ok  " if ok else "FAIL", name))
    if not ok:
        failures.append(name)


def frontmatter(path):
    text = open(path, encoding="utf-8").read()
    match = re.match(r"^---\n(.*?)\n---\n", text, re.S)
    if not match:
        return None
    fields = {}
    for line in match.group(1).split("\n"):
        key, sep, value = line.partition(":")
        if not sep or line.startswith(" "):
            return None
        fields[key.strip()] = value.strip()
    return fields


def line_count(path):
    return len(open(path, encoding="utf-8").read().splitlines())


def changelog_version(plugin):
    text = open(os.path.join(REPO, "CHANGELOG.md"), encoding="utf-8").read()
    match = re.search(r"^### %s (\S+)$" % re.escape(plugin), text, re.M)
    return match.group(1) if match else None


marketplace = json.load(open(os.path.join(REPO, ".claude-plugin", "marketplace.json")))
listed = {p["name"]: p["source"] for p in marketplace["plugins"]}

for plugin_dir in sorted(glob.glob(os.path.join(REPO, "plugins", "*"))):
    plugin = os.path.basename(plugin_dir)
    manifest = json.load(open(os.path.join(plugin_dir, ".claude-plugin", "plugin.json")))
    expect(plugin + ": manifest name matches folder", manifest["name"] == plugin)
    expect(plugin + ": listed in marketplace", listed.get(plugin) == "./plugins/" + plugin)
    expect(plugin + ": name is not a bare r5", plugin != "r5")
    expect(plugin + ": version matches changelog", manifest.get("version") == changelog_version(plugin))

    for skill in sorted(glob.glob(os.path.join(plugin_dir, "skills", "*", "SKILL.md"))):
        name = os.path.basename(os.path.dirname(skill))
        fields = frontmatter(skill)
        expect("%s skill %s: frontmatter parses" % (plugin, name), fields is not None)
        fields = fields or {}
        expect("%s skill %s: name matches folder" % (plugin, name), fields.get("name") == name)
        description = fields.get("description", "")
        expect("%s skill %s: one-sentence description" % (plugin, name), description.endswith(".") and description.count(". ") == 0)
        expect("%s skill %s: at most 60 lines" % (plugin, name), line_count(skill) <= 60)
        if name.endswith("-mode"):
            expect("%s skill %s: manual only" % (plugin, name), fields.get("disable-model-invocation") == "true")

    for reference in glob.glob(os.path.join(plugin_dir, "skills", "*", "references", "*.md")):
        expect("%s: %s at most 250 lines" % (plugin, os.path.basename(reference)), line_count(reference) <= 250)

    for agent in sorted(glob.glob(os.path.join(plugin_dir, "agents", "*.md"))):
        name = os.path.splitext(os.path.basename(agent))[0]
        fields = frontmatter(agent)
        expect("%s agent %s: frontmatter parses" % (plugin, name), fields is not None)
        fields = fields or {}
        expect("%s agent %s: name matches file" % (plugin, name), fields.get("name") == name)
        expect("%s agent %s: model pinned" % (plugin, name), bool(fields.get("model")))
        expect("%s agent %s: effort is medium or high" % (plugin, name), fields.get("effort") in ("medium", "high"))
        expect("%s agent %s: model is not fable" % (plugin, name), "fable" not in fields.get("model", "").lower())

    rules = os.path.join(plugin_dir, "rules", "core.md")
    if os.path.isfile(rules):
        expect(plugin + ": core rules at most 40 lines", line_count(rules) <= 40)

    hooks = json.load(open(os.path.join(plugin_dir, "hooks", "hooks.json")))
    for event, groups in hooks["hooks"].items():
        for group in groups:
            for hook in group["hooks"]:
                for arg in hook.get("args", []):
                    if "${CLAUDE_PLUGIN_ROOT}" in arg:
                        path = arg.replace("${CLAUDE_PLUGIN_ROOT}", plugin_dir)
                        expect("%s hook %s: %s exists" % (plugin, event, os.path.basename(path)), os.path.isfile(path))

sys.exit(1 if failures else 0)
