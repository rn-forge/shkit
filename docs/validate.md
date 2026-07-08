# validate.sh

Input validation and guard functions.

## Overview

Validation utilities for checking required variables, allowed values,
and value patterns. All functions log via log.sh on failure.
Does not exit on its own except where documented — callers control flow.

Dependencies: log.sh, core.sh
Safe to source multiple times (guarded by _RNF_VALIDATE_LOADED).

## Index

* [check_required](#check_required)
* [check_value_in_list](#check_value_in_list)
* [check_pattern](#check_pattern)

### check_required

Exit with an error if any of the named variables are unset or empty.

#### Example

```bash
NAME="alice"
check_required 1 NAME           # passes silently
check_required 1 NAME MISSING   # logs error and exits 1
```

#### Arguments

* **$1** (integer): Exit code to use on failure.
* **...** (string): One or more variable names to check (not values — names).

#### Exit codes

* **0**:  All named variables are set and non-empty.
* $**1**: First variable found to be unset or empty.

### check_value_in_list

Exit with an error if a named variable's value is not in the allowed set.

#### Example

```bash
MODE="i"
check_value_in_list 1 MODE i I u U   # passes
```

#### Arguments

* **$1** (integer): Exit code to use on failure.
* **$2** (string): Name of the variable to check (not its value — the name).
* **...** (string): Two or more allowed values.

#### Exit codes

* **0**:  Variable value is in the allowed set.
* $**1**: Variable value is not in the allowed set.

### check_pattern

Verify a value matches a POSIX basic regular expression (BRE).
Uses grep -qx for whole-value matching. Returns 1 on mismatch — does not exit,
so the caller decides how to handle failure.

#### Example

```bash
check_pattern "version" "1.2.3" "^[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*$" || exit 1
```

#### Arguments

* **$1** (string): Label describing what is being validated (used in log messages).
* **$2** (string): Value to test.
* **$3** (string): POSIX BRE pattern the entire value must satisfy.

#### Exit codes

* **0**: Value matches the pattern.
* **1**: Value does not match the pattern.

