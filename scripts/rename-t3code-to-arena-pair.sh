#!/usr/bin/env bash
#
# rename-t3code-to-arena-pair.sh
#
# Rename every literal "T3Code" instance to "Arena Pair" (single-token scheme).
#
# Scope (chosen): ONLY the four product-name forms are swapped. The rest of the
# T3-prefixed ecosystem (@t3tools, T3Markdown, T3Project, CLI `t3`, domain
# `t3.codes`, data dir `~/.t3`, etc.) is intentionally left untouched.
#
# Mapping:
#   T3 Code -> Arena Pair
#   T3Code  -> ArenaPair
#   t3code  -> arenapair
#   T3CODE  -> ARENAPAIR
#
# Usage:
#   ./scripts/rename-t3code-to-arena-pair.sh                 # dry run (default)
#   ./scripts/rename-t3code-to-arena-pair.sh --apply         # write changes
#   ./scripts/rename-t3code-to-arena-pair.sh --apply --all   # include pnpm-lock.yaml
#
# By default pnpm-lock.yaml is SKIPPED (it's generated; regenerate it with
# `pnpm install` after changing source package names instead of hand-editing).
# Path renames (git mv) are a separate, opt-in step: --rename-paths
#
# Exit code 0 means "no changes made" / success. Safe to run repeatedly.

set -euo pipefail

FORMS=("T3Code" "t3code" "T3CODE" "T3 Code")
REPLS=("ArenaPair" "arenapair" "ARENAPAIR" "Arena Pair")

MODE="dry-run"
INCLUDE_LOCKFILE=0
RENAME_PATHS=0
ASSUME_YES=0

usage() {
  cat <<'EOF'
Usage: rename-t3code-to-arena-pair.sh [options]

Options:
  --apply           Write the replacements (default is a dry run).
  --all             Also edit pnpm-lock.yaml (default: skip it; regenerate via `pnpm install`).
  --rename-paths    Also git mv paths that contain t3code / t3-code (default: off; risky, see docs).
  --yes, -y         Skip the confirmation prompt (non-interactive / CI).
  --help            Show this help.
EOF
}

for arg in "$@"; do
  case "$arg" in
    --apply)  MODE="apply" ;;
    --all)    INCLUDE_LOCKFILE=1 ;;
    --rename-paths) RENAME_PATHS=1 ;;
    --yes|-y) ASSUME_YES=1 ;;
    --help|-h) usage; exit 0 ;;
    *) echo "Unknown option: $arg" >&2; usage >&2; exit 2 ;;
  esac
done

# Build list of tracked files to scan: every git-tracked file that matches any
# form. -F = fixed strings (no regex surprises), -l = filenames only.
# We exclude binary files via grep -I. To handle spaces in paths, use -z + -0.
mapfile -d '' -t FILES < <(
  git grep -Fzl \
    -e "${FORMS[0]}" -e "${FORMS[1]}" -e "${FORMS[2]}" -e "${FORMS[3]}" \
    2>/dev/null || true
)

if [[ "${#FILES[@]}" -eq 0 ]]; then
  echo "No tracked files contain any of the T3Code product-name forms."
  exit 0
fi

# Always exclude pnpm-lock.yaml unless --all (regenerate it, don't hand-edit).
if [[ "$INCLUDE_LOCKFILE" -eq 0 ]]; then
  mapfile -d '' -t FILTERED < <(printf '%s\0' "${FILES[@]}" | grep -zZv -e '^pnpm-lock.yaml$' || true)
else
  FILTERED=("${FILES[@]}")
fi

# Exclude our own tooling/docs that intentionally document the OLD strings
# (the plan and the script itself must retain the literal t3code/T3Code forms).
mapfile -d '' -t FILTERED < <(
  printf '%s\0' "${FILTERED[@]}" \
    | grep -zZv \
        -e '^docs/rename-t3code-to-arena-pair.md$' \
        -e '^scripts/rename-t3code-to-arena-pair.sh$' \
    || true
)

report_counts() {
  local total=0
  for i in "${!FORMS[@]}"; do
    local c
    # -F fixed strings, -h suppress filename, -o print only each match (one per
    # line), so wc -l == number of occurrences.
    c=$(git grep -Fho -- "${FORMS[i]}" -- "${FILTERED[@]}" 2>/dev/null | wc -l || true)
    printf '  %-12s -> %-12s : %5d occurrences in %d files\n' \
      "${FORMS[i]}" "${REPLS[i]}" "$c" \
      "$(git grep -Fl -e "${FORMS[i]}" -- "${FILTERED[@]}" 2>/dev/null | wc -l)"
    total=$(( total + c ))
  done
  echo "  ---"
  echo "  Total matches: $total across ${#FILTERED[@]} files"
}

echo "=== T3Code -> Arena Pair (literal, single-token) ==="
echo "Mode: ${MODE}  (files in scope: ${#FILTERED[@]})"
echo "Breakdown:"
report_counts

if [[ "$MODE" == "dry-run" ]]; then
  echo ""
  echo "Dry run complete. No files were changed."
  echo "Run with --apply to write the replacements, then:"
  echo "  git diff --stat                     # review the change set"
  echo "  pnpm install                        # regenerate pnpm-lock.yaml"
  echo "  <run your test/typecheck command>   # verify"
  exit 0
fi

# --apply
if [[ "$ASSUME_YES" -eq 0 ]]; then
  read -r -p "Apply replacements to ${#FILTERED[@]} files? [y/N] " ans
  if [[ ! "$ans" =~ ^[Yy]$ ]]; then
    echo "Aborted."
    exit 0
  fi
fi

printf '%s\0' "${FILTERED[@]}" | xargs -0 perl -pi -e \
  's/T3Code/ArenaPair/g; s/t3code/arenapair/g; s/T3CODE/ARENAPAIR/g; s/T3 Code/Arena Pair/g'

echo "Applied. Remaining matches (should be 0):"
report_counts

# Optional path renames
if [[ "$RENAME_PATHS" -eq 1 ]]; then
  echo "=== Renaming paths containing t3code / t3-code ==="
  # docs file (hyphenated slug -> hyphenated target)
  git mv docs/internals/t3-code-connect-auth-flow.html docs/internals/arena-pair-connect-auth-flow.html 2>/dev/null || echo "skip: docs file already renamed or missing"
  # oxlint plugin dir (t3code -> arenapair)
  git mv oxlint-plugin-t3code oxlint-plugin-arenapair 2>/dev/null || echo "skip: oxlint-plugin dir already renamed or missing"
  # AUR packaging dirs
  git mv packaging/aur/t3code-bin packaging/aur/arenapair-bin 2>/dev/null || echo "skip: aur/bin already renamed or missing"
  git mv packaging/aur/t3code-nightly-bin packaging/aur/arenapair-nightly-bin 2>/dev/null || echo "skip: aur/nightly already renamed or missing"
  echo "(After renaming paths, update any internal references and republish external artifacts.)"
else
  echo "(Path renames skipped. Pass --rename-paths to also git mv t3code/t3-code paths.)"
fi

echo "Done."
