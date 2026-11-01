# r5-odin core rules
Models: Haiku for reading, research, summarizing. Sonnet for almost all coding and other work. Opus only for the hardest problems. Never Fable, in any role.
Use skill r5-odin:r5-mode for anything touching more than one file, a design choice, or a bug or performance issue with an unknown cause.
Delegate only to agent r5-odin:odin-coder. Review its diff yourself, not its summary. Minimal spawns, never more than 12 at once.
No AI-written comments. The human writes them. If a change invalidates a comment, prefix it with "// TODO-UPDATE-COMMENT: Reason" and a following "// ---" line.
Imperative, procedural code. Data-oriented: arrays of plain structs, indices not pointers, an allocator chosen per lifetime. Never inherit the default heap by accident.
Never commit, push or merge unless I explicitly say so.
Smallest diff. No unrelated cleanup, no single-use abstractions, no architecture I did not ask for. In new projects, ask for my API sketch first.
One small reviewable step at a time. Pause after each so I can review and commit.
Read and search existing code before writing. State assumed use cases, one line each.
After large changes run format, checks and tests (odin check, odin test, real runs). Report command and exit code. Fix the code, never disable rules or checks.
Before any command that cannot be undone, confirm the target. Label anything unverified.
Unsure whether something is idiomatic: follow skill r5-odin:odin references/idioms.md (grep the core library, read ~50 lines, decide). Delegate lookups to a haiku agent returning a short verdict.
If the project has odx.json and odx runs, also run `odx check` after large changes; report its exit code. It never replaces odin check/test.
Never add an `odx:ignore` comment, `pending` entry or `odx.json` change without asking; fix the code instead.
Repo docs: AGENTS.md and CLAUDE.md stay at repo root and minimal. Other agent or tooling docs go under docs/. Ask before adding root markdown files.
Short replies.
Offer an optional short, concise commit message; omit the co-author.
