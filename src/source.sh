#!/bin/bash
# shellcheck shell=bash
# Streams the rn-forge-shkit library into the current shell. Meant to be
# sourced from consuming scripts (bash or zsh), not executed:
#
#   . <(curl -fsSL https://github.com/rohitnarayanan/rn-forge-shkit/releases/latest/download/source.sh)
#
# or vendor this file next to your script and source it directly. Sources the
# installed bundle when present; otherwise downloads install.sh and runs it
# first, so the first run needs the network and later runs don't.
#
# Config vars:
#   RNF_HOME         Install root. Default: ~/.rn-forge.
#   RNF_VERSION      Pin a release (e.g. 0.2.0); sources ${RNF_HOME}/shkit/v<version>.
#   RNF_UPDATE_URL   Override the tarball download URL entirely (passed through to install.sh).
#   RNF_INSTALL_URL  Override the install.sh download URL itself.
#
# Safe under `set -eu` in the consuming script.

# Ensures the dist is installed and prints the bundle path on stdout. The
# bundle itself must be sourced at file top level, NOT inside this function:
# under zsh, `readonly` in a sourced file inside a function creates
# function-local variables, so the bundle's constants would vanish on return.
_rnf_source_prepare() {
  local home="${RNF_HOME:-${HOME}/.rn-forge}"
  local dist="${home}/shkit/current"

  if [ -n "${RNF_VERSION:-}" ]; then
    dist="${home}/shkit/v${RNF_VERSION}"
  fi

  if [ ! -f "${dist}/rn-forge-shkit.sh" ]; then
    if ! command -v curl >/dev/null 2>&1; then
      printf 'rn-forge-shkit source: curl is required\n' >&2
      return 1
    fi
    local tmp install_url
    tmp="$(mktemp -d)" || return 1
    install_url="${RNF_INSTALL_URL:-https://github.com/rohitnarayanan/rn-forge-shkit/releases/latest/download/install.sh}"
    if ! curl -fsSL "$install_url" -o "${tmp}/install.sh"; then
      printf 'rn-forge-shkit source: download failed: %s\n' "$install_url" >&2
      rm -rf "$tmp"
      return 1
    fi
    # Forward explicitly — RNF_VERSION/RNF_UPDATE_URL may be plain (unexported)
    # shell variables here, and a child process only inherits exported ones.
    if ! RNF_HOME="$home" RNF_VERSION="${RNF_VERSION:-}" RNF_UPDATE_URL="${RNF_UPDATE_URL:-}" \
      bash "${tmp}/install.sh"; then
      printf 'rn-forge-shkit source: install failed\n' >&2
      rm -rf "$tmp"
      return 1
    fi
    rm -rf "$tmp"
    if [ ! -f "${dist}/rn-forge-shkit.sh" ]; then
      printf 'rn-forge-shkit source: %s missing after install — does the pinned RNF_VERSION match the download?\n' "${dist}/rn-forge-shkit.sh" >&2
      return 1
    fi
  fi

  printf '%s\n' "${dist}/rn-forge-shkit.sh"
}

if _RNF_SOURCE_BUNDLE="$(_rnf_source_prepare)"; then
  unset -f _rnf_source_prepare
  . "$_RNF_SOURCE_BUNDLE"
  unset _RNF_SOURCE_BUNDLE
else
  unset -f _rnf_source_prepare
  unset _RNF_SOURCE_BUNDLE
  # `return` works when sourced; fall back to `exit` if executed directly.
  # shellcheck disable=SC2317  # reachable when executed rather than sourced
  return 1 2>/dev/null || exit 1
fi
