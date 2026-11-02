import json
import os
import subprocess
import sys
import tempfile

MEASURE = os.path.join(os.path.dirname(os.path.abspath(__file__)), "measure.py")
failures = []


def run(args):
    out = os.path.join(tempfile.mkdtemp(), "out.txt")
    proc = subprocess.run(["python3", "-I", MEASURE, "--out", out] + args, capture_output=True, text=True, timeout=60)
    return json.loads(proc.stdout.strip().splitlines()[-1]), open(out).read()


def expect(name, ok):
    print("%s %s" % ("ok  " if ok else "FAIL", name))
    if not ok:
        failures.append(name)


result, text = run(["--", "python3", "-c", "print('hi')"])
expect("normal exit is reported", result["exit"] == 0 and result["killed"] is None and text.strip() == "hi")

result, _ = run(["--", "python3", "-c", "import sys; sys.exit(3)"])
expect("exit code is passed through", result["exit"] == 3)

result, _ = run(["--timeout", "1", "--", "sleep", "5"])
expect("timeout kills the process", result["killed"] == "timeout" and result["seconds"] < 4)

result, _ = run(["--max-mb", "150", "--timeout", "20", "--", "python3", "-c", "import time; x = bytes([1]) * (600 * 1024 * 1024); time.sleep(5)"])
expect("memory limit kills the process", result["killed"] == "memory" and result["peak_rss_mb"] > 150)

result, _ = run(["--", "python3", "-c", "x = bytes([1]) * (50 * 1024 * 1024)"])
expect("peak memory is measured", result["peak_rss_mb"] > 40 or result["seconds"] < 0.2)

sys.exit(1 if failures else 0)
