#!/bin/bash
# shellcheck shell=bash
# update.sh is a thin delegator to the sibling install.sh — the fetch/
# validate/no-op logic itself is covered by install_spec.sh. These specs
# just confirm the delegation wiring works end to end.

Describe 'update.sh'
make_dist() {
  mkdir -p "${1}/commands"
  cat >"${1}/rn-forge-shkit.sh" <<EOF
_RNF_VERSION="${2} (test)"
log_verbose() { :; }
log_success() { printf 'SUCCESS: %s\n' "\$*" >&2; }
EOF
  printf '%s\n' "$2" >"${1}/VERSION"
  printf '#!/bin/bash\n' >"${1}/rnfshk.sh"
  cp src/install.sh "${1}/install.sh"
  cp src/commands/update.sh "${1}/commands/update.sh"
  chmod +x "${1}/rnfshk.sh" "${1}/install.sh" "${1}/commands/update.sh"
}

make_tarball() {
  make_dist "${tmpdir}/remote" "$1"
  tar -czf "${tmpdir}/rn-forge-shkit.tar.gz" -C "${tmpdir}/remote" .
}

setup() {
  tmpdir="$(mktemp -d)"
  RNF_HOME="${tmpdir}/home"
  export RNF_HOME
  # installed v1.0.0 layout
  make_dist "${RNF_HOME}/shkit/v1.0.0" "1.0.0"
  ln -s v1.0.0 "${RNF_HOME}/shkit/current"
  # shellcheck disable=SC2034  # consumed by install.sh
  RNF_UPDATE_URL="file://${tmpdir}/rn-forge-shkit.tar.gz"
  export RNF_UPDATE_URL
}
cleanup() { rm -rf "$tmpdir"; }
Before setup
After cleanup

current_points_to() { [ "$(readlink "${RNF_HOME}/shkit/current")" = "$1" ]; }

It 'installs a newer release and flips current'
make_tarball "2.0.0"
When run script "${RNF_HOME}/shkit/current/commands/update.sh"
The status should equal 0
The error should include 'installed (current -> v2.0.0)'
Assert current_points_to v2.0.0
The file "${RNF_HOME}/shkit/v1.0.0/rn-forge-shkit.sh" should be exist
The file "${RNF_HOME}/shkit/v2.0.0/rn-forge-shkit.sh" should be exist
End

It 'is a no-op when already at the downloaded version'
make_tarball "1.0.0"
When run script "${RNF_HOME}/shkit/current/commands/update.sh"
The status should equal 0
The error should include 'already up to date: v1.0.0'
Assert current_points_to v1.0.0
End
End
