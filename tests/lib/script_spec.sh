#!/bin/bash
# shellcheck shell=bash

Describe 'script.sh'
Include src/lib/console.sh
Include src/lib/log.sh
Include src/lib/core.sh
Include src/lib/script.sh

Before 'RNF_NO_COLOR=1'

Describe 'SCRIPT_NAME and SCRIPT_DIR'
It 'sets SCRIPT_NAME to a non-empty string'
When call printf '%s' "$SCRIPT_NAME"
The output should not equal ''
End

It 'sets SCRIPT_DIR to an absolute path'
When call printf '%s' "$SCRIPT_DIR"
The output should match pattern '/*'
End
End

Describe 'show_help'
Before 'unset RNF_SCRIPT_DESCRIPTION RNF_SCRIPT_ARGS RNF_SCRIPT_OPTIONS'

It 'prints SCRIPT_NAME in the usage line'
When call show_help
The output should include "$SCRIPT_NAME [OPTIONS]"
The status should equal 0
End

It 'appends RNF_SCRIPT_ARGS to the usage line when set'
RNF_SCRIPT_ARGS="FILE"
When call show_help
The output should include '[OPTIONS] FILE'
End

It 'prints RNF_SCRIPT_DESCRIPTION below the usage line when set'
RNF_SCRIPT_DESCRIPTION="Deploy the application."
When call show_help
The output should include 'Deploy the application.'
End

It 'prints RNF_SCRIPT_OPTIONS under an OPTIONS header when set'
RNF_SCRIPT_OPTIONS="  -e ENV   Target environment"
When call show_help
The output should include 'OPTIONS:'
The output should include '-e ENV'
End

It 'omits OPTIONS section when RNF_SCRIPT_OPTIONS is unset'
When call show_help
The output should not include 'OPTIONS:'
End

It 'writes to stdout and not stderr'
When call show_help
The output should include '[OPTIONS]'
The error should equal ''
End
End

Describe 'handle_invalid_args'
Before 'unset RNF_SCRIPT_DESCRIPTION RNF_SCRIPT_ARGS RNF_SCRIPT_OPTIONS'

It 'logs the error message to stderr'
When run handle_invalid_args 1 'MODE is required'
The status should equal 1
The error should include 'MODE is required'
The output should include '[OPTIONS]'
End

It 'exits with the given exit code'
When run handle_invalid_args 3 'bad value'
The status should equal 3
The error should include 'bad value'
The output should include '[OPTIONS]'
End

It 'always prints usage from SCRIPT_NAME'
When run handle_invalid_args 1 'bad value'
The status should equal 1
The error should include 'bad value'
The output should include '[OPTIONS]'
End

It 'includes RNF_SCRIPT_OPTIONS in output when set'
RNF_SCRIPT_OPTIONS="  -e ENV   Target environment"
When run handle_invalid_args 1 'bad value'
The status should equal 1
The error should include 'bad value'
The output should include '-e ENV'
End
End

Describe 'print_vars'
It 'logs each named variable and its value'
MYHOST="localhost"
MYPORT="8080"
When call print_vars MYHOST MYPORT
The error should include 'MYHOST=localhost'
The error should include 'MYPORT=8080'
End

It 'uses a custom log function when given as the first arg'
DEPLOY_ENV="staging"
When call print_vars log_warning DEPLOY_ENV
The error should include 'DEPLOY_ENV=staging'
The error should include '[WARNING ]'
End

It 'handles an unset variable gracefully'
unset UNSET_VAR
When call print_vars UNSET_VAR
The error should include 'UNSET_VAR='
End
End

Describe 'confirm'
Describe 'with RNF_SKIP_CONFIRMATIONS=1'
It 'auto-proceeds and logs without prompting'
RNF_SKIP_CONFIRMATIONS=1
When call confirm 'Delete all files'
The status should equal 0
The error should include 'auto-confirmed'
End

It 'still prompts when --force is passed'
RNF_SKIP_CONFIRMATIONS=1
Data "y"
When call confirm 'Wipe database' --force
The status should equal 0
The output should include '(y/n)'
End
End

Describe 'with interactive input'
It 'returns 0 on y input'
Data "y"
When call confirm 'Proceed'
The status should equal 0
The output should include '(y/n)'
End

It 'returns 0 on Y input'
Data "Y"
When call confirm 'Proceed'
The status should equal 0
The output should include '(y/n)'
End

It 'returns 0 on "yes" line input (POSIX read fallback)'
Data "yes"
When call confirm 'Proceed'
The status should equal 0
The output should include '(y/n)'
End

It 'exits with 1 and logs Cancelled on n input'
Data "n"
When run confirm 'Proceed'
The status should equal 1
The output should include '(y/n)'
The error should include 'Cancelled'
End

It 'exits with 1 on any non-y input'
Data "q"
When run confirm 'Proceed'
The status should equal 1
The output should include '(y/n)'
The error should include 'Cancelled'
End
End
End

Describe 'prompt'
read_into_output() {
  prompt captured_var 'Enter a value'
  printf '%s' "$captured_var"
}

It 'reads a line of input into the named variable'
Data "hello world"
When call read_into_output
The output should include 'hello world'
End

It 'displays the prompt message to stdout'
Data "anything"
When call read_into_output
The output should include 'Enter a value'
End
End
End
