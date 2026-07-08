#!/bin/bash
# shellcheck shell=bash

Describe 'rnfshk.sh'
setup() {
  tmpdir="$(mktemp -d)"
  cp src/rnfshk.sh "${tmpdir}/rnfshk.sh"
  mkdir -p "${tmpdir}/commands"
  cat >"${tmpdir}/commands/greet.sh" <<'EOF'
#!/bin/bash
printf 'greet:%s\n' "$*"
EOF
  cat >"${tmpdir}/commands/self_test.sh" <<'EOF'
#!/bin/bash
printf 'self-test ran\n'
EOF
  chmod +x "${tmpdir}/rnfshk.sh" "${tmpdir}/commands/greet.sh" "${tmpdir}/commands/self_test.sh"
}
cleanup() { rm -rf "$tmpdir"; }
Before setup
After cleanup

It 'prints usage with no arguments, listing sub-commands'
When run script "${tmpdir}/rnfshk.sh"
The output should include 'usage: rnfshk'
The output should include 'greet'
The output should include 'self-test'
End

It 'prints usage for the help command'
When run script "${tmpdir}/rnfshk.sh" help
The output should include 'usage: rnfshk'
End

It 'fails with usage for an unknown sub-command'
When run script "${tmpdir}/rnfshk.sh" bogus
The status should equal 1
The error should include "unknown sub-command 'bogus'"
The error should include 'usage: rnfshk'
End

It 'dispatches to the sub-command script with arguments'
When run script "${tmpdir}/rnfshk.sh" greet hello world
The output should equal 'greet:hello world'
End

It 'maps hyphenated sub-commands to underscore script names'
When run script "${tmpdir}/rnfshk.sh" self-test
The output should equal 'self-test ran'
End
End
