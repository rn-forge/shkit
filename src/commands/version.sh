#!/bin/bash
# shellcheck shell=bash
# Prints the installed rn-forge-shkit version.

set -eo pipefail

SRC_ROOT="$(cd "$(dirname "$0")/.." && pwd -P)"

. "${SRC_ROOT}/rn-forge-shkit.sh"

rnf_version
