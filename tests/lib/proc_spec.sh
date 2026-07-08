#!/bin/bash
# shellcheck shell=bash

Describe 'proc.sh'
Include src/lib/console.sh
Include src/lib/log.sh
Include src/lib/proc.sh

Describe 'check_return_code'
It 'returns 0 and logs success when rc=0'
When call check_return_code 0 1 'my-op'
The status should equal 0
The error should include 'my-op'
The error should include 'ok'
End

It 'exits with exit_code and logs failure when rc!=0 and exit_code>0'
When run check_return_code 1 1 'my-op'
The status should equal 1
The error should include 'my-op'
The error should include 'failed'
End

It 'returns rc and logs failure when exit_code=0'
When call check_return_code 3 0 'optional-op'
The status should equal 3
The error should include 'failed'
End

It 'exits with the configured exit code (not rc) when rc!=0'
When run check_return_code 99 7 'my-op'
The status should equal 7
The error should include 'failed'
End
End

Describe 'wait_for_children'
It 'returns 0 when all children succeed'
(exit 0) &
pid1=$!
(exit 0) &
pid2=$!
When call wait_for_children "$pid1" "$pid2"
The status should equal 0
End

It 'returns the highest non-zero exit status'
(exit 2) &
pid1=$!
(exit 5) &
pid2=$!
When call wait_for_children "$pid1" "$pid2"
The status should equal 5
End

It 'returns the non-zero status even when only one child fails'
(exit 0) &
pid1=$!
(exit 3) &
pid2=$!
When call wait_for_children "$pid1" "$pid2"
The status should equal 3
End

It 'returns 0 for a single successful child'
(exit 0) &
pid=$!
When call wait_for_children "$pid"
The status should equal 0
End

It 'collects all statuses under set -e without aborting early'
(exit 3) &
pid1=$!
(exit 5) &
pid2=$!
_sete_wait() {
  set -e
  wait_for_children "$pid1" "$pid2"
}
When call _sete_wait
The status should equal 5
End
End
End
