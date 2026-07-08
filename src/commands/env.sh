#!/bin/bash
# shellcheck shell=bash
# Prints the current RNF_* configuration.

set -eo pipefail

SELF_PATH="$(readlink -f "$0")"
SRC_ROOT="$(dirname "$(dirname "${SELF_PATH}")")"

. "${SRC_ROOT}/rn-forge-shkit.sh"

for var in RNF_HOME RNF_VERSION RNF_LOG_LEVEL RNF_LOG_FILE RNF_LOG_CONTEXT \
  RNF_NO_COLOR RNF_SKIP_CONFIRMATIONS RNF_OUTPUT_FILE RNF_UPDATE_URL; do
  printf '%s=%s\n' "$var" "$(var_get "$var")"
done
