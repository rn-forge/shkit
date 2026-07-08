#!/bin/bash
# @file script.sh
# @brief Script context, diagnostics, and interactive input utilities.
# @description
#   Sets SCRIPT_NAME and SCRIPT_DIR from the calling script's path, and provides
#   helpers for help text, variable inspection, environment dumps, and user input.
#
#   Interactive input suite:
#     pause   — wait for any keypress
#     confirm — yes/no prompt with automation bypass (RNF_SKIP_CONFIRMATIONS)
#     prompt  — read a line of input into a named variable
#
#   Config vars:
#     RNF_OUTPUT_FILE  Path to capture all stdout+stderr output, ANSI stripped.
#                      Set before sourcing this file to activate. Unset = disabled.
#
#   Dependencies: log.sh, core.sh, console.sh
#   Safe to source multiple times (guarded by _RNF_SCRIPT_LOADED).

# shellcheck shell=bash

[ "${_RNF_SCRIPT_LOADED:-}" = "1" ] && return 0
_RNF_SCRIPT_LOADED=1

# If RNF_OUTPUT_FILE is set, tee all stdout+stderr to it with ANSI stripped in-flight.
# Must be set before sourcing this file to take effect.
# Process substitution is bash/zsh-only; the eval hides its syntax from POSIX
# parsers, and single quotes defer variable expansion until execution.
if [ -n "${RNF_OUTPUT_FILE:-}" ]; then
  if [ -n "${BASH_VERSION:-}" ] || [ -n "${ZSH_VERSION:-}" ]; then
    eval 'exec > >(tee >(strip_ansi >>"$RNF_OUTPUT_FILE")) 2>&1'
  else
    log_warning "RNF_OUTPUT_FILE requires bash or zsh — output capture disabled"
  fi
fi

# SCRIPT_NAME and SCRIPT_DIR reflect the calling script's identity, not this file.
# In bash, $0 is always the main invoking script.
# In zsh, $0 is the sourced file (FUNCTION_ARGZERO is on by default), so we use
# $ZSH_ARGZERO, which zsh sets once at startup and does not change on source.
if [ -n "${ZSH_VERSION:-}" ]; then
  SCRIPT_NAME="$(basename -- "$ZSH_ARGZERO" .sh)"
  SCRIPT_DIR="$(cd "$(dirname -- "$ZSH_ARGZERO")" && pwd)"
else
  SCRIPT_NAME="$(basename -- "$0" .sh)"
  SCRIPT_DIR="$(cd "$(dirname -- "$0")" && pwd)"
fi
export SCRIPT_NAME SCRIPT_DIR

# ---------------------------------------------------------------------------
# Internal helpers
# ---------------------------------------------------------------------------

# Read a single character without requiring Enter.
# Sets _RNF_CHAR to the character read.
# Falls back to a full-line read if neither bash nor zsh is detected.
# shellcheck disable=SC3045,SC2162  # -k/-n are intentionally shell-specific; branches are runtime-guarded
_read_char() {
  _RNF_CHAR=""
  if [ -n "${ZSH_VERSION:-}" ]; then
    if [ -t 0 ]; then
      read -rk 1 _RNF_CHAR # interactive TTY: raw-mode single keypress
    else
      read -rk 1 -u0 _RNF_CHAR # piped stdin (e.g. shellspec): -u0 reads stdin, not the terminal
    fi
  elif [ -n "${BASH_VERSION:-}" ]; then
    read -r -n 1 _RNF_CHAR # bash
  else
    read -r _RNF_CHAR # POSIX fallback
  fi
}

# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------

# @description Print a formatted usage/help message to stdout.
#   Reads RNF_SCRIPT_* globals — all are optional; unset vars are silently omitted.
#
# @noargs
#
# @set RNF_SCRIPT_ARGS        Positional args shown after [OPTIONS] in the usage line.
# @set RNF_SCRIPT_DESCRIPTION One-line description printed below the usage line.
# @set RNF_SCRIPT_OPTIONS     Options block printed under an "OPTIONS: [* Required]" header.
#
# @example
#   RNF_SCRIPT_DESCRIPTION="Deploy the application."
#   RNF_SCRIPT_ARGS="FILE"
#   RNF_SCRIPT_OPTIONS="
#     -e ENV   Target environment (required)
#     -n       Dry run
#     -h       Show this help"
#   show_help
#   # Usage: deploy.sh [OPTIONS] FILE
#   # Deploy the application.
#   #
#   # OPTIONS: [* Required]
#   #   -e ENV   Target environment (required)
#   #   -n       Dry run
#   #   -h       Show this help
#
# @stdout Formatted usage block.
# @exitcode 0 Always.
show_help() {
  local h="" r=""
  if _rnf_color_enabled 1; then
    h="${RNF_COLOR_HEADER}" r="\033[0m"
  fi
  local args=""
  [ -n "${RNF_SCRIPT_ARGS:-}" ] && args=" ${RNF_SCRIPT_ARGS}"
  printf "%sUsage: %s [OPTIONS]%s%s\n" "$h" "$SCRIPT_NAME" "$args" "$r"
  [ -n "${RNF_SCRIPT_DESCRIPTION:-}" ] && printf "%s\n" "$RNF_SCRIPT_DESCRIPTION"
  if [ -n "${RNF_SCRIPT_OPTIONS:-}" ]; then
    printf "\n%sOPTIONS:%s [* Required]\n%s\n" "$h" "$r" "$RNF_SCRIPT_OPTIONS"
  fi
}

# @description Log an error for an invalid argument, print usage help, then exit.
#   Combines log_error + show_help + exit. show_help reads RNF_SCRIPT_* globals —
#   set them before calling this if you want usage printed.
#
# @arg $1 integer Exit code.
# @arg $2 string  Error message describing what was invalid.
#
# @example
#   RNF_SCRIPT_OPTIONS="  -e ENV   Target environment (required)"
#   handle_invalid_args 1 "MODE must be i, u, or a"
#
# @exitcode $1 Always exits.
handle_invalid_args() {
  local exit_code="$1" message="$2"
  log_error "$message"
  show_help
  exit "$exit_code"
}

# @description Log the current values of named variables.
#   First argument may be a log function name (e.g. log_warn); defaults to log_info.
#
# @arg $1 string Optional log function to use (must start with 'log_'). Default: log_info.
# @arg $@ string Variable names whose values should be printed.
#
# @example
#   TARGET="prod"
#   DRY_RUN="1"
#   print_vars TARGET DRY_RUN
#   print_vars log_warn TARGET DRY_RUN
#
# @exitcode 0 Always.
print_vars() {
  local log_fn="log_info"
  case "${1:-}" in log_*)
    log_fn="$1"
    shift
    ;;
  esac
  local var
  for var in "$@"; do
    "$log_fn" "${var}=$(var_get "$var")"
  done
}

# @description Log all environment variables via log_debug.
#   Output is only visible when RNF_LOG_LEVEL is set to DEBUG or lower.
#
# @noargs
#
# @example
#   RNF_LOG_LEVEL=$RNF_LOG_LEVEL_DEBUG
#   debug_environment
#
# @exitcode 0 Always.
debug_environment() {
  log_debug "--- environment ---"
  env | while IFS= read -r line; do
    log_debug "  $line"
  done
  log_debug "---"
}

# @description Wait for the user to press any key before continuing.
#
# @arg $1 string Optional message to display before the prompt. Default: empty.
#
# @example
#   pause
#   pause "Review the output above"
#
# @exitcode 0 Always.
pause() {
  [ -n "${1:-}" ] && printf "%s\n" "$1"
  printf "Press any key to continue..."
  _read_char
  printf "\n"
}

# @description Prompt the user for a yes/no confirmation.
#   Exits the script with code 1 if the user answers 'n' or presses any key
#   other than 'y'/'Y'. Auto-proceeds without prompting when RNF_SKIP_CONFIRMATIONS=1,
#   unless --force is passed.
#
# @arg $1 string  Confirmation message (the question to display).
# @arg $2 string  Optional '--force' flag to always prompt, even if RNF_SKIP_CONFIRMATIONS=1.
#
# @set RNF_SKIP_CONFIRMATIONS When set to '1', confirm auto-proceeds without prompting.
#
# @example
#   confirm "Delete all build artefacts"
#   confirm "Wipe the database — are you sure" --force
#
# @exitcode 0 User confirmed (or auto-confirmed via RNF_SKIP_CONFIRMATIONS).
# @exitcode 1 User declined. Script is exited.
confirm() {
  local msg="$1" force=0
  [ "${2:-}" = "--force" ] && force=1

  if [ "${RNF_SKIP_CONFIRMATIONS:-0}" = "1" ] && [ "$force" -eq 0 ]; then
    log_info "auto-confirmed: ${msg}"
    return 0
  fi

  printf "%s (y/n): " "$msg"
  _read_char
  printf "\n"

  # Also match "yes": the POSIX fallback in _read_char reads a whole line.
  case "${_RNF_CHAR:-}" in
  [Yy] | [Yy][Ee][Ss]) return 0 ;;
  *)
    log_error "Cancelled."
    exit 1
    ;;
  esac
}

# @description Read a line of user input into a named variable.
#
# @arg $1 string Name of the variable to populate.
# @arg $2 string Prompt message displayed before the input cursor.
#
# @example
#   prompt target_env "Target environment (prod/staging)"
#   echo "Deploying to: $target_env"
#
# @exitcode 0 Always.
prompt() {
  local var_name="$1" msg="$2"
  printf "%s: " "$msg"
  # shellcheck disable=SC2229
  read -r "${var_name}"
}
