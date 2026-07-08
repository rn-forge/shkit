#!/bin/bash
# shellcheck shell=bash
# Installs (or updates) the rn-forge-shkit distribution into RNF_HOME with a
# versioned layout:
#   ${RNF_HOME}/shkit/<version>/   copy of the dist tree
#   ${RNF_HOME}/shkit/current      symlink to the active version
#   ${RNF_HOME}/bin/rnfshk         symlink to current/rnfshk.sh
#
# Standalone entry point — curl it directly on a fresh machine:
#   curl -fsSL https://github.com/rn-forge/rn-forge-shkit/releases/latest/download/install.sh | bash
# or run it from a checkout/unpacked release: bash dist/shkit/install.sh
#
# When run next to an unpacked dist (sibling rn-forge-shkit.sh + VERSION
# present), installs that tree directly — this is how a freshly-extracted
# tarball reaches this script. Otherwise (piped straight from curl, no
# sibling files) it downloads the release tarball first, honoring
# RNF_VERSION / RNF_UPDATE_URL, and re-runs the extracted copy.
#
# `install.sh --update` always fetches, even when sibling files are present —
# this is how `rnfshk update` re-checks for a newer release from an already-
# installed copy (which otherwise looks identical to a freshly-extracted one).
#
# Config vars:
#   RNF_HOME        Install root. Default: ~/.rn-forge.
#   RNF_VERSION     Pin a release (e.g. 0.2.0). Default: latest.
#   RNF_UPDATE_URL  Override the tarball download URL entirely.
#   RNF_GITHUB_ORG  GitHub org/user the release lives under. Default: rn-forge.

set -eo pipefail

RNF_HOME="${RNF_HOME:-${HOME}/.rn-forge}"
RNF_GITHUB_ORG="${RNF_GITHUB_ORG:-rn-forge}"

FORCE_FETCH=0
if [ "${1:-}" = "--update" ]; then
  FORCE_FETCH=1
fi

SRC_ROOT=""
if [ -f "$0" ]; then
  SRC_ROOT="$(dirname "$(readlink -f "$0")")"
fi

# Prints the sha256 of $1 — sha256sum on Linux, shasum on macOS.
sha256_of() {
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$1" | awk '{print $1}'
  else
    shasum -a 256 "$1" | awk '{print $1}'
  fi
}

# Downloads the release tarball and re-runs the install.sh it contains.
# Used when this script has no sibling dist tree — i.e. curled standalone.
fetch_and_install() {
  if ! command -v curl >/dev/null 2>&1; then
    echo "install.sh: curl is required" >&2
    exit 1
  fi

  local url
  if [ -n "${RNF_VERSION:-}" ]; then
    url="${RNF_UPDATE_URL:-https://github.com/${RNF_GITHUB_ORG}/rn-forge-shkit/releases/download/v${RNF_VERSION}/rn-forge-shkit.tar.gz}"
  else
    url="${RNF_UPDATE_URL:-https://github.com/${RNF_GITHUB_ORG}/rn-forge-shkit/releases/latest/download/rn-forge-shkit.tar.gz}"
  fi

  local tmp
  tmp="$(mktemp -d)" || exit 1
  trap 'rm -rf "${tmp}"' EXIT

  echo "install.sh: downloading ${url}" >&2
  if ! curl -fsSL "$url" -o "${tmp}/rn-forge-shkit.tar.gz"; then
    echo "install.sh: download failed: ${url}" >&2
    exit 1
  fi

  if curl -fsSL "${url}.sha256" -o "${tmp}/rn-forge-shkit.tar.gz.sha256" 2>/dev/null; then
    local expected actual
    expected="$(awk '{print $1}' "${tmp}/rn-forge-shkit.tar.gz.sha256")"
    actual="$(sha256_of "${tmp}/rn-forge-shkit.tar.gz")"
    if [ "$expected" != "$actual" ]; then
      echo "install.sh: checksum mismatch for ${url}" >&2
      exit 1
    fi
  else
    echo "install.sh: no checksum found at ${url}.sha256, skipping verification" >&2
  fi

  if ! tar -xzf "${tmp}/rn-forge-shkit.tar.gz" -C "$tmp" 2>/dev/null ||
    [ ! -f "${tmp}/VERSION" ] || ! grep -q '^_RNF_VERSION=' "${tmp}/rn-forge-shkit.sh" 2>/dev/null; then
    echo "install.sh: download is not an rn-forge-shkit dist: ${url}" >&2
    exit 1
  fi

  local new_version current_version
  new_version="v$(cat "${tmp}/VERSION")"
  current_version=""
  if [ -f "${RNF_HOME}/shkit/current/VERSION" ]; then
    current_version="v$(cat "${RNF_HOME}/shkit/current/VERSION")"
  fi
  if [ "${new_version}" = "${current_version}" ]; then
    echo "install.sh: already up to date: ${current_version}" >&2
    return 0
  fi

  RNF_HOME="${RNF_HOME}" bash "${tmp}/install.sh"
}

if [ "$FORCE_FETCH" = "1" ] || [ -z "${SRC_ROOT}" ] ||
  [ ! -f "${SRC_ROOT}/rn-forge-shkit.sh" ] || [ ! -f "${SRC_ROOT}/VERSION" ]; then
  fetch_and_install
  exit 0
fi

# Source the bundle being installed for log_* helpers.
. "${SRC_ROOT}/rn-forge-shkit.sh"

DIST_VERSION="v$(cat "${SRC_ROOT}/VERSION")"
PRODUCT_HOME="${RNF_HOME}/shkit"
DIST_PATH="${PRODUCT_HOME}/${DIST_VERSION}"
LOCK_DIR="${PRODUCT_HOME}/.install.lock"

# Serializes concurrent installs (e.g. parallel CI jobs on a shared, cached
# $RNF_HOME) via a mkdir-based lock — portable across macOS/Linux, unlike
# flock. Breaks a stale lock after one timeout rather than deadlocking
# forever on a crashed prior run.
#
# LOCK_DIR is a script-global, not a local — the release trap fires at
# script EXIT, after this function has already returned and any local
# would be out of scope (silently expanding to empty, making `rm -rf`
# a no-op and leaking the lock).
acquire_install_lock() {
  local waited=0 broke_stale=0
  while ! mkdir "${LOCK_DIR}" 2>/dev/null; do
    if [ "$waited" -ge 30 ]; then
      if [ "$broke_stale" -eq 0 ]; then
        log_verbose "Breaking stale install lock ${LOCK_DIR} ..."
        rm -rf "${LOCK_DIR}"
        broke_stale=1
        continue
      fi
      echo "install.sh: could not acquire install lock ${LOCK_DIR}" >&2
      exit 1
    fi
    sleep 1
    waited=$((waited + 1))
  done
  trap 'rm -rf "${LOCK_DIR}"' EXIT
}

install_dist() {
  log_verbose "Installing distribution ${DIST_VERSION} ..."
  mkdir -p "${RNF_HOME}/bin" "${PRODUCT_HOME}"
  acquire_install_lock

  # canonicalize before comparing — SRC_ROOT is fully resolved, DIST_PATH may not be
  if [ "${SRC_ROOT}" != "$(readlink -f "${DIST_PATH}" 2>/dev/null || true)" ]; then
    # Build the new version in a scratch dir first, then swap it into place
    # with rm+mv (fast, same-filesystem) instead of rm-then-cp-in-place — a
    # failed cp only ever leaves the scratch dir broken, never DIST_PATH.
    local tmp_dist="${PRODUCT_HOME}/.tmp-${DIST_VERSION}-$$"
    rm -rf "${tmp_dist}"
    mkdir -p "${tmp_dist}"
    cp -R "${SRC_ROOT}/." "${tmp_dist}/"
    rm -rf "${DIST_PATH}"
    mv "${tmp_dist}" "${DIST_PATH}"
  fi

  ln -sfn "${DIST_VERSION}" "${PRODUCT_HOME}/current"
  ln -sfn "../shkit/current/rnfshk.sh" "${RNF_HOME}/bin/rnfshk"
}

migrate_legacy() {
  # one-time cleanup of the pre-0.2.0 single-file install
  if [ -f "${RNF_HOME}/rn-forge.sh" ] && [ ! -L "${RNF_HOME}/rn-forge.sh" ]; then
    log_verbose "Removing legacy ${RNF_HOME}/rn-forge.sh ..."
    rm -f "${RNF_HOME}/rn-forge.sh"
  fi
}

install_dist
migrate_legacy
log_success "rn-forge-shkit installed (current -> ${DIST_VERSION})"
