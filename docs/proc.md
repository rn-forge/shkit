# proc.sh

Process execution and result-handling utilities.

## Overview

Helpers for checking command exit codes and waiting on background processes.

Dependencies: log.sh
Safe to source multiple times (guarded by _RNF_PROC_LOADED).

## Index

* [check_return_code](#check_return_code)
* [wait_for_children](#wait_for_children)

### check_return_code

Check a command's return code, log the result, and optionally exit.
Pass EXIT_CODE=0 to log the failure without aborting.

#### Example

```bash
brew install ripgrep
check_return_code $? 1 "brew install"
```

#### Arguments

* **$1** (integer): Return code of the command that was run (typically $?).
* **$2** (integer): Exit code to use if the command failed. 0 = log only, no exit.
* **$3** (string): Label describing the operation (used in log messages).

#### Exit codes

* **0**:  RC was zero (command succeeded).
* $**2**: RC was non-zero and EXIT_CODE > 0.

### wait_for_children

Wait for a list of background processes and return the combined exit status.
Waits on each PID in order. Tracks the highest non-zero exit status seen
so a single failure does not prevent waiting on the remaining processes.

#### Example

```bash
slow_cmd_a & pid_a=$!
slow_cmd_b & pid_b=$!
wait_for_children $pid_a $pid_b
check_return_code $? 1 "background tasks"
```

#### Arguments

* **...** (integer): One or more PIDs returned by backgrounded commands.

#### Exit codes

* **0**: All child processes exited successfully.
* N Highest non-zero exit status returned by any child.

