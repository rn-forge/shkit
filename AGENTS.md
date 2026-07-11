# AGENTS.md

This file provides guidance to Codex (Codex.ai/code) when working with code in this repository.

## What this is

`shkit` is a bash/zsh shell library of reusable utilities. Sourced modules live in `src/lib/` and are concatenated into a single bundle; management tooling lives alongside them: `src/rnfshk.sh` (standalone `rnfshk` dispatcher bin), `src/commands/` (its subcommands: `update`, `version`, `env`), `src/install.sh` (standalone installer — curlable directly, or delegated to by `rnfshk update` and `source.sh`), and `src/source.sh` (streaming-sourcing entry point for app/CI environments).

## Commands

All tasks are run via [mise](https://mise.jdx.dev/). [shellspec](https://shellspec.info/), [gawk](https://www.gnu.org/software/gawk/), and [kcov](https://simonkagstrom.github.io/kcov/) (coverage only) must be installed separately (not managed by mise).

```sh
mise run format        # shfmt -w (in-place)
mise run format-check  # shfmt -d (diff only, exits non-zero if dirty)
mise run lint          # shellcheck src/ scripts/ examples/
mise run test          # shellspec under the default shell (bash, per .shellspec)
mise run test-bash     # shellspec under bash
mise run test-zsh      # shellspec under zsh
mise run test-all      # shellspec under bash AND zsh
mise run coverage      # shellspec --shell bash --kcov; HTML+lcov report in coverage/
mise run build         # generate dist/shkit/ tree + tarball + loose assets
mise run docs          # generate docs/ from shdoc annotations via gawk
mise run verify        # format-check + lint + coverage + build + docs (CI; needs kcov)
mise run verify-local  # format-check + lint + test-all + build + docs (local dev; no kcov needed)
```

**`verify` vs `verify-local`:** `verify` is what CI runs and requires `kcov`, which is Linux-native — `kcov`'s ptrace-based instrumentation fails under macOS's System Integrity Protection even when `kcov` itself is installed (`kcov: error: Can't start/attach to ...`), so `mise run verify` reliably fails on a macOS dev machine at the coverage step, not because anything is broken. Use `mise run verify-local` for the equivalent local pre-push check — same pipeline, but bash+zsh test coverage (`test-all`) in place of `coverage`, which works everywhere including macOS.

Run a single spec file:
```sh
shellspec tests/lib/core_spec.sh
```

**CI** (`.github/workflows/main.yml`) runs two verify jobs ahead of `publish`: `verify` (`ubuntu-22.04`, the full `mise run verify` pipeline including coverage) and `verify-zsh` (`macos-latest`, `mise run test-zsh` only — zsh needs no install there since it's macOS's default shell). `verify-zsh` is optional: set the repo variable `RUN_ZSH_VERIFY` to `false` to skip it without editing the workflow. A skip doesn't block `publish`; an actual zsh test failure does.

## Architecture

### Module dependency order

Modules must be sourced in this order (also the order in `scripts/build.sh`):

```
console.sh → log.sh → core.sh → validate.sh → proc.sh → script.sh → print.sh → git.sh
```

Each module is guarded by a `_RNF_<MODULE>_LOADED` variable so sourcing multiple times is safe.

### Build pipeline

`scripts/build.sh` concatenates all modules (in dependency order), strips shdoc comment blocks (`# @tag` lines), and emits a `#!/bin/sh` bundle plus a `.map` line-range file for tracing bundle lines back to source. It stages the full dist tree at `dist/shkit/` (`shkit.sh`, `shkit.sh.map`, `rnfshk.sh`, `install.sh`, `commands/`, `VERSION`), tars it to `dist/shkit.tar.gz`, writes `dist/shkit.tar.gz.sha256`, and copies loose release assets (`shkit.sh`, `.map`, `source.sh`, `install.sh`) into `dist/`.

### Docs

`docs/` is generated from `# @file`, `# @description`, `# @arg`, `# @example`, `# @stdout`, `# @exitcode` annotations by the `scripts/shdoc` gawk script. Never edit `docs/` manually.

### Install layout

`src/install.sh` is self-detecting dual-mode: run next to an unpacked dist tree (sibling `shkit.sh` + `VERSION` present — inside `dist/shkit/`, an unpacked release tarball, or an installed `shkit/<version>/`), it installs that tree directly. Run standalone (curled fresh, no sibling files), it downloads the release tarball first (honoring `RNF_VERSION`/`RNF_UPDATE_URL`) and re-runs the extracted copy. Either way it installs versioned into `${RNF_HOME:-$HOME/.rn-forge}`:

```
~/.rn-forge/
  bin/rnfshk -> ../shkit/current/rnfshk.sh
  shkit/
    current -> v<X.Y.Z>          # ln -sfn symlink
    v<X.Y.Z>/{shkit.sh, shkit.sh.map, rnfshk.sh, install.sh, commands/, VERSION}
```

`rnfshk` resolves itself through those symlinks (`readlink -f`) and dispatches sub-commands to sibling `commands/<cmd>.sh`. `commands/update.sh` is a thin delegator — it just `exec`s the sibling `install.sh` (one directory up), inheriting `RNF_VERSION`/`RNF_UPDATE_URL` from the environment; there is no `commands/install.sh` and no `rnfshk install` sub-command. `src/source.sh` (shipped as the `source.sh` release asset) sources the installed bundle, downloading `install.sh` and running it first when missing.

## Key constraints

**Bash + zsh only.** The library targets macOS zsh (dev) and Linux bash (scripts on VMs/CI). No POSIX sh / dash support. Shebangs and `# shellcheck shell=` directives are `bash`; `.shellspec` defaults to `--shell bash`.

**Zsh `readonly` scoping.** Under zsh, `readonly`/`typeset` in a file sourced *inside a function* creates function-local variables — the bundle's `RNF_LOG_LEVEL_*` constants would vanish when the function returns (bash scopes them globally). Never source the bundle from inside a function; `src/source.sh` computes the bundle path in a helper and sources at file top level for this reason.

**Zsh reserved variables.** Avoid `local status`, `local path`, `local options`, `local argv` — these are read-only special variables in zsh that silently break functions. Use `local rc`, `local dir`, etc. instead.

**Zsh `read` from stdin.** Use `read -r -u0` (not bare `read -k 1`) to read stdin under zsh; `read -k 1` reads from the terminal, not stdin, and breaks under piped/non-TTY contexts like shellspec.

**Mixing bash/zsh syntax in one file.** shfmt parses the whole file as the dialect declared by the shebang. Zsh-only constructs like `${(P)name}` are a hard parse error even inside `if [ -n "$ZSH_VERSION" ]` branches. The established pattern: wrap zsh-only syntax in `eval '...'` with single quotes so shfmt/shellcheck see an opaque string. See `var_get` in `core.sh` and the `RNF_OUTPUT_FILE` block in `script.sh`.

**TTY detection in tests.** shellspec runs without a TTY (all FDs are pipes), so `_rnf_color_enabled` is always false in tests. Specs must assert plain uncolored output. Never check exit codes at the end of a pipeline (`fn | head; echo $?` reports `head`'s status — capture exit code directly).

**Glob safety in zsh.** Unmatched globs are hard errors in zsh. Use `find` in tests rather than shell globs when listing files.

**shellcheck directives.** `.shellcheckrc` disables SC1090, SC1091 (unresolvable dynamic sources) and SC3043 globally. Don't add per-file directives for these.
