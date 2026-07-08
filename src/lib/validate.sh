#!/bin/bash
# @file validate.sh
# @brief Input validation and guard functions.
# @description
#   Validation utilities for checking required variables, allowed values,
#   and value patterns. All functions log via log.sh on failure.
#   Does not exit on its own except where documented — callers control flow.
#
#   Dependencies: log.sh, core.sh
#   Safe to source multiple times (guarded by _RNF_VALIDATE_LOADED).

# shellcheck shell=bash

[ "${_RNF_VALIDATE_LOADED:-}" = "1" ] && return 0
_RNF_VALIDATE_LOADED=1

# @description Exit with an error if any of the named variables are unset or empty.
#
# @arg $1 integer Exit code to use on failure.
# @arg $@ string  One or more variable names to check (not values — names).
#
# @example
#   NAME="alice"
#   check_required 1 NAME           # passes silently
#   check_required 1 NAME MISSING   # logs error and exits 1
#
# @exitcode 0  All named variables are set and non-empty.
# @exitcode $1 First variable found to be unset or empty.
check_required() {
  local exit_code="$1"
  shift
  local var
  for var in "$@"; do
    if [ -z "$(var_get "$var")" ]; then
      log_error "${var} is required but is not set"
      exit "$exit_code"
    fi
  done
}

# @description Exit with an error if a named variable's value is not in the allowed set.
#
# @arg $1 integer Exit code to use on failure.
# @arg $2 string  Name of the variable to check (not its value — the name).
# @arg $@ string  Two or more allowed values.
#
# @example
#   MODE="i"
#   check_value_in_list 1 MODE i I u U   # passes
#
#   MODE="x"
#   check_value_in_list 1 MODE i I u U   # logs error and exits 1
#
# @exitcode 0  Variable value is in the allowed set.
# @exitcode $1 Variable value is not in the allowed set.
check_value_in_list() {
  local exit_code="$1" var_name="$2"
  shift 2
  local value allowed
  value="$(var_get "$var_name")"
  for allowed in "$@"; do
    [ "$value" = "$allowed" ] && return 0
  done
  log_error "${var_name}='${value}' must be one of: $*"
  exit "$exit_code"
}

# @description Verify a value matches a POSIX basic regular expression (BRE).
#   Uses grep -qx for whole-value matching. Returns 1 on mismatch — does not exit,
#   so the caller decides how to handle failure.
#
# @arg $1 string Label describing what is being validated (used in log messages).
# @arg $2 string Value to test.
# @arg $3 string POSIX BRE pattern the entire value must satisfy.
#
# @example
#   check_pattern "version" "1.2.3" "^[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*$" || exit 1
#
# @exitcode 0 Value matches the pattern.
# @exitcode 1 Value does not match the pattern.
check_pattern() {
  local label="$1" value="$2" pattern="$3"
  case "$value" in
  *'
'*)
    log_error "${label}: value must not contain newlines"
    return 1
    ;;
  esac
  if printf '%s\n' "$value" | grep -qx -e "$pattern" 2>/dev/null; then
    log_debug "${label}: '${value}' matches '${pattern}'"
    return 0
  fi
  log_error "${label}: '${value}' does not match required pattern '${pattern}'"
  return 1
}
