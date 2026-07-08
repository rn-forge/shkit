#!/bin/bash
# shellcheck shell=bash

Describe 'console.sh'
Include src/lib/console.sh

Describe '_rnf_color_enabled'
It 'returns failure when RNF_NO_COLOR=1'
RNF_NO_COLOR=1
When call _rnf_color_enabled
The status should be failure
End

It 'returns failure when the FD is not a TTY, even with RNF_NO_COLOR unset'
unset RNF_NO_COLOR
When call _rnf_color_enabled 1
The status should be failure
End
End

Describe 'strip_ansi'
strip_colored() { printf '\033[32mhello\033[0m' | strip_ansi; }
strip_plain() { printf 'hello world' | strip_ansi; }
strip_compound() { printf '\033[1;31mbold red\033[0m and normal' | strip_ansi; }

It 'removes a single ANSI color code'
When call strip_colored
The output should equal 'hello'
End

It 'passes plain text through unchanged'
When call strip_plain
The output should equal 'hello world'
End

It 'removes multiple compound ANSI codes in one line'
When call strip_compound
The output should equal 'bold red and normal'
End
End

Describe 'RNF_COLOR_* defaults'
It 'sets RNF_COLOR_DEBUG to a non-empty value'
When call printf '%s' "$RNF_COLOR_DEBUG"
The output should not equal ''
End

It 'sets RNF_COLOR_ERROR to a non-empty value'
When call printf '%s' "$RNF_COLOR_ERROR"
The output should not equal ''
End

It 'sets RNF_COLOR_HEADER to a non-empty value'
When call printf '%s' "$RNF_COLOR_HEADER"
The output should not equal ''
End
End
End
