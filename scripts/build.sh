#!/bin/bash
# Builds the rn-forge-shkit distribution into dist/:
#   dist/shkit/                  staged dist tree (= tarball contents):
#     rn-forge-shkit.sh          bundle — src/lib modules concatenated in
#                                dependency order, shdoc blocks stripped
#     rn-forge-shkit.sh.map      line-range map for issue traceability
#     rnfshk.sh, install.sh, commands/, VERSION
#   dist/rn-forge-shkit.tar.gz   tarball of dist/shkit contents
#   dist/rn-forge-shkit.sh(.map) loose bundle assets for direct sourcing
#   dist/source.sh               streaming-sourcing entry point
#   dist/install.sh              standalone installer entry point

set -eu

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
STAGE="${REPO_ROOT}/dist/shkit"
DIST="${STAGE}/rn-forge-shkit.sh"
MAP="${DIST}.map"

# Module list in dependency order — console before log (log depends on it), etc.
MODULES="
src/lib/console.sh
src/lib/log.sh
src/lib/core.sh
src/lib/validate.sh
src/lib/proc.sh
src/lib/script.sh
src/lib/print.sh
src/lib/git.sh
"

# Strip shdoc blocks: contiguous # comment runs that contain at least one # @ line.
# Directives (shellcheck) and inline implementation comments (no # @) are preserved.
strip_shdoc() {
  awk '
    /^# @/ { in_shdoc=1; buf=buf $0 "\n"; next }
    /^#/   { if (in_shdoc) { buf=buf $0 "\n"; next } }
    {
      if (in_shdoc) { in_shdoc=0; buf="" }
      print
    }
  '
}

# Count lines in a file.
line_count() { wc -l <"$1" | tr -d ' '; }

# Prints the sha256 of $1 — sha256sum on Linux, shasum on macOS.
sha256_of() {
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$1" | awk '{print $1}'
  else
    shasum -a 256 "$1" | awk '{print $1}'
  fi
}

GIT_SHA="$(git -C "${REPO_ROOT}" rev-parse --short HEAD 2>/dev/null || printf 'unknown')"
# VERSION may be set by the caller (e.g. CI sets it to the tag: v1.0.0).
VERSION="$(cat "${REPO_ROOT}"/VERSION)"
GITHUB_ORG="${RNF_GITHUB_ORG:-rn-forge}"

rm -rf "${STAGE}"
mkdir -p "${STAGE}"

# Write bundle and collect line ranges for the map in one pass.
map_entries=""
current_line=0

{
  printf '#!/bin/sh\n'
  printf '# rn-forge-shkit.sh — generated bundle\n'
  printf '# Version: %s\n' "${VERSION}"
  printf '# Built:   %s\n' "$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
  printf '# Commit:  %s\n' "$GIT_SHA"
  printf '# Source:  https://github.com/%s/rn-forge-shkit\n' "$GITHUB_ORG"
  printf '\n'
  printf '_RNF_VERSION="%s (%s)"\n' "$VERSION" "$GIT_SHA"
  printf '\n'
} >"$DIST"

current_line="$(line_count "$DIST")"

for module in $MODULES; do
  path="${REPO_ROOT}/${module}"
  if [ ! -f "$path" ]; then
    printf 'error: module not found: %s\n' "$path" >&2
    exit 1
  fi

  # Write section header + processed module content to a temp file so we can
  # count its lines before appending — keeps the map accurate.
  tmp="${STAGE}/.tmp_module"
  {
    printf '# ---- %s ----\n' "$module"
    tail -n +2 "$path" | strip_shdoc
    printf '\n'
  } >"$tmp"

  module_lines="$(line_count "$tmp")"
  start=$((current_line + 1))
  end=$((current_line + module_lines))
  map_entries="${map_entries}${module}	${start}-${end}\n"
  current_line="$end"

  cat "$tmp" >>"$DIST"
done

rm -f "${STAGE}/.tmp_module"
chmod +x "$DIST"

# Write the map file.
{
  printf '# rn-forge-shkit.sh source map\n'
  printf '# Version: %s\n' "$VERSION"
  printf '# Commit:  %s\n' "$GIT_SHA"
  printf '# Format:  <source_file>  <bundle_start_line>-<bundle_end_line>\n'
  printf '#\n'
  printf '%b' "$map_entries"
} >"$MAP"

# Stage the rest of the dist tree: dispatcher bin, installer, subcommand
# scripts (commands/), VERSION.
cp -f "${REPO_ROOT}/src/rnfshk.sh" "${STAGE}/rnfshk.sh"
cp -f "${REPO_ROOT}/src/install.sh" "${STAGE}/install.sh"
mkdir -p "${STAGE}/commands"
cp -f "${REPO_ROOT}"/src/commands/*.sh "${STAGE}/commands/"
cp -f "${REPO_ROOT}/VERSION" "${STAGE}/VERSION"
chmod +x "${STAGE}/rnfshk.sh" "${STAGE}/install.sh" "${STAGE}"/commands/*.sh

# Release assets: tarball of the staged tree + loose copies for direct use.
tar -czf "${REPO_ROOT}/dist/rn-forge-shkit.tar.gz" -C "${STAGE}" .
sha256_of "${REPO_ROOT}/dist/rn-forge-shkit.tar.gz" >"${REPO_ROOT}/dist/rn-forge-shkit.tar.gz.sha256"
cp -f "$DIST" "$MAP" "${REPO_ROOT}/dist/"
cp -f "${REPO_ROOT}/src/source.sh" "${REPO_ROOT}/dist/source.sh"
cp -f "${REPO_ROOT}/src/install.sh" "${REPO_ROOT}/dist/install.sh"

printf 'Staged:   %s\n' "$STAGE"
printf 'Tarball:  %s\n' "${REPO_ROOT}/dist/rn-forge-shkit.tar.gz"
printf 'Checksum: %s\n' "${REPO_ROOT}/dist/rn-forge-shkit.tar.gz.sha256"
printf 'Bundle:   %s\n' "${REPO_ROOT}/dist/rn-forge-shkit.sh"
printf 'Source:   %s\n' "${REPO_ROOT}/dist/source.sh"
printf 'Install:  %s\n' "${REPO_ROOT}/dist/install.sh"
