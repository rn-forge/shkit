#!/bin/bash
# shellcheck shell=bash
# cleanup.sh removes old installed versions, keeping only the one `current`
# points to. confirm/log_* behavior itself is covered by tests/lib/script_spec.sh
# and tests/lib/log_spec.sh; these specs cover the version-selection wiring.

Describe 'cleanup.sh'
REPO_ROOT="$(pwd)"

make_dist() {
  mkdir -p "${1}/commands"
  cat >"${1}/shkit.sh" <<EOF
_RNF_VERSION="${2} (test)"
. "${REPO_ROOT}/src/lib/console.sh"
. "${REPO_ROOT}/src/lib/log.sh"
. "${REPO_ROOT}/src/lib/core.sh"
. "${REPO_ROOT}/src/lib/script.sh"
EOF
  printf '%s\n' "$2" >"${1}/VERSION"
  cp src/commands/cleanup.sh "${1}/commands/cleanup.sh"
  chmod +x "${1}/commands/cleanup.sh"
}

setup() {
  tmpdir="$(mktemp -d)"
  RNF_HOME="${tmpdir}/home"
  RNF_SKIP_CONFIRMATIONS=1
  export RNF_HOME RNF_SKIP_CONFIRMATIONS
  make_dist "${RNF_HOME}/shkit/v1.0.0" "1.0.0"
}
cleanup() { rm -rf "$tmpdir"; }
Before setup
After cleanup

It 'reports no installations when RNF_HOME does not exist'
unset RNF_HOME
RNF_HOME="${tmpdir}/missing"
export RNF_HOME
When run script "${tmpdir}/home/shkit/v1.0.0/commands/cleanup.sh"
The status should equal 0
The error should include 'No installations found'
End

It 'errors when no current symlink exists'
When run script "${RNF_HOME}/shkit/v1.0.0/commands/cleanup.sh"
The status should equal 1
The error should include 'No current install found'
The directory "${RNF_HOME}/shkit/v1.0.0" should be exist
End

It 'reports nothing to remove when only current exists'
ln -s v1.0.0 "${RNF_HOME}/shkit/current"
When run script "${RNF_HOME}/shkit/v1.0.0/commands/cleanup.sh"
The status should equal 0
The error should include 'No old installations to remove'
The directory "${RNF_HOME}/shkit/v1.0.0" should be exist
End

It 'removes old versions but keeps current'
make_dist "${RNF_HOME}/shkit/v2.0.0" "2.0.0"
ln -s v2.0.0 "${RNF_HOME}/shkit/current"
When run script "${RNF_HOME}/shkit/v2.0.0/commands/cleanup.sh"
The status should equal 0
The error should include 'Removed 1 old installation(s)'
The output should include 'v1.0.0'
The directory "${RNF_HOME}/shkit/v1.0.0" should not be exist
The directory "${RNF_HOME}/shkit/v2.0.0" should be exist
End

It 'does not remove anything when the user declines'
make_dist "${RNF_HOME}/shkit/v2.0.0" "2.0.0"
ln -s v2.0.0 "${RNF_HOME}/shkit/current"
unset RNF_SKIP_CONFIRMATIONS
Data "n"
When run script "${RNF_HOME}/shkit/v2.0.0/commands/cleanup.sh"
The status should equal 1
The output should include 'v1.0.0'
The output should include '(y/n)'
The error should include 'Cancelled.'
The directory "${RNF_HOME}/shkit/v1.0.0" should be exist
End
End
