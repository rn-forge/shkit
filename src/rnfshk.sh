#!/bin/bash
# shellcheck shell=bash
# shkit command dispatcher: `rnfshk <sub-command> [args ...]` runs
# commands/<sub_command>.sh from the installed dist (resolved through the
# ~/.rn-forge/bin/rnfshk -> shkit/current symlinks).

set -eo pipefail

SELF_PATH="$(readlink -f "$0")"
COMMANDS_PATH="$(dirname "${SELF_PATH}")/commands"

usage() {
  echo "usage: rnfshk <sub-command> [args ...]"
  echo "sub-commands:"
  local script name
  for script in "${COMMANDS_PATH}"/*.sh; do
    name="$(basename "${script}" .sh)"
    echo "  ${name//_/-}"
  done
}

if [ $# -eq 0 ] || [ "$1" = "-h" ] || [ "$1" = "--help" ] || [ "$1" = "help" ]; then
  usage
  exit 0
fi

SUB_COMMAND="$1"
shift
SUB_COMMAND_SCRIPT="${COMMANDS_PATH}/${SUB_COMMAND//-/_}.sh"
if [ ! -x "${SUB_COMMAND_SCRIPT}" ]; then
  echo "rnfshk: unknown sub-command '${SUB_COMMAND}'" >&2
  usage >&2
  exit 1
fi

exec "${SUB_COMMAND_SCRIPT}" "$@"
