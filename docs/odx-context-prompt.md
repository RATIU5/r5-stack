# Context prompt for the odx repository

Paste everything below the line into a Claude Code session started in the odx repository. It is written for an agent that has not seen the r5-odin plugin.

---

You are improving odx so it works well with a Claude Code plugin named r5-odin. Do the smallest changes that earn their place. Read `CLAUDE.md`, `docs/adr/0004-principles.md` and the other ADRs first, and follow the repo's own rules, test layout (`tests/golden`) and rule-set versioning. Do not add dependencies. Ask me before any change that alters an existing finding, an exit code, the JSON schema or the rule set number. Propose each change as a short ADR-style note first, then implement only what I approve. Run `mise run test` and `mise run golden` and report the commands and exit codes. Never commit or push.

## What the plugin already does (do not duplicate it)
- Detects odx only when the project root has `odx.json` and `odx --version` exits 0. Otherwise it never mentions odx.
- Runs `odx check` after large changes with the project's pinned compiler on PATH, reports the exit code, and on exit 2 reports the error code and falls back to `odin check`. It never retries in a loop.
- Blocks the agent from adding `// odx:ignore`, `pending` entries or `odx.json` edits without asking. It lets a line that starts with `// odx:ignore` through only when an `odx.json` exists above the file.
- Teaches three frictions (`transmute` and `#no_bounds_check` banned, name case on C-ABI names, darwin_arm64 and linux_amd64 only). It does not copy odx's rule list, and it points the agent at `odx --help` and the README for rule meanings.
- Its code examples are written as multi-line blocks because `one-line-block` flagged the plugin's earlier one-line examples.

## What I measured (odx 0.2.0, rule set 2, built from a scratch copy with the repo's `build` task flags; compiler dev-2026-10-nightly:84bc3fc)
- `odx --version` prints `odx 0.2.0, rule set 2, odin dev-2026-10-nightly:84bc3fc` and exits 0 even when `odin` is not on PATH.
- `odx check` with no `odin` on PATH printed `odx: error: odin-missing: 'odin' is not on PATH` and exited 2.
- With Homebrew `dev-2026-09` first on PATH it printed `compiler-mismatch: odx.json pins odin dev-2026-10-nightly:84bc3fc, but the running compiler is dev-2026-09:a2fb372b7` and exited 2.
- `odx check` on odx's own sources: 0 findings, exit 0.
- A scratch file with a foreign procedure `strLen` (with `link_name = "strlen"`), a struct field `camelField`, `transmute(u32)x` and `#no_bounds_check` gave four findings: `name-case` for the procedure (8:2), `name-case` for the field (13:2), `transmute` (17:9) and `bounds-check-directive` (22:19), exit 1. Renaming the Odin name and keeping `link_name` is a full fix, so a foreign-block exemption for `name-case` is not needed.
- A line `// odx:ignore transmute bit pattern needed` directly above the `transmute` line gave `0 findings, 1 ignored`, exit 0.
- `odx check --json` prints `{"version":1,"findings":[{path,line,col,rule,message}],"errors":[],"summary":{findings,ignored,pending,skipped,rules,release,odin}}`.
- Not measured: `--pending`, `init`, files with parse errors, large repos.

## Requested changes, in priority order
1. **`odx rules` and `odx explain <rule>`.** Print each rule id, one-sentence rationale, the usual fix, and whether it can be ignored. Support `--json`. Today the agent must read the README table to learn what a finding means. This lets the plugin stay free of rule text. Generate the output from the same table the checker uses so it cannot drift from the README.
2. **Fix hints in finding messages.** Examples: `transmute: 'transmute' isn't allowed; use cast or restructure` and `name-case: ...; keep the C symbol with @(link_name=...) and rename the Odin name`. Keep the message short. Existing golden outputs will change, so list them for me before editing.
3. **A bounded summary for agents.** `odx check --summary` (rule id, count, first location per rule) or `--max-findings N` with the true total on the last line. A large repo currently prints every finding into the agent's context.
4. **Print the checked targets.** Add `targets: darwin_arm64, linux_amd64` to the human summary line and `"targets"` to the JSON summary. This tells an agent that Windows-only code was not checked. A `--target` flag is optional and only if it is cheap.
5. **`odx --version` and compiler health.** Decide whether `--version` should stay exit 0 without a compiler. If so, document that in `--help` and the README, because the plugin treats a working `--version` as "odx is installed" and handles `odin-missing` and `compiler-mismatch` from `odx check` itself. Document the format of `--version` as stable, or tell me it is not, so the plugin never parses it.
6. **List the error codes** (`odin-missing`, `compiler-mismatch` and the rest) in `--help` or the README with one line each, since the plugin reports them verbatim.

## Out of scope
- No hook, MCP server, plugin or Claude-specific code in odx.
- No `odx run`, `odx test` or other new verbs besides `rules` and `explain`. The old skill at `~/Documents/Skills/odin` claims `odx run` and `odx test` exist and attributes a "strict profile" to odx. Both are false, and I will remove them from that skill myself. Check that the README and `--help` do not suggest them.
- No change to rule behavior for `one-line-block`, `transmute`, `bounds-check-directive` or `name-case` unless I approve it separately. One open question for me: whether `defer if err != nil {free(p)}` should count as an exempt one-line block. The plugin now avoids it, so no change is required.

## Report back
For each change: the file list, the commands you ran with exit codes, anything unverified, and the golden cases you added or changed.
