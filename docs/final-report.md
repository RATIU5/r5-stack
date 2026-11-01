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
- `[src]` tags in `allocators.md` (thread safety, cost claims, Dynamic_Arena defaults, tlsf bounds, Scratch backup behavior).
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
- Unverified odx claims: everything about odx comes from its docs. I never ran the real tool.

## Interrogate results (3 reviewers, effort high, high, medium)
- Docs reviewer (sonnet): 3 real errors, all fixed. `a = nil` inside a defer does not reach the caller. An enum-indexed array failed with a gapped enum. A `find` sample had no return.
- Constraint reviewer (haiku): 2 findings, both dismissed. One was my stage A note naming `fable`. The other was the three odx frictions your addendum required.
- Hook reviewer (opus): findings below. I reproduced 6 of them and have not fixed any.

### Open hook findings
1. The git guard is a regex. It misses `env git commit`, `command git commit`, `sudo git push`, `sh -c 'git commit'`, `git -c alias.ci=commit ci`, `{ git push; }` and similar. It stops accidents. It is not a sandbox.
2. A trailing `// ---` or `// TODO-UPDATE-COMMENT` on a code line is exempt, though only line-initial comments should be. Nested `/* /* */ */` and a block reopened on the same line are missed.
3. Multi-line raw strings are not tracked, so a `//` inside one is denied wrongly.
4. Empty stdin, `null` fields or a non-UTF-8 file make `guard.py` and `session_start.py` exit 1 with a traceback. The tool call is not blocked in that case.
5. `session_start.py` searches only downward from the working directory. It misses a session started in a subdirectory of an Odin project, and it injects for a directory with an Odin file three levels down.

## Review first
1. The open hook findings, and whether to fix them.
2. `rules/core.md`, because it is the single source of the rules.
3. `allocators.md`, the largest file, with the `[src]` items.

## Changes for the odx owner (ask first, not done)
A. Exempt foreign blocks from the `name-case` rule.
B. Make the README and `--help` say `odx test` and `odx run` do not exist, and remove the false claims from `~/Documents/Skills/odin` once r5-odin replaces it.
C. Add `--max-findings N` or `--summary`.
D. Confirm and document the stable `odx --version` format.
E. Add a note or `--target` for Windows-only code that odx does not check.

## Old skill (`~/Documents/Skills/odin`)
Unedited. It had the false `odx run` and `odx test` claims, and a "strict profile" attributed to odx. I did not re-audit it for other gaps this stage; the earlier digest is in the stage A scratch notes.

## Friction found
The agent reads `rules/core.md` from the plugin directory, which is outside the project. In a headless run that read was denied until the directory was added with `--add-dir`. An interactive session may prompt each time. A fix is to allow reads of the plugin directory in your own settings. I did not touch settings.
