# r5-stack

My personal Claude Code plugins for various programming languages and tasks.

| Plugin    | What it does                                                                                       |
| --------- | -------------------------------------------------------------------------------------------------- |
| `r5-odin` | Rules, skills, an agent and guard hooks for writing Odin, including allocators, C mapping and FFI. |

## Install

In Claude Code:

```
/plugin marketplace add RATIU5/r5-stack
/plugin install r5-odin@r5-stack
```

Or from a shell:

```bash
claude plugin marketplace add RATIU5/r5-stack
claude plugin install r5-odin@r5-stack
```

### Requirements

- Claude Code with plugin support.
- `python3` on PATH for the hooks.
- Odin on PATH for the checks the rules ask for. Examples were checked with Odin dev-2026-10 on 64-bit macOS. Linux and Windows were not run.

## Layout

```
.claude-plugin/marketplace.json
plugins/r5-odin/           the plugin
tests/r5-odin/             hook tests and the allocator test suite
```

Run the tests from the repo root:

```bash
python3 -I tests/r5-odin/test_hooks.py
python3 -I tests/r5-odin/test_manifest.py
odin test tests/r5-odin/allocators -vet -strict-style
claude plugin validate .
```

An opt-in end-to-end check runs real `claude -p` sessions and makes API calls:

```bash
tests/r5-odin/e2e.sh
```

A small eval set compares Odin tasks with and without the plugin. Each task has a prompt, a stub, a reference solution and a grader that runs `odin test`. The self-check needs no API calls. The run does:

```bash
python3 -I tests/r5-odin/evals/test_measure.py
tests/r5-odin/evals/selfcheck.sh
tests/r5-odin/evals/run.sh with 3
tests/r5-odin/evals/run.sh without 3
tests/r5-odin/evals/run.sh none 3
```

Modes: `with` loads the plugin, `without` is your normal setup, and `none` also blocks a user skill named `odin`. `measure.py` runs a built program with a time limit and a memory cap and reports peak memory.

## License

MIT. See `LICENSE`.
