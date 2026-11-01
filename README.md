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
odin test tests/r5-odin/allocators -vet -strict-style
claude plugin validate .
```

## License

MIT. See `LICENSE`.
