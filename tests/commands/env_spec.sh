#!/bin/bash
# shellcheck shell=bash
# env.sh is a thin wrapper around the bundle's var_get — these specs confirm
# it prints every documented RNF_* variable in order, not var_get itself
# (covered by tests/lib/core_spec.sh).

Describe 'env.sh'
make_dist() {
  mkdir -p "${1}/commands"
  cat >"${1}/shkit.sh" <<EOF
_RNF_VERSION="${2} (test)"
. "$(pwd)/src/lib/core.sh"
EOF
  printf '%s\n' "$2" >"${1}/VERSION"
  cp src/commands/env.sh "${1}/commands/env.sh"
  chmod +x "${1}/commands/env.sh"
}

setup() {
  tmpdir="$(mktemp -d)"
  make_dist "${tmpdir}/dist" "1.2.3"
  unset RNF_HOME RNF_VERSION RNF_LOG_LEVEL RNF_LOG_FILE RNF_LOG_CONTEXT \
    RNF_NO_COLOR RNF_SKIP_CONFIRMATIONS RNF_OUTPUT_FILE RNF_UPDATE_URL
}
cleanup() { rm -rf "$tmpdir"; }
Before setup
After cleanup

It 'prints every RNF_* variable in order, empty when unset'
When run script "${tmpdir}/dist/commands/env.sh"
The status should equal 0
The output should equal "$(
  cat <<'EOF'
RNF_HOME=
RNF_VERSION=
RNF_LOG_LEVEL=
RNF_LOG_FILE=
RNF_LOG_CONTEXT=
RNF_NO_COLOR=
RNF_SKIP_CONFIRMATIONS=
RNF_OUTPUT_FILE=
RNF_UPDATE_URL=
EOF
)"
End

It 'prints the current value of set variables'
RNF_HOME="/tmp/rnf-home"
RNF_LOG_LEVEL="20"
export RNF_HOME RNF_LOG_LEVEL
When run script "${tmpdir}/dist/commands/env.sh"
The status should equal 0
The output should include 'RNF_HOME=/tmp/rnf-home'
The output should include 'RNF_LOG_LEVEL=20'
The output should include 'RNF_LOG_CONTEXT='
End
End
