# Odin

Checked 2026-11-04 against Odin dev-2026-11a (published 2026-11-03). Confirm with `odin version`. Core rules live in `core-toolchain.md`. For writing Odin code use skill `r5-odin:odin`.

## Version source
- One `VERSION` file per component, plain `x.y.z`.
- Knope reads and writes it with a regex entry: `versioned_files = [{ path = "apps/tool/VERSION", regex = '(?<version>\d+\.\d+\.\d+)' }]`. Native `VERSION` support does not exist.
- `scripts/version-generate.sh <VERSION> <out.odin> <package>` writes the generated source (`VERSION :: "x.y.z"`). Source: `templates/version-generate.sh`.
- Tasks: `version:generate` runs it. `version:check` runs it with `--check` and fails if the file is stale. `build` depends on `version:generate`. `lint` depends on `version:check`, so CI fails on drift.
- Add a `Command` step after `PrepareRelease` running `mise run version:generate`, so the release PR carries the new generated file. The template commit step uses `git commit -a`, so tracked changes are included.
- Commit the generated file. Do not edit it.

## Compiler
- Order of preference, verified in this order:
  1. `mise use --pin odin@<tag>`. The registry already maps `odin` to `github:odin-lang/Odin`. Tested: installs `dev-2026-11a`, `odin version` runs, a program builds and runs with the system clang. `mise lock` records sha256 per platform.
  2. A private vfox Lua plugin pinned by commit SHA in `[plugins]`, only if the github backend breaks.
  3. `asdf:jtakakura/asdf-odin`: avoid. Last push 2025-01-09. Registry lists it second.
- Release assets: `odin-linux-amd64-<tag>.tar.gz`, `odin-linux-arm64-<tag>.tar.gz`, `odin-macos-arm64-<tag>.tar.gz`, `odin-windows-amd64-<tag>.zip`. No macOS amd64 asset.
- No `SHA256SUMS` and no attestation published. GitHub reports a sha256 digest per asset. mise records it in the lock.
- Archive is flat: `odin`, `base/`, `core/`, `vendor/`, `shared/` side by side. The compiler needs them together, so never move only the binary.
- `odin version` prints `odin version <tag>:<commit>`. Nightly builds print `dev-YYYY-MM-nightly`.
- Pin the exact tag. A project's pinned compiler wins. Never bump it unprompted.

## Runner dependencies
- Odin docs: Unix release builds need clang for linking, macOS needs Xcode command line tools, Windows needs MSVC and the Windows SDK. Odin's own CI uses LLVM 22 to build the compiler, which release users do not need.
- mise registry has no `llvm`. `clang` maps to `conda:clang`, `asdf:mise-plugins/mise-llvm`, `vfox:jdx/vfox-clang`. Not tested.
- Decision: the runner image provides clang. On `ubuntu-latest` run `clang --version` as the first step of the build job and fail with a clear message if missing. Whether the image ships clang: not verified.

## Dependencies
- Vendored under `vendor/<name>/` or pinned by `deps.lock`.
- `deps.lock` has one line per dependency: `name url revision sha256 path`, space separated.
- sha256 is the hash of per-file hashes: `find . -type f -not -path './.git/*' | LC_ALL=C sort | xargs shasum -a 256 | shasum -a 256`, run inside `path`.
- `deps:verify` runs `scripts/deps-verify.sh` (`templates/deps-verify.sh`). It recomputes each hash and exits 1 on mismatch. Tested.
- `deps:bump <name> <revision>`: fetch the revision into `path`, recompute the hash, rewrite that lock line, write a changeset for the component. Write `scripts/deps-bump.sh` when first needed. `knope document-change` is interactive and takes no arguments, so the script writes the `.changeset/<name>.md` file itself. Say so when you do it.

## Attestation
`actions/attest` over `dist/SHA256SUMS` in `release.yml`. The checksums file lists the Odin binaries. Verify with `gh attestation verify`.

## Tasks to add
`mise tasks add build -- odin build <pkg> -out:dist/<name> -vet -strict-style` with `depends = ["version:generate"]`. `test` runs `odin test <pkg> -vet -strict-style`. `lint` runs `odin check <pkg> -vet -vet-cast -strict-style`. `fmt` runs `odinfmt` only if the project has `odinfmt.json`. Use the project's existing flags first.
