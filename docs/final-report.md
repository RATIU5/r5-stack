# r5-odin final report

Built and checked against Odin dev-2026-10 (`dev-2026-10-nightly:84bc3fc`) on darwin_arm64. Nothing is committed, installed or enabled.

## Files and context cost
Measured with `claude -p "/context" --model sonnet --plugin-dir .` in a scratch Odin project, against the same run without the plugin.

| File | Lines | Cost |
|---|---|---|
| `rules/core.md` | 18 | About 800 tokens in the Messages category, only when the session starts inside an Odin project. 0 elsewhere. |
| `skills/odin/SKILL.md` | 46 | Listing about 50 tokens. Body loads when the skill runs. |
| `agents/odin-coder.md` | 14 | Listing 49 tokens. Body loads when spawned. |
| `skills/r5-mode/SKILL.md` | 17 | 0 (manual only). Not listed in `/context`. |
| `skills/odin/references/*.md` | 19 to 227 | 0 until read. |
| `hooks/hooks.json`, `scripts/*.py` | 27, 141, 36 | 0 tokens. Hooks run outside the model. |
| `tests/test_hooks.py`, `docs/` | 111, 42 | 0. |

Always-loaded lines (rules plus descriptions): 18 plus 2 = 20, under the 60 limit.

## Verified by real runs
- The agent resolves `${CLAUDE_PLUGIN_ROOT}` in its body, runs as Sonnet 5.5 with no model passed, and read `rules/core.md`.
- A real Agent call with `model: fable` is denied by the hook, so `tool_input.model` is visible.
- `/r5-odin:r5-mode` runs by hand.
- 29 hook tests pass. `claude plugin validate .` passes with directory warnings (README, LICENSE, icon, author).

## Unverified
- `[src]` tags in `allocators.md` that remain (thread safety, cost claims, tlsf bounds and double-free assert, Tracking's default panic, lazy commit). 23 `odin test` cases in `tests/allocators` turned other `[src]` claims into `[run]` and corrected one: Dynamic_Arena accepts requests above its block size.
- Linux and Windows branches, `odin-c-bindgen`, non-C callers of exported procedures, larger exported libraries.
- That Odin `free` on C memory breaks off Unix.
- The `syntax.md` samples were compiled earlier as fragments. Only the lines the reviewers retried were rechecked this stage.

## odx interaction
- Context cost of each odx line: `core.md` has two lines (estimated, not measured separately, at about 110 tokens together), `SKILL.md` one bullet, `r5-mode` one step. The odx notes in `allocators.md` and `ffi.md` cost 0 until read.
- Scenarios, run with `claude -p` in scratch copies. (b) used a stub `odx` that only prints a version, because odx must not be installed.
  - (a) no `odx.json`: ran `odin check` and `odin test`, never ran odx.
  - (b) `odx.json` and a working `odx`: ran `odx --version`, then `odx check`.
  - (c) `odx.json`, no `odx`: ran `odx --version` (exit 127), then no further odx command. The first run of (c) failed this test: the model ran `odx check` anyway. I rewrote the rule to probe `odx --version` first and treat a failure as absent, and the retest passed.
  - (a) and (c) both skip odx, but the model still mentions odx in its summary when asked to list commands. "Say nothing" is a soft instruction.
- Hook exemption: a line starting `// odx:ignore` is allowed only when `odx.json` exists in the file's directory or above. Four tests pass.
- odx was built from a scratch copy of its repo and run (0.2.0, rule set 2). The three frictions, `odx:ignore`, the JSON shape, exit 2 for `odin-missing` and `compiler-mismatch`, and a clean self-check were all confirmed. Not run: `--pending`, `init`, large repos.
- Found by running odx: its `one-line-block` rule flagged the plugin's one-line examples, so every code example is now multi-line and checks clean under odx.

## Interrogate results (3 reviewers, effort high, high, medium)
- Docs reviewer (sonnet): 3 real errors, all fixed. `a = nil` inside a defer does not reach the caller. An enum-indexed array failed with a gapped enum. A `find` sample had no return.
- Constraint reviewer (haiku): 2 findings, both dismissed. One was my stage A note naming `fable`. The other was the three odx frictions your addendum required.
- Hook reviewer (opus): findings below. I reproduced 6 of them and have not fixed any.

### Hook findings, fixed after the review
The git guard now tokenizes each command segment. It handles wrappers (`env`, `sudo`, `command`, `xargs`, `eval`, `time`, `!`), variable assignments, quoting, `sh -c` and here-strings, `-c alias.x=commit`, `--git-dir`, `{ }` and `if` forms. It is still a guard against accidents, not a sandbox. The comment scanner tracks nested blocks, reopened blocks and multi-line raw strings, and a trailing `// ---` is no longer exempt. Both hooks fail open with no traceback on bad input, and `session_start.py` also finds markers in ancestor directories. 73 hook tests pass.

## Review first
1. `docs/odx-context-prompt.md`, the prompt for the odx owner.
2. `scripts/guard.py`, rewritten.
3. The multi-line example rewrite across `references/`.

## Changes for the odx owner
Superseded by `docs/odx-context-prompt.md`, which also records that change A is not needed. The original list:
A. Exempt foreign blocks from the `name-case` rule.
B. Make the README and `--help` say `odx test` and `odx run` do not exist, and remove the false claims from `~/Documents/Skills/odin` once r5-odin replaces it.
C. Add `--max-findings N` or `--summary`.
D. Confirm and document the stable `odx --version` format.
E. Add a note or `--target` for Windows-only code that odx does not check.

## Old skill (`~/Documents/Skills/odin`)
Unedited. It had the false `odx run` and `odx test` claims, and a "strict profile" attributed to odx. I did not re-audit it for other gaps this stage; the earlier digest is in the stage A scratch notes.

## Friction found
The agent reads `rules/core.md` from the plugin directory, which is outside the project. In a headless run that read was denied until the directory was added with `--add-dir`. An interactive session may prompt each time. A fix is to allow reads of the plugin directory in your own settings. I did not touch settings.
