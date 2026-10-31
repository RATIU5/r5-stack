---
name: odin
description: Write, review and debug Odin code (syntax, idioms, errors, tests, verification) using references verified against a real compiler.
---

# Odin

Verified against Odin dev-2026-10, compiler `dev-2026-10-nightly:84bc3fc`. Remembered APIs are often stale: check the signature in the core library before using one you are unsure of.
A project's pinned compiler wins over this version. Never suggest bumping the compiler, or an odx rule set, unprompted.

## First
- Match the project: read its build script, CI flags, `ols.json`, `odinfmt.json`, test layout and file tags before changing anything.
- Read and search existing code before writing. Check the compiler: `odin version`, `odin root`.

## References (grep headings, read one section)
- `references/syntax.md`: syntax, control flow, errors, memory basics, constructs other languages emit that fail here.
- `references/allocators.md`: pick an allocator per lifetime (complexity ladder, decision table, catalog, custom pool and frame arena, temp scoping, tracking, measuring).
- `references/idioms.md`: how to check an idiom against the core library.

## Style
- Imperative and procedural. Procedures on data, no methods, no wrapper types. Built-in `[dynamic]`, `map`, slices.
- Put `defer delete(x)` or `defer free(p)` on the line after the allocation.
- Fallible procs use named results. Cleanup that only runs on failure: `defer if err != nil {free(p)}`, then `err = .X` and a bare `return`.
- Library procs take `allocator := context.allocator` and pass it down. Applications may use `context.allocator`.
- Keep `main` thin. Put logic in packages that tests can call.
- Handle an error where it happens. Translate at package boundaries. Errors are for environment causes, `assert` is for programmer bugs.
- Tests: `@(test)`, a `defer delete` beside each test allocation, table cases covering every error variant. `odin test` logs leaks as warnings but still exits 0, so read its output.

## Writing
- Name the data shape first. State the allocator and lifetime of each allocation.
- No implicit numeric conversion. Use `cast(T)x` or `T(x)`.
- Odin has no `#run`, no exceptions, no `i++`. See the syntax table.

## Debugging
- Reproduce first. Say what was reproduced and what was not.
- Claim "compiles", "passes" or "does not leak" only after the command that shows it. Report the command and exit code.

## Verification
- `odin check <pkg>` with the project's flags (default `-vet -vet-cast -strict-style`), then `odin test <pkg>`, then a real run. Fix the code; never disable a check.
- When odx is enabled (`odx.json` in the project root and `odx --version` runs): run `odx check` with the project's pinned compiler on PATH (see `mise.toml`, `odx.json` "odin"). On exit 2 report the error code and fall back to `odin check`; never retry in a loop. For a rule's meaning read `odx --help` or the project README.

## Reviews
- Report findings as `file:line - problem - why it matters`, marked confirmed or "(unconfirmed)". Silent bugs first, then rule violations. Do not rewrite unless asked.
