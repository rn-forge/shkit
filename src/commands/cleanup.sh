#!/bin/bash
# shellcheck shell=bash
# Removes old installed shkit versions under RNF_HOME, keeping only the
# version the `current` symlink points to.
#
# Config vars:
#   RNF_HOME                Install root. Default: ~/.rn-forge.
#   RNF_SKIP_CONFIRMATIONS  Set to '1' to skip the confirmation prompt.

set -eo pipefail

SRC_ROOT="$(cd "$(dirname "$0")/.." && pwd -P)"

. "${SRC_ROOT}/shkit.sh"

RNF_HOME="${RNF_HOME:-${HOME}/.rn-forge}"
PRODUCT_HOME="${RNF_HOME}/shkit"

if [ ! -d "${PRODUCT_HOME}" ]; then
  log_info "No installations found at ${PRODUCT_HOME}"
  exit 0
fi

if [ ! -L "${PRODUCT_HOME}/current" ]; then
  log_error "No current install found at ${PRODUCT_HOME}/current"
  exit 1
fi
CURRENT_VERSION="$(readlink "${PRODUCT_HOME}/current")"

OLD_VERSIONS=()
while IFS= read -r dir; do
  OLD_VERSIONS+=("${dir}")
done < <(find "${PRODUCT_HOME}" -mindepth 1 -maxdepth 1 -type d -name 'v*' ! -name "${CURRENT_VERSION}")

if [ "${#OLD_VERSIONS[@]}" -eq 0 ]; then
  log_info "No old installations to remove"
  exit 0
fi

log_info "Old installations to remove (keeping ${CURRENT_VERSION:-current}):"
for dir in "${OLD_VERSIONS[@]}"; do
  echo "  $(basename "${dir}")"
done

confirm "Remove ${#OLD_VERSIONS[@]} old installation(s) from ${PRODUCT_HOME}"

for dir in "${OLD_VERSIONS[@]}"; do
  rm -rf "${dir}"
done

log_success "Removed ${#OLD_VERSIONS[@]} old installation(s)"
