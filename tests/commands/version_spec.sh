#!/bin/bash
# shellcheck shell=bash
# version.sh is a thin wrapper around the bundle's rnf_version — these specs
# confirm the sourcing/dispatch wiring, not rnf_version itself (covered by
# tests/lib/core_spec.sh).

Describe 'version.sh'
make_dist() {
  mkdir -p "${1}/commands"
  cat >"${1}/shkit.sh" <<EOF
_RNF_VERSION="${2} (test)"
. "$(pwd)/src/lib/core.sh"
EOF
  printf '%s\n' "$2" >"${1}/VERSION"
  cp src/commands/version.sh "${1}/commands/version.sh"
  chmod +x "${1}/commands/version.sh"
}

setup() {
  tmpdir="$(mktemp -d)"
  make_dist "${tmpdir}/dist" "1.2.3"
}
cleanup() { rm -rf "$tmpdir"; }
Before setup
After cleanup

It 'prints the version baked into the sourced bundle'
When run script "${tmpdir}/dist/commands/version.sh"
The status should equal 0
The output should equal '1.2.3 (test)'
End
End
