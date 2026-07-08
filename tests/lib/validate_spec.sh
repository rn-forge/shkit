#!/bin/bash
# shellcheck shell=bash

Describe 'validate.sh'
Include src/lib/core.sh
Include src/lib/console.sh
Include src/lib/log.sh
Include src/lib/validate.sh

Describe 'check_required'
It 'passes silently when the named var is set'
MYVAR="value"
When call check_required 1 MYVAR
The status should equal 0
The error should equal ''
End

It 'exits with the given code and logs when a var is unset'
unset MISSING_VAR
When run check_required 1 MISSING_VAR
The status should equal 1
The error should include 'MISSING_VAR'
End

It 'exits on the first empty var when multiple are given'
SETVAR="ok"
unset EMPTYVAR
When run check_required 2 SETVAR EMPTYVAR
The status should equal 2
The error should include 'EMPTYVAR'
End

It 'passes when all vars in a list are set'
VARA="a"
VARB="b"
When call check_required 1 VARA VARB
The status should equal 0
End
End

Describe 'check_value_in_list'
It 'passes when value is in the allowed list'
MODE="i"
When call check_value_in_list 1 MODE i u a
The status should equal 0
End

It 'exits and logs when value is not in the allowed list'
MODE="x"
When run check_value_in_list 1 MODE i u a
The status should equal 1
The error should include 'MODE'
The error should include 'x'
End

It 'passes for a value that matches case-sensitively'
MODE="I"
When call check_value_in_list 1 MODE i I u U
The status should equal 0
End

It 'exits with the configured exit code'
MODE="z"
When run check_value_in_list 5 MODE a b c
The status should equal 5
The error should include 'MODE'
End
End

Describe 'check_pattern'
It 'returns 0 when value matches the pattern'
When call check_pattern 'version' '1.2.3' '^[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*$'
The status should equal 0
End

It 'returns 1 and logs when value does not match the pattern'
When call check_pattern 'version' 'not-a-version' '^[0-9]'
The status should equal 1
The error should include 'version'
The error should include 'not-a-version'
End

It 'does not exit on mismatch — caller controls flow'
When call check_pattern 'x' 'bad' '^good$'
The status should equal 1
The error should include 'bad'
End

It 'matches a simple alphanumeric pattern'
When call check_pattern 'name' 'hello123' '^[a-z0-9]*$'
The status should equal 0
End

It 'matches an empty value against ^$'
When call check_pattern 'empty' '' '^$'
The status should equal 0
End

It 'rejects an empty value against a non-empty pattern'
When call check_pattern 'empty' '' '^[a-z]'
The status should equal 1
The error should include 'empty'
End

It 'rejects a prefix match — goodBAD must not pass ^good'
When call check_pattern 'label' 'goodBAD' '^good'
The status should equal 1
The error should include 'goodBAD'
End

It 'rejects a multiline value'
When call check_pattern 'ml' "$(printf 'a\nb')" '^.*$'
The status should equal 1
The error should include 'newlines'
End

It 'honours backreferences — abab matches ^\(ab\)\1$'
When call check_pattern 'ref' 'abab' '^\(ab\)\1$'
The status should equal 0
End

It 'honours backreferences — abcd fails ^\(ab\)\1$'
When call check_pattern 'ref' 'abcd' '^\(ab\)\1$'
The status should equal 1
The error should include 'abcd'
End
End
End
