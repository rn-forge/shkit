# console.sh

Terminal detection, ANSI color configuration, and text utilities.

## Overview

Single source of truth for all color configuration. Provides:
- RNF_COLOR_* variables covering log levels and print UI elements,
defaulted to standard ANSI codes and overridable before sourcing.
- _rnf_color_enabled FD — test whether color output is appropriate
for a given file descriptor.
- strip_ansi — pipe filter to strip ANSI escape sequences.

RNF_NO_COLOR=1 suppresses ANSI output globally across all modules.

No dependencies on other rn-forge-shkit modules.
Safe to source multiple times (guarded by _RNF_CONSOLE_LOADED).

## Index

* [_rnf_color_enabled](#_rnf_color_enabled)
* [strip_ansi](#strip_ansi)

### _rnf_color_enabled

Return 0 if color output is appropriate for file descriptor FD.
Checks RNF_NO_COLOR=1 first, then whether FD is connected to a terminal.
Call with FD=1 for stdout (print_*) or FD=2 for stderr (log_*).

#### Arguments

* **$1** (integer): File descriptor to test. Default: 1.

### strip_ansi

Strip ANSI color (SGR) sequences from stdin. Use as a pipe filter.

#### Exit codes

* **0**: Always.

#### Input on stdin

* Text that may contain ANSI color codes.

#### Output on stdout

* The same text with ANSI color (SGR) sequences removed.

