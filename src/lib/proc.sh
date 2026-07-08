#!/bin/bash
# @file proc.sh
# @brief Process execution and result-handling utilities.
# @description
#   Helpers for checking command exit codes and waiting on background processes.
#
#   Dependencies: log.sh
#   Safe to source multiple times (guarded by _RNF_PROC_LOADED).

# shellcheck shell=bash

[ "${_RNF_PROC_LOADED:-}" = "1" ] && return 0
_RNF_PROC_LOADED=1

# @description Check a command's return code, log the result, and optionally exit.
#   Pass EXIT_CODE=0 to log the failure without aborting.
#
# @arg $1 integer Return code of the command that was run (typically $?).
# @arg $2 integer Exit code to use if the command failed. 0 = log only, no exit.
# @arg $3 string  Label describing the operation (used in log messages).
#
# @example
#   brew install ripgrep
#   check_return_code $? 1 "brew install"
#
#   # Log failure but keep going:
#   optional_cmd
#   check_return_code $? 0 "optional step"
#
# @exitcode 0  RC was zero (command succeeded).
# @exitcode $2 RC was non-zero and EXIT_CODE > 0.
check_return_code() {
  local rc="$1" exit_code="$2" label="$3"
  if [ "$rc" -eq 0 ]; then
    log_success "${label}: ok"
    return 0
  fi
  log_error "${label}: failed (rc=${rc})"
  [ "$exit_code" -gt 0 ] && exit "$exit_code"
  return "$rc"
}

# @description Wait for a list of background processes and return the combined exit status.
#   Waits on each PID in order. Tracks the highest non-zero exit status seen
#   so a single failure does not prevent waiting on the remaining processes.
#
# @arg $@ integer One or more PIDs returned by backgrounded commands.
#
# @example
#   slow_cmd_a & pid_a=$!
#   slow_cmd_b & pid_b=$!
#   wait_for_children $pid_a $pid_b
#   check_return_code $? 1 "background tasks"
#
# @exitcode 0 All child processes exited successfully.
# @exitcode N Highest non-zero exit status returned by any child.
wait_for_children() {
  local final_status=0
  # Not named 'status': that is a read-only special variable in zsh.
  local pid child_status
  for pid in "$@"; do
    wait "$pid" && child_status=$? || child_status=$?
    log_debug "PID ${pid} exited with status ${child_status}"
    [ "$child_status" -gt "$final_status" ] && final_status="$child_status"
  done
  return "$final_status"
}
