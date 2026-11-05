# r5-odin core rules
Models: Haiku for reading, research, summarizing. Sonnet for almost all coding and other work. Opus only for the hardest problems. Never Fable, in any role.
Use skill r5-odin:odin-mode for anything touching more than one file, a design choice, or a bug or performance issue with an unknown cause.
Delegate only to agent r5-odin:odin-coder, passing a model each time. Review its diff yourself, not its summary. Minimal spawns, never more than 12 at once.
No AI-written comments. The human writes them. If a change invalidates a comment, prefix it with "// TODO-UPDATE-COMMENT: Reason" and a following "// ---" line.
Imperative, procedural code. Data-oriented: arrays of plain structs, indices not pointers, an allocator chosen per lifetime. Never inherit the default heap by accident.
Never commit, push or merge on your own, and never ask whether to commit. Commit only when I tell you to, then do it without asking for confirmation.
Smallest diff. No unrelated cleanup, no single-use abstractions, no architecture I did not ask for. In new projects, ask for my API sketch first.
One small reviewable step at a time. Pause after each so I can review and commit.
Read and search existing code before writing. State assumed use cases, one line each.
After large changes run format, checks and tests (odin check, odin test, real runs). Report command and exit code. Fix the code, never disable rules or checks.
Before any command that cannot be undone, confirm the target. Label anything unverified.
Unsure whether something is idiomatic: follow skill r5-odin:odin references/idioms.md (grep the core library, read ~50 lines, decide). Delegate lookups to r5-odin:odin-coder with model haiku, asking for a short verdict.
odx is optional and silent. No odx.json in the project root: never run or mention odx. With odx.json, run `odx --version` first; if it fails, treat odx as absent, never run or mention it. If it works, also run `odx check` after large changes and report its exit code. It never replaces odin check/test.
Never add an `odx:ignore` comment, `pending` entry or `odx.json` change without asking; fix the code instead.
Repo docs: AGENTS.md and CLAUDE.md stay at repo root and minimal. Other agent or tooling docs go under docs/. Ask before adding root markdown files.
Keep replies very short.
When work is done, end with one short line suggesting I review and commit, plus a short, concise commit message; omit the co-author. If the changes are too large for one commit, suggest how to split them into separate commits.
