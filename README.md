# shkit

A bash/zsh library of reusable shell utilities. Source individual modules or the single-file bundle, and manage the installation with the `rnfshk` command.

## Modules

| Module | Dependencies | Description |
|---|---|---|
| `console.sh` | — | Terminal detection, ANSI color configuration, and text utilities |
| `log.sh` | `console.sh` | Leveled logging (DEBUG–CRITICAL) with pretty stderr and logfmt file output |
| `core.sh` | — | Core utility functions — indirect variable lookup, dividers, timestamps |
| `validate.sh` | `log.sh`, `core.sh` | Input validation helpers — value lists, patterns, required vars |
| `proc.sh` | `log.sh` | Process and command utilities |
| `script.sh` | `log.sh`, `core.sh`, `console.sh` | Script lifecycle helpers — argument parsing, help display, exit traps |
| `print.sh` | `console.sh` | Styled stdout output for human-facing script UI |
| `git.sh` | `log.sh` | Git workflow helpers — branch management, commit, merge, squash, prune |

## Installation

**From a clone** (developing, or testing the current working tree) — requires [mise](https://mise.jdx.dev/):

```sh
mise run install
```

Builds the distribution from source and installs it versioned under `~/.rn-forge/`:

```
~/.rn-forge/
  bin/rnfshk -> ../shkit/current/rnfshk.sh
  shkit/
    current -> v<X.Y.Z>
    v<X.Y.Z>/{shkit.sh, shkit.sh.map, rnfshk.sh, install.sh, commands/, VERSION}
```

**Without cloning** — install the latest release directly:

```sh
curl -fsSL https://github.com/rn-forge/shkit/releases/latest/download/install.sh | bash
```

Downloads the release tarball and installs it into the same versioned layout as `mise run install`. From then on, use `rnfshk update` to move to a newer release — there's no separate `rnfshk install`; `install.sh` is only for the first install on a machine (or vendored/curled by `source.sh` and `update` under the hood).

Either way, add to your shell RC to activate:

```sh
export PATH="$HOME/.rn-forge/bin:$PATH"
source "$HOME/.rn-forge/shkit/current/shkit.sh"
```

## Usage

There are two ways to source the library: from a local installation, or straight from a remote distribution without one.

### Source from a local installation

**The installed bundle** — the common case, after either [install path](#installation) above:

```sh
# Use in your shell RC, or in scripts on any machine where the library is
# already installed (dev laptop, provisioned server).
. ~/.rn-forge/shkit/current/shkit.sh
log_info "deploying..."
log_success "done"
```

**From the repo:**

> Run `mise run build` first to generate the bundle.

```sh
# Use while developing shkit itself, to exercise the built bundle
# without installing it.
. /path/to/shkit/dist/shkit/shkit.sh
```

**Individual modules:**

> Modules have dependencies — source them in order. `log.sh` requires `console.sh`.

```sh
# Use when you only need a subset of the library and want to avoid pulling
# in the full bundle.
. /path/to/shkit/src/lib/console.sh
. /path/to/shkit/src/lib/log.sh
. /path/to/shkit/src/lib/print.sh
```

### Source from a remote distribution

No local install required — both options fetch from GitHub releases at source time. `source.sh` installs on first use so repeat runs are fast and offline; the raw bundle never installs and always re-downloads. See the comments in each block below for which fits your scenario.

**`source.sh`:**

```sh
# Use for scripts that run repeatedly on the same machine and may or may not
# already have the library installed (CI runners with persistent/cached
# workspaces, cron jobs, provisioning scripts run more than once). Installs
# on first run (needs network), sources the installed bundle on every run
# after (no network), and leaves rnfshk/RNF_VERSION management in place.
. <(curl -fsSL https://github.com/rn-forge/shkit/releases/latest/download/source.sh)
log_info "works locally and on a fresh VM"
```

Or vendor `dist/source.sh` next to your script and source it directly — no network needed once installed:

```sh
. "$(dirname "$0")/source.sh"
```

**Raw bundle, no install:**

```sh
# Use for one-shot, ephemeral environments (a container/pod that runs once
# and is destroyed) where installing would just write files nobody reuses.
# Always downloads; leaves nothing behind after the temp file is removed.
#
# Download to a file first rather than `. <(curl ...)` directly — process
# substitution swallows curl's exit code, so a failed download (network
# down, 404) would source an empty stream and silently continue with none
# of the library loaded instead of failing.
_rnf_tmp="$(mktemp)" &&
  curl -fsSL https://github.com/rn-forge/shkit/releases/latest/download/shkit.sh -o "$_rnf_tmp" &&
  . "$_rnf_tmp" && rm -f "$_rnf_tmp"
```

Pin a version by replacing `latest/download` with `download/v<X.Y.Z>`. Source it at the top level of your script, never inside a function (zsh scopes the bundle's `readonly` constants to the function otherwise).

Config vars (also honored by `rnfshk update`):

| Variable | Effect |
|---|---|
| `RNF_HOME` | Install root. Default: `~/.rn-forge` |
| `RNF_VERSION` | Pin a release (e.g. `0.2.0`) for reproducible runs — sources `shkit/v<version>/` |
| `RNF_UPDATE_URL` | Override the tarball download URL entirely |
| `RNF_INSTALL_URL` | `source.sh` only — override the `install.sh` download URL itself |
| `RNF_GITHUB_ORG` | GitHub org/user for release downloads. Default: `rn-forge` |

## Logging

```sh
RNF_LOG_LEVEL=$RNF_LOG_LEVEL_DEBUG   # default: INFO (20)
RNF_LOG_FILE=/var/log/app.log        # logfmt output; unset = disabled
RNF_LOG_CONTEXT="svc=deploy env=prod" # injected into every logfmt line

log_debug   "fine-grained detail"
log_verbose "more than info, less than debug"
log_info    "routine message"
log_notice  "noteworthy event"
log_warning "unexpected but recoverable"
log_success "operation completed"
log_error   "recoverable failure"
log_critical "unrecoverable — script should abort"
```

## Management commands

`rnfshk` (installed at `~/.rn-forge/bin/rnfshk`) is a standalone dispatcher that manages the library itself — each sub-command runs the matching `commands/<cmd>.sh` from the installed dist:

```sh
rnfshk version   # print the installed library version
rnfshk env       # print current RNF_* configuration
rnfshk update    # update to the latest release (or RNF_VERSION pin)
rnfshk cleanup   # remove old installed versions, keeping current
rnfshk help      # list sub-commands
```

`rnfshk update` delegates to the installed `install.sh` (override its tarball URL with `RNF_UPDATE_URL`, pin with `RNF_VERSION`). Versions install side by side under `~/.rn-forge/shkit/`; the `current` symlink flips to the new one. There's no `rnfshk install` — `install.sh` handles first-time setup (see [Installation](#installation) above), and every subsequent install goes through `update`.

`rnfshk cleanup` deletes every version directory under `~/.rn-forge/shkit/` except the one `current` points to, prompting for confirmation first (bypass with `RNF_SKIP_CONFIRMATIONS=1`).

## Development

Additional prerequisites (not managed by mise):

- [shellspec](https://shellspec.info/) — required for `mise run test`
- [gawk](https://www.gnu.org/software/gawk/) — required for `mise run docs`
- [kcov](https://simonkagstrom.github.io/kcov/) — required for `mise run coverage` / `mise run verify`

```sh
mise run format        # shfmt -w (in-place)
mise run format-check  # shfmt -d (diff only, exits non-zero if dirty)
mise run lint          # shellcheck src/ scripts/ examples/
mise run test          # shellspec under the default shell (bash)
mise run test-bash     # shellspec under bash
mise run test-zsh      # shellspec under zsh
mise run test-all      # shellspec under bash and zsh
mise run coverage      # shellspec --shell bash --kcov; HTML+lcov report in coverage/
mise run install       # build + install to ~/.rn-forge
mise run build         # generate dist/shkit/ tree, tarball, loose assets
mise run docs          # generate docs/ from shdoc annotations
mise run clean         # remove generated dist/ artifacts
mise run verify        # format-check + lint + coverage + build + docs (CI; needs kcov)
mise run verify-local  # format-check + lint + test-all + build + docs (local dev; no kcov needed)
```

See [examples/demo.sh](examples/demo.sh) for a runnable walkthrough.

## API reference

Per-module docs are generated into [`docs/`](docs/) by `mise run docs` and published at **[rn-forge.github.io/shkit](https://rn-forge.github.io/shkit/)**.
