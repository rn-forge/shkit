# script.sh

Script context, diagnostics, and interactive input utilities.

## Overview

Sets SCRIPT_NAME and SCRIPT_DIR from the calling script's path, and provides
helpers for help text, variable inspection, environment dumps, and user input.

Interactive input suite:
pause   — wait for any keypress
confirm — yes/no prompt with automation bypass (RNF_SKIP_CONFIRMATIONS)
prompt  — read a line of input into a named variable

Config vars:
RNF_OUTPUT_FILE  Path to capture all stdout+stderr output, ANSI stripped.
Set before sourcing this file to activate. Unset = disabled.

Dependencies: log.sh, core.sh, console.sh
Safe to source multiple times (guarded by _RNF_SCRIPT_LOADED).

## Index

* [show_help](#show_help)
* [handle_invalid_args](#handle_invalid_args)
* [print_vars](#print_vars)
* [debug_environment](#debug_environment)
* [pause](#pause)
* [confirm](#confirm)
* [prompt](#prompt)

### show_help

Print a formatted usage/help message to stdout.
Reads RNF_SCRIPT_* globals — all are optional; unset vars are silently omitted.

#### Example

```bash
RNF_SCRIPT_DESCRIPTION="Deploy the application."
RNF_SCRIPT_ARGS="FILE"
RNF_SCRIPT_OPTIONS="
  -e ENV   Target environment (required)
  -n       Dry run
  -h       Show this help"
show_help
# Usage: deploy.sh [OPTIONS] FILE
# Deploy the application.
#
# OPTIONS: [* Required]
#   -e ENV   Target environment (required)
#   -n       Dry run
#   -h       Show this help
```

_Function has no arguments._

#### Variables set

* RNF_SCRIPT_ARGS        Positional args shown after [OPTIONS] in the usage line.
* **RNF_SCRIPT_DESCRIPTION** (One-line): description printed below the usage line.
* RNF_SCRIPT_OPTIONS     Options block printed under an "OPTIONS: [* Required]" header.

#### Exit codes

* **0**: Always.

#### Output on stdout

* Formatted usage block.

### handle_invalid_args

Log an error for an invalid argument, print usage help, then exit.
Combines log_error + show_help + exit. show_help reads RNF_SCRIPT_* globals —
set them before calling this if you want usage printed.

#### Example

```bash
RNF_SCRIPT_OPTIONS="  -e ENV   Target environment (required)"
handle_invalid_args 1 "MODE must be i, u, or a"
```

#### Arguments

* **$1** (integer): Exit code.
* **$2** (string): Error message describing what was invalid.

#### Exit codes

* $**1**: Always exits.

### print_vars

Log the current values of named variables.
First argument may be a log function name (e.g. log_warn); defaults to log_info.

#### Example

```bash
TARGET="prod"
DRY_RUN="1"
print_vars TARGET DRY_RUN
print_vars log_warn TARGET DRY_RUN
```

#### Arguments

* **$1** (string): Optional log function to use (must start with 'log_'). Default: log_info.
* **...** (string): Variable names whose values should be printed.

#### Exit codes

* **0**: Always.

### debug_environment

Log all environment variables via log_debug.
Output is only visible when RNF_LOG_LEVEL is set to DEBUG or lower.

#### Example

```bash
RNF_LOG_LEVEL=$RNF_LOG_LEVEL_DEBUG
debug_environment
```

_Function has no arguments._

#### Exit codes

* **0**: Always.

### pause

Wait for the user to press any key before continuing.

#### Example

```bash
pause
pause "Review the output above"
```

#### Arguments

* **$1** (string): Optional message to display before the prompt. Default: empty.

#### Exit codes

* **0**: Always.

### confirm

Prompt the user for a yes/no confirmation.
Exits the script with code 1 if the user answers 'n' or presses any key
other than 'y'/'Y'. Auto-proceeds without prompting when RNF_SKIP_CONFIRMATIONS=1,
unless --force is passed.

#### Example

```bash
confirm "Delete all build artefacts"
confirm "Wipe the database — are you sure" --force
```

#### Arguments

* **$1** (string): Confirmation message (the question to display).
* **$2** (string): Optional '--force' flag to always prompt, even if RNF_SKIP_CONFIRMATIONS=1.

#### Variables set

* **RNF_SKIP_CONFIRMATIONS** (When): set to '1', confirm auto-proceeds without prompting.

#### Exit codes

* **0**: User confirmed (or auto-confirmed via RNF_SKIP_CONFIRMATIONS).
* **1**: User declined. Script is exited.

### prompt

Read a line of user input into a named variable.

#### Example

```bash
prompt target_env "Target environment (prod/staging)"
echo "Deploying to: $target_env"
```

#### Arguments

* **$1** (string): Name of the variable to populate.
* **$2** (string): Prompt message displayed before the input cursor.

#### Exit codes

* **0**: Always.

