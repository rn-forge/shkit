# print.sh

Styled stdout output for human-facing script UI.

## Overview

print_* functions write directly to stdout with no timestamps or level
prefixes. Intended for output the user is meant to read: banners, step
indicators, section headers, and status lines.

Contrast with log.sh:
log_* → stderr, timestamped, diagnostic metadata, for log-tailing
print_* → stdout, no metadata, for the script's primary human output

print_* functions never call log_*; they write directly via printf.
Colors come from RNF_COLOR_* vars defined in console.sh.
RNF_COLOR_SUCCESS and RNF_COLOR_ERROR are shared with log.sh.

Dependencies: console.sh
Safe to source multiple times (guarded by _RNF_PRINT_LOADED).

## Index

* [print_header](#print_header)
* [print_step](#print_step)
* [print_banner](#print_banner)
* [print_success](#print_success)
* [print_error](#print_error)
* [print_divider](#print_divider)

### print_header

Print a bold, colored section heading to stdout.

#### Example

```bash
print_header "Installing dependencies"
# output: === Installing dependencies ===
```

#### Arguments

* **$1** (string): Heading text.

#### Exit codes

* **0**: Always.

#### Output on stdout

* Colored bold heading line.

### print_step

Print a numbered step line to stdout.

#### Example

```bash
print_step 1 "Cloning repository"
# output: [1] Cloning repository
```

#### Arguments

* **$1** (string): Step number or label.
* **...** (string): Step description.

#### Exit codes

* **0**: Always.

#### Output on stdout

* Bold step indicator followed by description.

### print_banner

Print a prominent banner box around text to stdout.
Draws attention to major script phases or start/end announcements.

#### Example

```bash
print_banner "Deployment complete"
# output:
# ==========================
#   Deployment complete
# ==========================
```

#### Arguments

* **$1** (string): Banner text.

#### Exit codes

* **0**: Always.

#### Output on stdout

* Bold bordered box with the text.

### print_success

Print a green success line to stdout.

#### Example

```bash
print_success "Build complete"
# output: ✓ Build complete
```

#### Arguments

* **...** (string): Message.

#### Exit codes

* **0**: Always.

#### Output on stdout

* Green check mark followed by message.

### print_error

Print a red error line to stdout. Does not exit.
For structured diagnostic output use log_error instead.

#### Example

```bash
print_error "Config file missing"
# output: ✗ Config file missing
```

#### Arguments

* **...** (string): Message.

#### Exit codes

* **0**: Always.

#### Output on stdout

* Red cross mark followed by message.

### print_divider

Print a colored horizontal divider line to stdout.

#### Arguments

* **$1** (string): Character to repeat. Default: '-'.
* **$2** (integer): Width in characters. Default: 80.

#### Exit codes

* **0**: Always.

