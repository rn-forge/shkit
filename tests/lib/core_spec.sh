#!/bin/bash
# shellcheck shell=bash

Describe 'core.sh'
Include src/lib/core.sh

Describe 'var_get'
It 'returns the value of a set variable'
greeting="hello world"
When call var_get greeting
The output should equal 'hello world'
End

It 'returns empty string for an unset variable'
When call var_get __unset_var__
The output should equal ''
End
End

Describe 'divider'
It 'prints 80 dashes by default'
When call divider
The output should equal "$(printf '%080d' 0 | tr '0' '-')"
End

It 'prints the given character at the given width'
When call divider '=' 10
The output should equal '=========='
End

It 'prints a single character at width 1'
When call divider '*' 1
The output should equal '*'
End
End

Describe 'timestamp'
It 'returns a string matching YYYY-MM-DD HH:MM:SS'
When call timestamp
The output should match pattern '[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9] [0-9][0-9]:[0-9][0-9]:[0-9][0-9]'
End
End

Describe 'rnf_version'
It 'returns "dev" when _RNF_VERSION is unset'
When call rnf_version
The output should equal 'dev'
End

It 'returns _RNF_VERSION when set (as injected by scripts/build.sh)'
_RNF_VERSION="1.2.3 (abc1234)"
When call rnf_version
The output should equal '1.2.3 (abc1234)'
End
End
End
