# Idiom check against the core library

Use when unsure whether a construct is idiomatic or current. The core library is the reference: it is written by the compiler authors and compiled with every release. Never read it wholesale.

## Procedure
1. Find the library for the compiler the project uses: `ROOT=$(odin root)`. Source is under `$ROOT/core`, `$ROOT/base`, `$ROOT/vendor`. `odin root` prints a directory containing `core/`.
2. Grep for the specific construct, not the topic: `rg -n 'or_return' $ROOT/core/bufio`, `rg -n '^clone ::' $ROOT/core/strings`.
3. Read only the ~50 lines around the best hit. Prefer hits in several packages over a single one.
4. Decide: if the core library uses it routinely, it is idiomatic. If it uses it nowhere, or only in tests and examples, treat it as unusual and prefer the form that appears.
5. Apply it, then confirm with `odin check`. Move on; do not browse.

## Delegating
Give agent `r5-odin:odin-coder`, with model haiku, the construct, the package to grep and the question. Ask for a verdict of at most 5 lines: idiomatic yes/no/unusual, one file:line citation, the preferred form. Review the citation yourself if the decision matters.

## Signatures worth checking before use
Allocator parameters, error returns and `#optional_allocator_error` change between releases. Example from dev-2026-10: `strings.clone :: proc(s: string, allocator := context.allocator, loc := #caller_location) -> (res: string, err: runtime.Allocator_Error) #optional_allocator_error`. Read the declaration with `rg -n '^name ::' $ROOT/core/<pkg>` before calling a proc you remember from an older release.

## Versions
A project's pinned compiler wins over the release these examples were checked with. Grep that compiler's `odin root`. Never suggest bumping the compiler.
