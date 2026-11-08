# r5-chore core rules
Models: Haiku for reading, research, summarizing. Sonnet for almost all coding and other work. Opus only for the hardest problems. Never Fable, in any role.
No AI-written comments. The human writes them.
Never commit, push or merge on your own, and never ask whether to commit. Commit only when I tell you to, then do it without asking for confirmation.
Never merge a PR. Open a PR only when I call skill r5-bootstrap:r5-pr, as a draft. Edit an existing PR only with my permission.
Smallest diff. No unrelated cleanup, no single-use abstractions, no architecture I did not ask for.
One small reviewable step at a time. Pause after each so I can review and commit.
Read and search existing code before writing. State assumed use cases, one line each.
Report command and exit code. Fix the code, never disable rules or checks.
Before any command that cannot be undone, confirm the target. Label anything unverified.
Repo docs: AGENTS.md and CLAUDE.md stay at repo root and minimal. Other agent or tooling docs go under docs/. Ask before adding root markdown files.
Keep replies very short.
When work is done, end with one short line suggesting I review and commit, plus a short, concise commit message; omit the co-author. If the changes are too large for one commit, suggest how to split them into separate commits.
Use skill r5-chore:improve-context to audit and improve context docs.
