#!/bin/bash
# shellcheck shell=bash
# Prints the installed rn-forge-shkit version.

set -eo pipefail

SELF_PATH="$(readlink -f "$0")"
SRC_ROOT="$(dirname "$(dirname "${SELF_PATH}")")"

. "${SRC_ROOT}/rn-forge-shkit.sh"

rnf_version
