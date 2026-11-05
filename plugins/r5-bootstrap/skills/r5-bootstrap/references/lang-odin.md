# Odin

Installed by mise: `mise use --pin odin ols` (`ols` provides `odinfmt`). The archive is one folder (`odin`, `base/`, `core/`, `vendor/`); never move only the binary. Linking needs a system clang on the runner: add a `clang --version` step before `mise run build` in `ci.yml` and `release.yml`.

## Version
- One `VERSION` file per component, plain `x.y.z`. Create it with `1.0.0` when absent. Knope reads it with `{ path = "VERSION", regex = '(?<version>\d+\.\d+\.\d+(?:-[0-9A-Za-z.]+)?)' }`.
- Embed it with `VERSION :: #load("../VERSION", string)` in the main package, using the relative path from that package's folder. No generated file.

## Tasks
- `build`: `odin build <pkg> -out:dist/<name> -vet -strict-style`.
- `test`: `odin test <pkg> -vet -strict-style`.
- `lint`: `odin check <pkg> -vet -vet-cast -strict-style`.
- `fmt`: `odinfmt -w <pkg>` (confirm with `odinfmt --help`). `fmt:check` is the same without `-w` when the installed version supports it.
- `odx check` only when the project root has `odx.json` and `odx --version` works. Otherwise never run or mention odx.
- Reuse the project's own flags when it already has them.

## Dependencies
Vendor under `vendor/<name>/` or use a git submodule pinned to a commit.
