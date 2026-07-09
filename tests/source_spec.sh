#!/bin/bash
# shellcheck shell=bash

Describe 'source.sh'
# Stage a dist tree with a stub bundle: rnf_marker proves the bundle got
# sourced; log_* stubs are needed by install.sh, which source.sh downloads
# and runs as a standalone file (so it must be self-contained, not sourced
# from a sibling commands/ directory).
make_dist() {
  mkdir -p "${1}/commands"
  cat >"${1}/rn-forge-shkit.sh" <<EOF
_RNF_VERSION="${2} (test)"
log_verbose() { :; }
log_info() { :; }
log_warning() { :; }
log_success() { printf 'SUCCESS: %s\n' "\$*" >&2; }
rnf_marker() { printf 'marker %s\n' "\$_RNF_VERSION"; }
EOF
  printf '%s\n' "$2" >"${1}/VERSION"
  printf '#!/bin/bash\n' >"${1}/rnfshk.sh"
  cp src/install.sh "${1}/install.sh"
  chmod +x "${1}/rnfshk.sh" "${1}/install.sh"
}

make_tarball() {
  make_dist "${tmpdir}/remote" "$1"
  tar -czf "${tmpdir}/rn-forge-shkit.tar.gz" -C "${tmpdir}/remote" .
}

install_fake() {
  make_dist "${RNF_HOME}/shkit/v${1}" "$1"
  ln -sfn "v${1}" "${RNF_HOME}/shkit/current"
}

setup() {
  tmpdir="$(mktemp -d)"
  RNF_HOME="${tmpdir}/home"
  # source.sh downloads install.sh itself before install.sh can download the
  # tarball — point both at local fixtures so no test hits the network.
  cp src/install.sh "${tmpdir}/install.sh"
  # shellcheck disable=SC2034  # consumed by source.sh
  RNF_INSTALL_URL="file://${tmpdir}/install.sh"
  # shellcheck disable=SC2034  # consumed by install.sh
  RNF_UPDATE_URL="file://${tmpdir}/rn-forge-shkit.tar.gz"
}
cleanup() { rm -rf "$tmpdir"; }
Before setup
After cleanup

# Source the entry point the way a consuming script would, then prove the
# library is loaded by calling a function the bundle defines.
source_kit() { . src/source.sh && rnf_marker; }

It 'sources the installed bundle without downloading'
install_fake "1.0.0"
RNF_UPDATE_URL="file://${tmpdir}/does-not-exist.tar.gz"
When call source_kit
The output should equal 'marker 1.0.0 (test)'
End

It 'downloads and installs the dist when missing'
make_tarball "2.0.0"
When call source_kit
The output should equal 'marker 2.0.0 (test)'
The error should include 'installed (current -> v2.0.0)'
The file "${RNF_HOME}/shkit/v2.0.0/rn-forge-shkit.sh" should be exist
End

It 'fails when the download fails'
RNF_UPDATE_URL="file://${tmpdir}/does-not-exist.tar.gz"
When call source_kit
The status should equal 1
The error should include 'download failed'
End

It 'rejects a download that is not an rn-forge-shkit dist'
printf 'not a tarball\n' >"${tmpdir}/rn-forge-shkit.tar.gz"
When call source_kit
The status should equal 1
The error should include 'not an rn-forge-shkit dist'
End

It 'reuses a matching pinned version without downloading'
install_fake "1.0.0"
# shellcheck disable=SC2034  # consumed by source.sh
RNF_VERSION="1.0.0"
RNF_UPDATE_URL="file://${tmpdir}/does-not-exist.tar.gz"
When call source_kit
The output should equal 'marker 1.0.0 (test)'
End

It 'installs a pinned version when missing'
make_tarball "2.0.0"
RNF_VERSION="2.0.0"
When call source_kit
The output should equal 'marker 2.0.0 (test)'
The error should include 'installed (current -> v2.0.0)'
The file "${RNF_HOME}/shkit/v2.0.0/rn-forge-shkit.sh" should be exist
End

It 'fails when the pinned version does not match the download'
make_tarball "2.0.0"
RNF_VERSION="3.0.0"
When call source_kit
The status should equal 1
The error should include 'missing after install'
End

It 'rejects an invalid pinned version before constructing a path'
RNF_VERSION="../bad"
When call source_kit
The status should equal 1
The error should include 'invalid RNF_VERSION'
End
End
