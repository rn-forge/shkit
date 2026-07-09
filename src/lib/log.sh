#!/bin/bash
# @file log.sh
# @brief Leveled logging with pretty stderr output and logfmt file output.
# @description
#   Provides a 9-level logging API (DEBUG through CRITICAL) with numeric
#   spacing borrowed from verboselogs. Output is written to two streams:
#   - stderr: colored, human-readable, timestamped (pretty format)
#   - RNF_LOG_FILE: logfmt-formatted for machine parsing and log aggregators
#
#   Config vars:
#     RNF_LOG_LEVEL    Minimum level to emit. Default: RNF_LOG_LEVEL_INFO (20).
#     RNF_LOG_FILE     Path to logfmt output file. Unset = file output disabled.
#     RNF_LOG_CONTEXT  Free-form key=value pairs injected into logfmt lines.
#                      Example: RNF_LOG_CONTEXT="svc=deploy env=prod"
#     RNF_COLOR_*      Per-level color overrides — set in or before console.sh.
#     RNF_NO_COLOR     Set to 1 to suppress ANSI codes even on a TTY.
#
#   Dependencies: console.sh
#   Safe to source multiple times (guarded by _RNF_LOG_LOADED).

# shellcheck shell=bash

[ "${_RNF_LOG_LOADED:-}" = "1" ] && return 0
_RNF_LOG_LOADED=1

# ---------------------------------------------------------------------------
# Level constants — verboselogs-derived, 10-point spacing
# ---------------------------------------------------------------------------

readonly RNF_LOG_LEVEL_NONE=0
readonly RNF_LOG_LEVEL_DEBUG=10
readonly RNF_LOG_LEVEL_VERBOSE=15
readonly RNF_LOG_LEVEL_INFO=20
readonly RNF_LOG_LEVEL_NOTICE=25
readonly RNF_LOG_LEVEL_WARNING=30
readonly RNF_LOG_LEVEL_SUCCESS=35
readonly RNF_LOG_LEVEL_ERROR=40
readonly RNF_LOG_LEVEL_CRITICAL=50

# Set default minimum level if caller has not already set it.
: "${RNF_LOG_LEVEL:=$RNF_LOG_LEVEL_INFO}"

# ---------------------------------------------------------------------------
# Internal helpers
# ---------------------------------------------------------------------------

# Map a level name to its numeric value; prints to stdout.
# Unknown names fall back to INFO (20).
_log_level_num() {
  case "$1" in
  NONE) printf '%d' "$RNF_LOG_LEVEL_NONE" ;;
  DEBUG) printf '%d' "$RNF_LOG_LEVEL_DEBUG" ;;
  VERBOSE) printf '%d' "$RNF_LOG_LEVEL_VERBOSE" ;;
  INFO) printf '%d' "$RNF_LOG_LEVEL_INFO" ;;
  NOTICE) printf '%d' "$RNF_LOG_LEVEL_NOTICE" ;;
  WARNING) printf '%d' "$RNF_LOG_LEVEL_WARNING" ;;
  SUCCESS) printf '%d' "$RNF_LOG_LEVEL_SUCCESS" ;;
  ERROR) printf '%d' "$RNF_LOG_LEVEL_ERROR" ;;
  CRITICAL) printf '%d' "$RNF_LOG_LEVEL_CRITICAL" ;;
  *) printf '%d' "$RNF_LOG_LEVEL_INFO" ;;
  esac
}

# _log LEVEL_NUM LEVEL COLOR MSG...
# Central dispatch: filter by level, emit pretty to stderr, logfmt to file.
# Takes the numeric level directly — no subshell before the filter, so
# suppressed calls stay cheap.
_log() {
  local level_num="$1" level="$2" color="$3"
  shift 3
  local msg="$*"

  [ "$level_num" -lt "$RNF_LOG_LEVEL" ] && return 0

  local ts
  ts="$(date -u '+%Y-%m-%dT%H:%M:%SZ')"

  # Pretty to stderr — color only when stderr is an interactive TTY
  if _rnf_color_enabled 2; then
    printf "\033[0m%s ${color}[%-8s]\033[0m %s\n" "$ts" "$level" "$msg" >&2
  else
    printf "%s [%-8s] %s\n" "$ts" "$level" "$msg" >&2
  fi

  # logfmt to file — always plain text, always includes pid
  if [ -n "${RNF_LOG_FILE:-}" ]; then
    local escaped_msg ctx=""
    escaped_msg="$(printf '%s' "$msg" | awk '{gsub(/\\/, "\\\\"); gsub(/"/, "\\\""); gsub(/\r/, "\\r"); if (NR > 1) printf "\\n"; printf "%s", $0}')"
    [ -n "${RNF_LOG_CONTEXT:-}" ] && ctx=" ${RNF_LOG_CONTEXT}"
    if ! printf 'time=%s level=%s pid=%d%s msg="%s"\n' \
      "$ts" "$level" "$$" "$ctx" "$escaped_msg" >>"$RNF_LOG_FILE"; then
      printf '%s [WARNING ] disabling RNF_LOG_FILE after write failed: %s\n' "$ts" "$RNF_LOG_FILE" >&2
      RNF_LOG_FILE=""
    fi
  fi
}

# ---------------------------------------------------------------------------
# Public API — log levels
# ---------------------------------------------------------------------------

# @description Log at DEBUG level (10). Fine-grained diagnostic detail.
# @arg $@ string Message.
# @exitcode 0 Always.
log_debug() { _log "$RNF_LOG_LEVEL_DEBUG" DEBUG "$RNF_COLOR_DEBUG" "$@"; }

# @description Log at VERBOSE level (15). More detail than INFO, less noise than DEBUG.
# @arg $@ string Message.
# @exitcode 0 Always.
log_verbose() { _log "$RNF_LOG_LEVEL_VERBOSE" VERBOSE "$RNF_COLOR_VERBOSE" "$@"; }

# @description Log at INFO level (20). Routine operational messages.
# @arg $@ string Message.
# @exitcode 0 Always.
log_info() { _log "$RNF_LOG_LEVEL_INFO" INFO "$RNF_COLOR_INFO" "$@"; }

# @description Log at NOTICE level (25). Normal but noteworthy events.
# @arg $@ string Message.
# @exitcode 0 Always.
log_notice() { _log "$RNF_LOG_LEVEL_NOTICE" NOTICE "$RNF_COLOR_NOTICE" "$@"; }

# @description Log at WARNING level (30). Unexpected but recoverable; script continues.
# @arg $@ string Message.
# @exitcode 0 Always.
log_warning() { _log "$RNF_LOG_LEVEL_WARNING" WARNING "$RNF_COLOR_WARNING" "$@"; }

# @description Log at SUCCESS level (35). A significant operation completed successfully.
# @arg $@ string Message.
# @exitcode 0 Always.
log_success() { _log "$RNF_LOG_LEVEL_SUCCESS" SUCCESS "$RNF_COLOR_SUCCESS" "$@"; }

# @description Log at ERROR level (40). A recoverable or reported failure.
# @arg $@ string Message.
# @exitcode 0 Always.
log_error() { _log "$RNF_LOG_LEVEL_ERROR" ERROR "$RNF_COLOR_ERROR" "$@"; }

# @description Log at CRITICAL level (50). Unrecoverable failure — script should abort.
# @arg $@ string Message.
# @exitcode 0 Always.
log_critical() { _log "$RNF_LOG_LEVEL_CRITICAL" CRITICAL "$RNF_COLOR_CRITICAL" "$@"; }

# ---------------------------------------------------------------------------
# Public API — divider
# ---------------------------------------------------------------------------

# @description Write a horizontal divider line to stderr.
#
# @arg $1 string  Character to repeat. Default: '-'.
# @arg $2 integer Width in characters. Default: 80.
#
# @exitcode 0 Always.
log_divider() {
  local char="${1:--}" width="${2:-80}"
  printf "%*s\n" "$width" "" | tr ' ' "$char" >&2
}
