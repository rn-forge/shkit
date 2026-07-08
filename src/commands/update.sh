#!/bin/bash
# shellcheck shell=bash
# Fetches and installs a newer rn-forge-shkit release (or RNF_VERSION pin).
# Delegates to the sibling install.sh with --update, which forces the fetch
# even though this installed copy already has sibling dist files.
#
# Config vars:
#   RNF_VERSION     Pin a release (e.g. 0.2.0). Default: latest.
#   RNF_UPDATE_URL  Override the tarball download URL entirely.

set -eo pipefail

SELF_PATH="$(readlink -f "$0")"
SRC_ROOT="$(dirname "$(dirname "${SELF_PATH}")")"

exec "${SRC_ROOT}/install.sh" --update
