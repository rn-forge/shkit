#!/bin/bash
# @file console.sh
# @brief Terminal detection, ANSI color configuration, and text utilities.
# @description
#   Single source of truth for all color configuration. Provides:
#   - RNF_COLOR_* variables covering log levels and print UI elements,
#     defaulted to standard ANSI codes and overridable before sourcing.
#   - _rnf_color_enabled FD — test whether color output is appropriate
#     for a given file descriptor.
#   - strip_ansi — pipe filter to strip ANSI escape sequences.
#
#   RNF_NO_COLOR=1 suppresses ANSI output globally across all modules.
#
#   No dependencies on other shkit modules.
#   Safe to source multiple times (guarded by _RNF_CONSOLE_LOADED).

# shellcheck shell=bash

[ "${_RNF_CONSOLE_LOADED:-}" = "1" ] && return 0
_RNF_CONSOLE_LOADED=1

# ---------------------------------------------------------------------------
# Log-level color defaults (consumed by log.sh)
# Override any of these before sourcing to change a level's color.
# ---------------------------------------------------------------------------

: "${RNF_COLOR_DEBUG:=\033[36;2m}"    # cyan dim
: "${RNF_COLOR_VERBOSE:=\033[34m}"    # blue
: "${RNF_COLOR_INFO:=\033[0m}"        # default terminal color
: "${RNF_COLOR_NOTICE:=\033[35;1m}"   # magenta bold
: "${RNF_COLOR_WARNING:=\033[33m}"    # yellow
: "${RNF_COLOR_SUCCESS:=\033[32m}"    # green
: "${RNF_COLOR_ERROR:=\033[31m}"      # red
: "${RNF_COLOR_CRITICAL:=\033[1;31m}" # bold red

# ---------------------------------------------------------------------------
# Print UI color defaults (consumed by print.sh and script.sh)
# ---------------------------------------------------------------------------

: "${RNF_COLOR_HEADER:=\033[1;33m}" # bold yellow
: "${RNF_COLOR_STEP:=\033[1m}"      # bold
: "${RNF_COLOR_BANNER:=\033[1m}"    # bold
: "${RNF_COLOR_DIVIDER:=\033[2m}"   # dim

# ---------------------------------------------------------------------------
# Internal helper
# ---------------------------------------------------------------------------

# @description Return 0 if color output is appropriate for file descriptor FD.
#   Checks RNF_NO_COLOR=1 first, then whether FD is connected to a terminal.
#   Call with FD=1 for stdout (print_*) or FD=2 for stderr (log_*).
#
# @arg $1 integer File descriptor to test. Default: 1.
_rnf_color_enabled() {
  [ "${RNF_NO_COLOR:-0}" != "1" ] && [ -t "${1:-1}" ]
}

# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------

# @description Strip ANSI color (SGR) sequences from stdin. Use as a pipe filter.
#
# @stdin  Text that may contain ANSI color codes.
# @stdout The same text with ANSI color (SGR) sequences removed.
# @exitcode 0 Always.
strip_ansi() {
  # BSD sed (macOS) does not interpret \033 as ESC in patterns; embed the
  # literal ESC character via printf so the regex works on all POSIX sed.
  sed "s/$(printf '\033')\[[0-9;]*m//g"
}
