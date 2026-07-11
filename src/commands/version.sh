#!/bin/bash
# shellcheck shell=bash
# Prints the installed shkit version.

set -eo pipefail

SRC_ROOT="$(cd "$(dirname "$0")/.." && pwd -P)"

. "${SRC_ROOT}/shkit.sh"

rnf_version
