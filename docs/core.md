# core.sh

Core utility functions with no external dependencies.

## Overview

Foundational helpers used by all other shkit modules:
indirect variable lookup, divider lines, timestamps, and config parsing.

No dependencies on other shkit modules.
Safe to source multiple times (guarded by _RNF_CORE_LOADED).

## Index

* [var_get](#var_get)
* [divider](#divider)
* [timestamp](#timestamp)
* [rnf_version](#rnf_version)

### var_get

Indirect variable lookup by name.
Uses native indirect expansion — bash's ${!name} or zsh's ${(P)name} —
so, unlike eval on a caller-supplied string, an unusual variable name can
only fail to expand, never execute as code. The zsh branch is wrapped in
eval on a static (single-quoted) string purely so shfmt/shellcheck, which
parse the file as bash, don't choke on zsh-only expansion syntax — same
trick used for the process substitution in script.sh.

#### Example

```bash
greeting="hello world"
var_get greeting    # → hello world
var_get unset_var   # → (empty string)
```

#### Arguments

* **$1** (string): Name of the variable to read.

#### Exit codes

* **0**: Always.

#### Output on stdout

* The variable's current value, or empty string if unset.

### divider

Print a horizontal divider line to stdout.

#### Example

```bash
divider           # 80 dashes
divider '=' 40    # 40 equal signs
divider '*' 10    # **********
```

#### Arguments

* **$1** (string): Character to repeat. Default: '-'.
* **$2** (integer): Width in characters. Default: 80.

#### Exit codes

* **0**: Always.

#### Output on stdout

* The divider line followed by a newline.

### timestamp

Return the current date and time as a formatted string.

#### Example

```bash
ts=$(timestamp)
echo "Started at: $ts"
```

_Function has no arguments._

#### Exit codes

* **0**: Always.

#### Output on stdout

* Timestamp in 'YYYY-MM-DD HH:MM:SS' format.

### rnf_version

Print the shkit build version.
In the bundled dist/rn-forge.sh, this reflects the VERSION and commit
baked in at build time (see scripts/build.sh). When sourcing modules
directly from src/lib (no build step), reports "dev".

#### Example

```bash
rnf_version    # → 0.1.0 (e3db8e0)
```

_Function has no arguments._

#### Exit codes

* **0**: Always.

#### Output on stdout

* Version string.

