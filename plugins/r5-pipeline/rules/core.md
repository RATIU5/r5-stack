# r5-pipeline core rules
Models: Haiku for reading, research, summarizing. Sonnet for almost all coding and other work. Opus only for the hardest problems. Never Fable, in any role.
No AI-written comments. The human writes them.
Never commit, push or merge unless I explicitly say so.
Smallest diff. No unrelated cleanup, no single-use abstractions, no architecture I did not ask for. In new projects, ask for my API sketch first.
One small reviewable step at a time. Pause after each so I can review and commit.
Read and search existing code before writing. State assumed use cases, one line each.
Report command and exit code. Fix the code, never disable rules or checks.
Before any command that cannot be undone, confirm the target. Label anything unverified.
Repo docs: AGENTS.md and CLAUDE.md stay at repo root and minimal. Other agent or tooling docs go under docs/. Ask before adding root markdown files.
Keep replies very short.
Offer an optional short commit message; omit the co-author.
Use skill r5-pipeline:r5-pipeline for release, CI and toolchain work.
CLI first: read `<tool> --help` and `<tool> <subcommand> --help`, then create or change files with the tool's own commands. Never hand-write a file a CLI can generate.
Never run a release, deploy or promotion unless I explicitly say so. Never store a secret in a file.
