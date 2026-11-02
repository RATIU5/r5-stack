import json
import sys


def main():
    measure = json.load(open(sys.argv[1]))
    raw = open(sys.argv[2]).read()
    output = {}
    for line in raw.splitlines():
        key, _, value = line.partition(" ")
        output[key] = value.strip()
    ok = measure["exit"] == 0 and measure["killed"] is None
    args = sys.argv[3:]
    i = 0
    while i < len(args):
        kind, key, value = args[i], args[i + 1], args[i + 2]
        i += 3
        if kind == "equals":
            ok = ok and output.get(key) == value
        elif kind == "max":
            ok = ok and key in output and float(output[key]) <= float(value)
        elif kind == "min":
            ok = ok and key in output and float(output[key]) >= float(value)
        elif kind == "max-rss":
            ok = ok and measure["peak_rss_mb"] <= float(value)
        elif kind == "absent":
            ok = ok and value not in raw
    print(json.dumps({"measure": measure, "output": output, "ok": ok}))
    return 0 if ok else 1


sys.exit(main())
