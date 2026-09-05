#!/usr/bin/env bash
# Test runner for the Jira syntax validator (validate-jira-syntax.sh).
#
# This is a battery of regression tests that verify the validator behaves
# correctly on real cases discovered in practice (Jira authoring work).
#
# Usage:
#   scripts/tests/run_tests.sh            # run all tests
#   scripts/tests/run_tests.sh --verbose  # show full output per test
#
# Exit codes: 0 = all passed, 1 = one or more failed.

set -uo pipefail

SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# We're in scripts/tests/, so the skill root is two levels up.
SKILL_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
VALIDATOR="$SKILL_ROOT/scripts/validate-jira-syntax.sh"
TMPDIR="$(mktemp -d)"
VERBOSE="${1:-}"
PASS=0
FAIL=0
FAILED_NAMES=()

# Colors
GREEN=$'\033[0;32m'
RED=$'\033[0;31m'
NC=$'\033[0m'

trap 'rm -rf "$TMPDIR"' EXIT

# Helper: write test input to a temp file and run the validator, capturing
# whether the expected condition (ERROR/WARNING/pass) is met.
# Usage: run_case <name> <expected> <file-content>
#   expected: "pass" | "error" | "warning" | "has:ERROR:<regex>"
run_case() {
  local name="$1"
  local expected="$2"
  local content="$3"
  local file="$TMPDIR/case_$$.txt"

  printf '%s' "$content" > "$file"

  local output
  output=$("$VALIDATOR" "$file" 2>&1)

  local ok=1
  case "$expected" in
    pass)
      if [[ "$output" == *"All checks passed"* ]]; then ok=0; fi
      ;;
    error)
      if [[ "$output" == *"ERROR:"* ]]; then ok=0; fi
      ;;
    warning)
      if [[ "$output" == *"WARNING:"* ]]; then ok=0; fi
      ;;
    has:ERROR:*)
      local re="${expected#has:ERROR:}"
      if [[ "$output" =~ $re ]]; then ok=0; fi
      ;;
    has:WARNING:*)
      local re="${expected#has:WARNING:}"
      if [[ "$output" =~ $re ]]; then ok=0; fi
      ;;
    *)
      ok=1;;
  esac

  if [[ "$ok" -eq 0 ]]; then
    PASS=$((PASS+1))
    if [[ "$VERBOSE" == "--verbose" ]]; then
      echo -e "${GREEN}✓ PASS${NC}: $name"
    fi
  else
    FAIL=$((FAIL+1))
    FAILED_NAMES+=("$name")
    echo -e "${RED}✗ FAIL${NC}: $name (expected: $expected)"
    if [[ "$VERBOSE" == "--verbose" ]]; then
      echo "$output" | sed 's/^/    /'
    fi
  fi
}

# ─────────────────────────────────────────────────────────────────────────────
# TEST CASES (regression battery derived from real Jira authoring work)
# ─────────────────────────────────────────────────────────────────────────────
echo "Jira syntax validator test battery"
echo "=================================="
echo ""

# T1: {code:bash} must NOT raise a warning (regression: old regex false-positive)
run_case "T1: {code:bash} valid, no false warning" "pass" 'h2. Test

This is a {code} block mention in text.

{code:bash}
alpha-user
bravo-user
{code}

Done.
'

# T2: Markdown **bold** must be an ERROR
run_case "T2: Markdown **bold** detected as ERROR" "error" 'h2. Test

As a result, the ticket is now being **closed**.
'

# T3: CLI-escaped chars (\*, \{{) must be an ERROR
run_case "T3: CLI-escaped chars detected as ERROR" "error" 'h2. Test

* item one
\* item two (escaped)
{{code}} block
\{{code\}} escaped
'

# T4: Valid plan-like content must pass clean
run_case "T4: valid Jira content passes clean" "pass" 'h2. Execution Plan

||Team||Slug||Status||
|Alpha Team|alpha|exists|
|Bravo Team|bravo|exists|

* Bullet one
* Bullet two

[PROJ-1234|https://YOUR-JIRA-INSTANCE/browse/PROJ-1234]

{panel}
A note here.
{panel}

{{owner_team}} custom property
'

# T5: Legitimate Jira line break (\\ at end) is NOT an error
run_case "T5: Jira line break \\ ok" "pass" 'h2. Test

Line one\\\nLine two
'

# T6: Markdown # headings -> WARNING (doc-only, not blocking)
run_case "T6: Markdown headings -> WARNING" "has:WARNING:.*Markdown-style headings" '# H1 header
## H2 header
Texto
'

# T7: Markdown link [text](url) must be an ERROR
run_case "T7: Markdown link [text](url) ERROR" "error" 'h2. Test

[Google|https://x.com]
[Google](https://x.com)
'

# T8: Markdown dashes (- item) -> WARNING
run_case "T8: Markdown dash bullet -> WARNING" "has:WARNING:.*Markdown-style bullets" 'h2. Test

- item uno
* item ok
'

# T9: Unclosed {code} block (odd markers) -> ERROR
run_case "T9: unclosed {code} block ERROR" "error" 'h2. Test

{code:bash}
a
{code}
{code}
'

# T10: Balanced {code} blocks (even markers) -> pass
run_case "T10: balanced {code} blocks pass" "pass" 'h2. Test

{code:bash}
a
{code}
{code:bash}
b
{code}
'

# T11: No {code} at all -> pass (no balance error)
run_case "T11: no {code} markers -> pass" "pass" 'h2. Test

Texto normal sin code blocks.
'

# T12: Table header || -> pass (no false positive)
run_case "T12: table header || pass" "pass" 'h2. Test

||A||B||
|1|2|
'

# T13: Empty / minimal content -> pass
run_case "T13: minimal content pass" "pass" 'h2. Test
'

# T14: Bare {code} (no language) is VALID Jira -> NOT an error
run_case "T14: bare {code} valid -> pass" "pass" 'h2. Test

{code}
plain
{code}
'

# T15: Panel {panel:...} / {panel} pairing — must NOT error on valid use
run_case "T15: valid panel passthrough" "pass" 'h2. Test

{panel:title=Note}
Content
{panel}
'

# T16: Inline code glued to a list item / word must be an ERROR
# (e.g. "* Fix{{.releaserc}}" instead of "* Fix {{.releaserc}}"). Real bug:
# a space was dropped between the list text and {{code}}, which Jira renders
# corruptly and the old validator missed entirely.
run_case "T16: inline code glued to list text -> ERROR" "error" 'h2. Test

* Fix{{.releaserc}}: set {{"branches": "main"}}
* Rename{{package.json}} {{name}} to team-admin
'

# T17: Inline code correctly separated by a space must pass clean
# (guards against a false positive on the corrected form). Real case: the
# same text after fixing the glued spacing must validate as valid.
run_case "T17: inline code with space after text -> pass" "pass" 'h2. Test

* Fix {{.releaserc}}: set {{"branches": "main"}}
* Rename {{package.json}} {{name}} to team-admin
'

# ─────────────────────────────────────────────────────────────────────────────
echo ""
echo "=========================================="
echo "Test results: $PASS passed, $FAIL failed (of $((PASS+FAIL)))"
echo "=========================================="

if [[ "$FAIL" -eq 0 ]]; then
  echo -e "${GREEN}✅ All validator tests passed!${NC}"
  exit 0
else
  echo -e "${RED}❌ Failed tests:${NC}"
  for n in "${FAILED_NAMES[@]}"; do echo "  - $n"; done
  exit 1
fi
