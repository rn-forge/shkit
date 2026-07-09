#!/bin/bash
# shellcheck shell=bash

Describe 'install.sh'
# Stage a dist tree (install.sh sources its sibling bundle for log_* helpers).
make_dist() {
  mkdir -p "${1}/commands"
  cat >"${1}/rn-forge-shkit.sh" <<EOF
_RNF_VERSION="${2} (test)"
log_verbose() { :; }
log_info() { :; }
log_warning() { :; }
log_success() { printf 'SUCCESS: %s\n' "\$*" >&2; }
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

sha256_of() {
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$1" | awk '{print $1}'
  else
    shasum -a 256 "$1" | awk '{print $1}'
  fi
}

rnf_realpath() {
  local target="$1" dir link name
  while [ -L "$target" ]; do
    dir="$(cd "$(dirname "$target")" && pwd -P)" || return 1
    link="$(readlink "$target")" || return 1
    case "$link" in
    /*) target="$link" ;;
    *) target="${dir}/${link}" ;;
    esac
  done
  dir="$(cd "$(dirname "$target")" && pwd -P)" || return 1
  name="$(basename "$target")"
  printf '%s/%s\n' "$dir" "$name"
}

setup() {
  tmpdir="$(mktemp -d)"
  RNF_HOME="${tmpdir}/home"
  export RNF_HOME
  make_dist "${tmpdir}/dist" "1.0.0"
}
cleanup() { rm -rf "$tmpdir"; }
Before setup
After cleanup

current_points_to() { [ "$(readlink "${RNF_HOME}/shkit/current")" = "$1" ]; }
rnfshk_link_resolves_to() {
  [ "$(rnf_realpath "${RNF_HOME}/bin/rnfshk")" = "$(rnf_realpath "${RNF_HOME}/shkit/${1}/rnfshk.sh")" ]
}

Describe 'run next to an unpacked dist (local mode)'
It 'installs the dist tree versioned with current and bin symlinks'
When run script "${tmpdir}/dist/install.sh"
The status should equal 0
The error should include 'installed (current -> v1.0.0)'
The file "${RNF_HOME}/shkit/v1.0.0/rn-forge-shkit.sh" should be exist
Assert current_points_to v1.0.0
Assert rnfshk_link_resolves_to v1.0.0
End

It 'flips current to a newer version and keeps the old one'
bash "${tmpdir}/dist/install.sh" 2>/dev/null
make_dist "${tmpdir}/dist2" "2.0.0"
When run script "${tmpdir}/dist2/install.sh"
The status should equal 0
The error should include 'installed (current -> v2.0.0)'
Assert current_points_to v2.0.0
The file "${RNF_HOME}/shkit/v1.0.0/rn-forge-shkit.sh" should be exist
The file "${RNF_HOME}/shkit/v2.0.0/rn-forge-shkit.sh" should be exist
End

It 'reinstalls from the installed copy without deleting it'
bash "${tmpdir}/dist/install.sh" 2>/dev/null
When run script "${RNF_HOME}/shkit/current/install.sh"
The status should equal 0
The error should include 'installed (current -> v1.0.0)'
The file "${RNF_HOME}/shkit/v1.0.0/rn-forge-shkit.sh" should be exist
Assert current_points_to v1.0.0
End

It 'removes a legacy pre-0.2.0 single-file install'
mkdir -p "${RNF_HOME}"
printf 'old bundle\n' >"${RNF_HOME}/rn-forge.sh"
When run script "${tmpdir}/dist/install.sh"
The status should equal 0
The error should include 'installed'
The file "${RNF_HOME}/rn-forge.sh" should not be exist
End

It 'serializes concurrent installs without leaking the lock'
concurrent_install() {
  setopt no_bg_nice 2>/dev/null || true
  bash "${tmpdir}/dist/install.sh" >/dev/null 2>&1 &
  bash "${tmpdir}/dist/install.sh" >/dev/null 2>&1 &
  wait
}
When call concurrent_install
The status should equal 0
The directory "${RNF_HOME}/shkit/.install.lock" should not be exist
Assert current_points_to v1.0.0
The file "${RNF_HOME}/shkit/v1.0.0/rn-forge-shkit.sh" should be exist
End

It 'fails instead of breaking an install lock it cannot acquire'
mkdir -p "${RNF_HOME}/shkit/.install.lock"
RNF_INSTALL_LOCK_TIMEOUT=0
export RNF_INSTALL_LOCK_TIMEOUT
When run script "${tmpdir}/dist/install.sh"
The status should equal 1
The error should include 'could not acquire install lock'
The directory "${RNF_HOME}/shkit/.install.lock" should be exist
End

It 'rejects an invalid local VERSION before constructing install paths'
make_dist "${tmpdir}/bad-dist" "../bad"
When run script "${tmpdir}/bad-dist/install.sh"
The status should equal 1
The error should include 'invalid VERSION'
The directory "${RNF_HOME}/shkit/v../bad" should not be exist
End
End

Describe 'run standalone (no sibling dist — curled fresh)'
setup_standalone() {
  standalone_dir="${tmpdir}/standalone"
  mkdir -p "$standalone_dir"
  cp src/install.sh "${standalone_dir}/install.sh"
  chmod +x "${standalone_dir}/install.sh"
  # shellcheck disable=SC2034  # consumed by install.sh
  RNF_UPDATE_URL="file://${tmpdir}/rn-forge-shkit.tar.gz"
  export RNF_UPDATE_URL
}
Before setup_standalone

It 'downloads the tarball and installs it'
make_tarball "1.0.0"
When run script "${standalone_dir}/install.sh"
The status should equal 0
The error should include 'downloading'
The error should include 'no checksum found'
The error should include 'installed (current -> v1.0.0)'
The file "${RNF_HOME}/shkit/v1.0.0/rn-forge-shkit.sh" should be exist
Assert current_points_to v1.0.0
End

It 'verifies a matching checksum before installing'
make_tarball "1.0.0"
sha256_of "${tmpdir}/rn-forge-shkit.tar.gz" >"${tmpdir}/rn-forge-shkit.tar.gz.sha256"
When run script "${standalone_dir}/install.sh"
The status should equal 0
The error should not include 'checksum mismatch'
The error should not include 'no checksum found'
The error should include 'installed (current -> v1.0.0)'
Assert current_points_to v1.0.0
End

It 'rejects a tarball with a mismatched checksum'
make_tarball "1.0.0"
printf '%s\n' '0000000000000000000000000000000000000000000000000000000000000000' >"${tmpdir}/rn-forge-shkit.tar.gz.sha256"
When run script "${standalone_dir}/install.sh"
The status should equal 1
The error should include 'checksum mismatch'
The file "${RNF_HOME}/shkit/v1.0.0/rn-forge-shkit.sh" should not be exist
End

It 'is a no-op when the downloaded version matches the installed one'
bash "${tmpdir}/dist/install.sh" 2>/dev/null # pre-install v1.0.0 locally
make_tarball "1.0.0"
When run script "${standalone_dir}/install.sh"
The status should equal 0
The error should include 'already up to date: v1.0.0'
Assert current_points_to v1.0.0
End

It 'fails when the download fails'
# shellcheck disable=SC2034  # consumed by install.sh
RNF_UPDATE_URL="file://${tmpdir}/does-not-exist.tar.gz"
When run script "${standalone_dir}/install.sh"
The status should equal 1
The error should include 'download failed'
End

It 'rejects an invalid RNF_VERSION pin before download'
RNF_VERSION="../bad"
export RNF_VERSION
When run script "${standalone_dir}/install.sh"
The status should equal 1
The error should include 'invalid RNF_VERSION'
End

It 'rejects a download that is not an rn-forge-shkit dist'
printf 'not a tarball\n' >"${tmpdir}/rn-forge-shkit.tar.gz"
When run script "${standalone_dir}/install.sh"
The status should equal 1
The error should include 'not an rn-forge-shkit dist'
End

It 'rejects a downloaded dist with an invalid VERSION'
make_tarball "../bad"
When run script "${standalone_dir}/install.sh"
The status should equal 1
The error should include 'invalid VERSION'
End
End
End
