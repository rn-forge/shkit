#!/bin/bash
# shellcheck shell=bash

Describe 'print.sh'
Include src/lib/console.sh
Include src/lib/print.sh

# Force plain output — test runner stdout is not a TTY anyway,
# but set explicitly so tests don't depend on that assumption.
Before 'RNF_NO_COLOR=1'

Describe 'print_header'
It 'wraps text in === delimiters'
When call print_header 'Installing dependencies'
The output should equal '=== Installing dependencies ==='
End

It 'writes to stdout and not stderr'
When call print_header 'Test'
The output should include 'Test'
The error should equal ''
End
End

Describe 'print_step'
It 'formats as [N] description'
When call print_step 1 'Cloning repository'
The output should equal '[1] Cloning repository'
End

It 'handles multi-word step descriptions'
When call print_step 2 'Build and test'
The output should equal '[2] Build and test'
End

It 'works with non-numeric step labels'
When call print_step 'a' 'Optional step'
The output should equal '[a] Optional step'
End
End

Describe 'print_banner'
It 'contains the text'
When call print_banner 'Done'
The output should include 'Done'
End

It 'includes a border of = characters'
When call print_banner 'Done'
The output should match pattern '*====*'
End

It 'produces exactly three lines (border / text / border)'
banner_lines() { print_banner 'Hi' | wc -l | tr -d ' '; }
When call banner_lines
The output should equal '3'
End
End

Describe 'print_success'
It 'prefixes message with a check mark'
When call print_success 'Build complete'
The output should equal '✓ Build complete'
End

It 'writes to stdout and not stderr'
When call print_success 'ok'
The output should include 'ok'
The error should equal ''
End
End

Describe 'print_error'
It 'prefixes message with a cross mark'
When call print_error 'Config missing'
The output should equal '✗ Config missing'
End

It 'writes to stdout and not stderr'
When call print_error 'oops'
The output should include 'oops'
The error should equal ''
End
End

Describe 'print_divider'
It 'prints 80 dashes by default'
When call print_divider
The output should equal "$(printf '%080d' 0 | tr '0' '-')"
End

It 'uses the given character and width'
When call print_divider '=' 10
The output should equal '=========='
End

It 'writes to stdout and not stderr'
When call print_divider
The output should match pattern '*---*'
The error should equal ''
End
End
End
