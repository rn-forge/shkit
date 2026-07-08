#!/bin/bash
# @file print.sh
# @brief Styled stdout output for human-facing script UI.
# @description
#   print_* functions write directly to stdout with no timestamps or level
#   prefixes. Intended for output the user is meant to read: banners, step
#   indicators, section headers, and status lines.
#
#   Contrast with log.sh:
#     log_* → stderr, timestamped, diagnostic metadata, for log-tailing
#     print_* → stdout, no metadata, for the script's primary human output
#
#   print_* functions never call log_*; they write directly via printf.
#   Colors come from RNF_COLOR_* vars defined in console.sh.
#   RNF_COLOR_SUCCESS and RNF_COLOR_ERROR are shared with log.sh.
#
#   Dependencies: console.sh
#   Safe to source multiple times (guarded by _RNF_PRINT_LOADED).

# shellcheck shell=bash

[ "${_RNF_PRINT_LOADED:-}" = "1" ] && return 0
_RNF_PRINT_LOADED=1

# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------

# @description Print a bold, colored section heading to stdout.
#
# @arg $1 string Heading text.
#
# @example
#   print_header "Installing dependencies"
#   # output: === Installing dependencies ===
#
# @stdout Colored bold heading line.
# @exitcode 0 Always.
print_header() {
  if _rnf_color_enabled 1; then
    printf "${RNF_COLOR_HEADER}=== %s ===\033[0m\n" "$1"
  else
    printf "=== %s ===\n" "$1"
  fi
}

# @description Print a numbered step line to stdout.
#
# @arg $1 string Step number or label.
# @arg $@ string Step description.
#
# @example
#   print_step 1 "Cloning repository"
#   # output: [1] Cloning repository
#
# @stdout Bold step indicator followed by description.
# @exitcode 0 Always.
print_step() {
  local n="$1"
  shift
  if _rnf_color_enabled 1; then
    printf "${RNF_COLOR_STEP}[%s]\033[0m %s\n" "$n" "$*"
  else
    printf "[%s] %s\n" "$n" "$*"
  fi
}

# @description Print a prominent banner box around text to stdout.
#   Draws attention to major script phases or start/end announcements.
#
# @arg $1 string Banner text.
#
# @example
#   print_banner "Deployment complete"
#   # output:
#   # ==========================
#   #   Deployment complete
#   # ==========================
#
# @stdout Bold bordered box with the text.
# @exitcode 0 Always.
print_banner() {
  local text="$1"
  local line
  line="$(printf "%*s" "$((${#text} + 4))" "" | tr ' ' '=')"
  if _rnf_color_enabled 1; then
    printf "${RNF_COLOR_BANNER}%s\n  %s  \n%s\033[0m\n" "$line" "$text" "$line"
  else
    printf "%s\n  %s  \n%s\n" "$line" "$text" "$line"
  fi
}

# @description Print a green success line to stdout.
#
# @arg $@ string Message.
#
# @example
#   print_success "Build complete"
#   # output: ✓ Build complete
#
# @stdout Green check mark followed by message.
# @exitcode 0 Always.
print_success() {
  if _rnf_color_enabled 1; then
    printf "${RNF_COLOR_SUCCESS}✓ %s\033[0m\n" "$*"
  else
    printf "✓ %s\n" "$*"
  fi
}

# @description Print a red error line to stdout. Does not exit.
#   For structured diagnostic output use log_error instead.
#
# @arg $@ string Message.
#
# @example
#   print_error "Config file missing"
#   # output: ✗ Config file missing
#
# @stdout Red cross mark followed by message.
# @exitcode 0 Always.
print_error() {
  if _rnf_color_enabled 1; then
    printf "${RNF_COLOR_ERROR}✗ %s\033[0m\n" "$*"
  else
    printf "✗ %s\n" "$*"
  fi
}

# @description Print a colored horizontal divider line to stdout.
#
# @arg $1 string  Character to repeat. Default: '-'.
# @arg $2 integer Width in characters. Default: 80.
#
# @exitcode 0 Always.
print_divider() {
  local char="${1:--}" width="${2:-80}"
  if _rnf_color_enabled 1; then
    printf "${RNF_COLOR_DIVIDER}%s\033[0m\n" "$(printf "%*s" "$width" "" | tr ' ' "$char")"
  else
    printf "%*s\n" "$width" "" | tr ' ' "$char"
  fi
}
