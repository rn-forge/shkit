#!/bin/bash
# @file core.sh
# @brief Core utility functions with no external dependencies.
# @description
#   Foundational helpers used by all other rn-forge-shkit modules:
#   indirect variable lookup, divider lines, timestamps, and config parsing.
#
#   No dependencies on other rn-forge-shkit modules.
#   Safe to source multiple times (guarded by _RNF_CORE_LOADED).

# shellcheck shell=bash

[ "${_RNF_CORE_LOADED:-}" = "1" ] && return 0
_RNF_CORE_LOADED=1

# @description Indirect variable lookup by name.
#   Uses native indirect expansion — bash's ${!name} or zsh's ${(P)name} —
#   so, unlike eval on a caller-supplied string, an unusual variable name can
#   only fail to expand, never execute as code. The zsh branch is wrapped in
#   eval on a static (single-quoted) string purely so shfmt/shellcheck, which
#   parse the file as bash, don't choke on zsh-only expansion syntax — same
#   trick used for the process substitution in script.sh.
#
# @arg $1 string Name of the variable to read.
#
# @example
#   greeting="hello world"
#   var_get greeting    # → hello world
#   var_get unset_var   # → (empty string)
#
# @stdout The variable's current value, or empty string if unset.
# @exitcode 0 Always.
var_get() {
  if [ -n "${ZSH_VERSION:-}" ]; then
    eval 'printf "%s" "${(P)1:-}"'
  else
    printf '%s' "${!1:-}"
  fi
}

# @description Print a horizontal divider line to stdout.
#
# @arg $1 string Character to repeat. Default: '-'.
# @arg $2 integer Width in characters. Default: 80.
#
# @example
#   divider           # 80 dashes
#   divider '=' 40    # 40 equal signs
#   divider '*' 10    # **********
#
# @stdout The divider line followed by a newline.
# @exitcode 0 Always.
divider() {
  local char="${1:--}" width="${2:-80}"
  printf "%*s\n" "$width" "" | tr ' ' "$char"
}

# @description Return the current date and time as a formatted string.
#
# @noargs
#
# @example
#   ts=$(timestamp)
#   echo "Started at: $ts"
#
# @stdout Timestamp in 'YYYY-MM-DD HH:MM:SS' format.
# @exitcode 0 Always.
timestamp() {
  date '+%Y-%m-%d %H:%M:%S'
}

# @description Print the rn-forge-shkit build version.
#   In the bundled dist/rn-forge.sh, this reflects the VERSION and commit
#   baked in at build time (see scripts/build.sh). When sourcing modules
#   directly from src/lib (no build step), reports "dev".
#
# @noargs
#
# @example
#   rnf_version    # → 0.1.0 (e3db8e0)
#
# @stdout Version string.
# @exitcode 0 Always.
rnf_version() {
  printf '%s\n' "${_RNF_VERSION:-dev}"
}
