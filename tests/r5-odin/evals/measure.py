import argparse
import json
import os
import signal
import subprocess
import sys
import time


def rss_mb(pid):
    try:
        out = subprocess.run(["ps", "-o", "rss=", "-p", str(pid)], capture_output=True, text=True, timeout=2).stdout
        return int(out.strip()) / 1024 if out.strip() else 0.0
    except (subprocess.SubprocessError, ValueError):
        return 0.0


def kill_group(proc):
    try:
        os.killpg(proc.pid, signal.SIGKILL)
    except (ProcessLookupError, PermissionError):
        pass


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--timeout", type=float, default=20)
    parser.add_argument("--max-mb", type=float, default=1024)
    parser.add_argument("--out", default=os.devnull)
    parser.add_argument("command", nargs=argparse.REMAINDER)
    args = parser.parse_args()
    command = args.command[1:] if args.command and args.command[0] == "--" else args.command
    if not command:
        print(json.dumps({"error": "no command"}))
        return 2
    start = time.time()
    peak = 0.0
    killed = None
    with open(args.out, "w") as out:
        proc = subprocess.Popen(command, stdout=out, stderr=subprocess.STDOUT, start_new_session=True)
        while proc.poll() is None:
            peak = max(peak, rss_mb(proc.pid))
            if peak > args.max_mb:
                killed = "memory"
            elif time.time() - start > args.timeout:
                killed = "timeout"
            if killed:
                kill_group(proc)
                proc.wait()
                break
            time.sleep(0.02)
    print(json.dumps({
        "exit": proc.returncode,
        "peak_rss_mb": round(peak, 1),
        "seconds": round(time.time() - start, 2),
        "killed": killed,
    }))
    return 0


sys.exit(main())
