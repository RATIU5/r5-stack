# Odin

Installed by mise: `mise use --pin odin`. The archive is one folder (`odin`, `base/`, `core/`, `vendor/`); never move only the binary. Linking needs a system clang on the runner: make the first build step `clang --version`.

## Version
- One `VERSION` file per component, plain `x.y.z`. Knope reads it with `{ path = "VERSION", regex = '(?<version>\d+\.\d+\.\d+)' }`.
- Embed it with `VERSION :: #load("../VERSION", string)` in the main package, using the relative path from that package's folder. No generated file.

## Tasks
- `build`: `odin build <pkg> -out:dist/<name> -vet -strict-style`.
- `test`: `odin test <pkg> -vet -strict-style`.
- `lint`: `odin check <pkg> -vet -vet-cast -strict-style`.
- Reuse the project's own flags when it already has them.

## Dependencies
Vendor under `vendor/<name>/` or use a git submodule pinned to a commit.
