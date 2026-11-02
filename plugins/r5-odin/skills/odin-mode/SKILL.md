---
name: odin-mode
description: Manually invoked procedure for Odin work that spans several files, a design choice, or a bug or slowdown with an unknown cause.
disable-model-invocation: true
---

# odin mode

1. State the goal and the smallest change that meets it, in two lines.
2. Name the data shape. For every allocation name the allocator and its lifetime (skill `r5-odin:odin`, `references/allocators.md`).
3. Bug or slowdown: reproduce first with a command. Say what reproduced and what did not. For speed, measure before and after.
4. Make the smallest change. No unrelated cleanup, no abstraction with one caller.
5. Delegate only independent coding, to agent `r5-odin:odin-coder`, with an explicit model. Review its diff yourself.
6. Verify with commands: `odin check` with the project's flags, `odin test`, a real run. Report each command and its exit code.
7. odx is enabled only if `odx.json` is in the project root and `odx --version` succeeds. Check that first, and otherwise never run or mention odx. When enabled, run `odx check` with the project's pinned compiler on PATH (see `mise.toml`, `odx.json` "odin"). On exit 2 report the error code and fall back to `odin check`; never retry in a loop. For a rule's meaning run `odx explain <rule>` (older odx: read `odx --help`). Cap long output with `odx check --max-findings 20`.
8. Summarize in at most 10 lines: what changed, which files, the evidence, what is unverified. Offer an optional short commit message. Do not commit.
9. Stop and wait for review.
