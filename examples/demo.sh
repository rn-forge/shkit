#!/bin/bash
# shellcheck shell=bash
# Demonstrates the rn-forge-shkit library. Run after `mise run build`:
#   sh examples/demo.sh
# Or source the bundle explicitly:
#   RN_FORGE_BUNDLE=~/.rn-forge/shkit/current/rn-forge-shkit.sh sh examples/demo.sh

set -eu

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BUNDLE="${RN_FORGE_BUNDLE:-${REPO_ROOT}/dist/shkit/rn-forge-shkit.sh}"
if [ ! -f "$BUNDLE" ]; then
  printf 'error: bundle not found at %s\n' "$BUNDLE" >&2
  printf 'Run: mise run build\n' >&2
  exit 1
fi
. "$BUNDLE"

# ---------------------------------------------------------------------------
# Banner
# ---------------------------------------------------------------------------

print_banner "rn-forge-shkit demo"

# ---------------------------------------------------------------------------
# Logging
# ---------------------------------------------------------------------------

print_header "Logging"

log_debug "debug message (hidden at default INFO level)"
log_verbose "verbose message (hidden at default INFO level)"
log_info "info message"
export RNF_LOG_LEVEL="${RNF_LOG_LEVEL_DEBUG}"
log_debug "debug message (visible after log level change)"
log_verbose "verbose message (visible after log level change)"
log_notice "notice message"
log_warning "warning message"
log_success "success message"
log_error "error message"
log_divider "+"

# Enable debug output for the next section
RNF_LOG_LEVEL=$RNF_LOG_LEVEL_DEBUG
log_debug "debug now visible (RNF_LOG_LEVEL=DEBUG)"
RNF_LOG_LEVEL=$RNF_LOG_LEVEL_INFO

# ---------------------------------------------------------------------------
# Print (stdout, no log metadata)
# ---------------------------------------------------------------------------

print_header "Print"

print_step 1 "Cloning repository"
print_step 2 "Installing dependencies"
print_step 3 "Running tests"
print_success "All steps complete"
print_error "Something went wrong (non-fatal example)"
print_divider

# ---------------------------------------------------------------------------
# Core utilities
# ---------------------------------------------------------------------------

print_header "Core"

log_info "timestamp: $(timestamp)"

export GREETING="hello from var_get"
log_info "var_get: $(var_get GREETING)"

# ---------------------------------------------------------------------------
# Validation
# ---------------------------------------------------------------------------

print_header "Validation"

DEPLOY_ENV="staging"
check_value_in_list 1 DEPLOY_ENV dev staging prod &&
  log_success "DEPLOY_ENV='$DEPLOY_ENV' is valid"

VERSION_TAG="v1.2.3"
check_pattern "version tag" "$VERSION_TAG" '^v[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*$' &&
  log_success "VERSION_TAG='$VERSION_TAG' matches pattern"

# ---------------------------------------------------------------------------
# Interactive (skipped in non-interactive / CI)
# ---------------------------------------------------------------------------

print_header "Interactive (skipped in CI)"

if [ -t 0 ]; then
  confirm "Continue with interactive demo?"
  prompt USER_NAME "Enter your name"
  log_info "Hello, ${USER_NAME}!"
  pause "Press any key to finish"
else
  log_info "stdin is not a TTY — skipping interactive section"
fi

# ---------------------------------------------------------------------------
# Done
# ---------------------------------------------------------------------------

print_banner "Done"
