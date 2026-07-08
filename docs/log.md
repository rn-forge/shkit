# log.sh

Leveled logging with pretty stderr output and logfmt file output.

## Overview

Provides a 9-level logging API (DEBUG through CRITICAL) with numeric
spacing borrowed from verboselogs. Output is written to two streams:
- stderr: colored, human-readable, timestamped (pretty format)
- RNF_LOG_FILE: logfmt-formatted for machine parsing and log aggregators

Config vars:
RNF_LOG_LEVEL    Minimum level to emit. Default: RNF_LOG_LEVEL_INFO (20).
RNF_LOG_FILE     Path to logfmt output file. Unset = file output disabled.
RNF_LOG_CONTEXT  Free-form key=value pairs injected into logfmt lines.
Example: RNF_LOG_CONTEXT="svc=deploy env=prod"
RNF_COLOR_*      Per-level color overrides — set in or before console.sh.
RNF_NO_COLOR     Set to 1 to suppress ANSI codes even on a TTY.

Dependencies: console.sh
Safe to source multiple times (guarded by _RNF_LOG_LOADED).

## Index

* [log_debug](#log_debug)
* [log_verbose](#log_verbose)
* [log_info](#log_info)
* [log_notice](#log_notice)
* [log_warning](#log_warning)
* [log_success](#log_success)
* [log_error](#log_error)
* [log_critical](#log_critical)
* [log_divider](#log_divider)

### log_debug

Log at DEBUG level (10). Fine-grained diagnostic detail.

#### Arguments

* **...** (string): Message.

#### Exit codes

* **0**: Always.

### log_verbose

Log at VERBOSE level (15). More detail than INFO, less noise than DEBUG.

#### Arguments

* **...** (string): Message.

#### Exit codes

* **0**: Always.

### log_info

Log at INFO level (20). Routine operational messages.

#### Arguments

* **...** (string): Message.

#### Exit codes

* **0**: Always.

### log_notice

Log at NOTICE level (25). Normal but noteworthy events.

#### Arguments

* **...** (string): Message.

#### Exit codes

* **0**: Always.

### log_warning

Log at WARNING level (30). Unexpected but recoverable; script continues.

#### Arguments

* **...** (string): Message.

#### Exit codes

* **0**: Always.

### log_success

Log at SUCCESS level (35). A significant operation completed successfully.

#### Arguments

* **...** (string): Message.

#### Exit codes

* **0**: Always.

### log_error

Log at ERROR level (40). A recoverable or reported failure.

#### Arguments

* **...** (string): Message.

#### Exit codes

* **0**: Always.

### log_critical

Log at CRITICAL level (50). Unrecoverable failure — script should abort.

#### Arguments

* **...** (string): Message.

#### Exit codes

* **0**: Always.

### log_divider

Write a horizontal divider line to stderr.

#### Arguments

* **$1** (string): Character to repeat. Default: '-'.
* **$2** (integer): Width in characters. Default: 80.

#### Exit codes

* **0**: Always.

