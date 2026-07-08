#!/bin/bash
# shellcheck shell=bash

Describe 'log.sh'
Include src/lib/console.sh
Include src/lib/log.sh

Describe 'level constants'
It 'defines NONE as 0'
When call printf '%d' "$RNF_LOG_LEVEL_NONE"
The output should equal '0'
End

It 'defines DEBUG as 10'
When call printf '%d' "$RNF_LOG_LEVEL_DEBUG"
The output should equal '10'
End

It 'defines INFO as 20'
When call printf '%d' "$RNF_LOG_LEVEL_INFO"
The output should equal '20'
End

It 'defines SUCCESS as 35 (above WARNING at 30)'
When call printf '%d' "$RNF_LOG_LEVEL_SUCCESS"
The output should equal '35'
End

It 'defines CRITICAL as 50'
When call printf '%d' "$RNF_LOG_LEVEL_CRITICAL"
The output should equal '50'
End
End

Describe 'stderr output format'
It 'writes to stderr and not stdout'
When call log_info 'hello world'
The output should equal ''
The error should include 'hello world'
End

It 'includes the level label for INFO'
When call log_info 'test message'
The error should include '[INFO    ]'
End

It 'includes the level label for WARNING'
When call log_warning 'watch out'
The error should include '[WARNING ]'
The error should include 'watch out'
End

It 'includes the level label for ERROR'
When call log_error 'something failed'
The error should include '[ERROR   ]'
The error should include 'something failed'
End

It 'includes the level label for CRITICAL'
When call log_critical 'fatal'
The error should include '[CRITICAL]'
End

It 'includes a UTC timestamp'
When call log_info 'ts check'
The error should match pattern '*[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]T*Z*'
End
End

Describe 'level filtering'
It 'suppresses messages below RNF_LOG_LEVEL'
RNF_LOG_LEVEL=40
When call log_info 'should be hidden'
The error should equal ''
End

It 'emits messages at exactly RNF_LOG_LEVEL'
RNF_LOG_LEVEL=20
When call log_info 'should appear'
The error should include 'should appear'
End

It 'emits messages above RNF_LOG_LEVEL'
RNF_LOG_LEVEL=20
When call log_error 'also appears'
The error should include 'also appears'
End
End

Describe 'RNF_LOG_FILE logfmt output'
logfile="/tmp/rnf_log_spec_$$"

Before 'RNF_LOG_FILE="$logfile"'
After 'rm -f "$logfile"; unset RNF_LOG_FILE'

It 'writes a logfmt line to RNF_LOG_FILE'
When call log_info 'logfmt test'
The error should include 'logfmt test'
The contents of file "$logfile" should include 'level=INFO'
The contents of file "$logfile" should include 'msg="logfmt test"'
End

It 'includes pid= in logfmt output'
When call log_info 'pid check'
The error should include 'pid check'
The contents of file "$logfile" should include 'pid='
End

It 'includes time= in logfmt output'
When call log_info 'time check'
The error should include 'time check'
The contents of file "$logfile" should include 'time='
End

It 'injects RNF_LOG_CONTEXT fields into logfmt'
RNF_LOG_CONTEXT='svc=deploy env=prod'
When call log_info 'context test'
The error should include 'context test'
The contents of file "$logfile" should include 'svc=deploy'
The contents of file "$logfile" should include 'env=prod'
End

It 'escapes newlines in multiline messages as literal \n in logfmt'
When call log_info "$(printf 'first\nsecond')"
The error should include 'first'
The contents of file "$logfile" should include 'first\nsecond'
End
End

Describe 'log_divider'
It 'writes a line of dashes to stderr by default'
When call log_divider
The error should match pattern '*---*'
The output should equal ''
End

It 'uses the given character'
When call log_divider '='
The error should match pattern '*===*'
End

It 'respects the given width'
When call log_divider '-' 10
The error should include '----------'
End
End
End
