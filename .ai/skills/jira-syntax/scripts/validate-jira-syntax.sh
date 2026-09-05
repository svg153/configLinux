#!/bin/bash

# Jira Wiki Markup Syntax Validator
# Checks text for common Jira syntax errors and suggests corrections

set -e

# Colors for output
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# Counters
ERRORS=0
WARNINGS=0

# Function to print error
error() {
    echo -e "${RED}❌ ERROR:${NC} $1"
    ((ERRORS++))
}

# Function to print warning
warning() {
    echo -e "${YELLOW}⚠️  WARNING:${NC} $1"
    ((WARNINGS++))
}

# Function to print success
success() {
    echo -e "${GREEN}✅ $1${NC}"
}

# Function to check file
validate_file() {
    local file="$1"
    echo ""
    echo "=========================================="
    echo "Validating: $file"
    echo "=========================================="

    if [ ! -f "$file" ]; then
        error "File not found: $file"
        return
    fi

    local content=$(cat "$file")
    local line_num=0

    # Check for Markdown-style bold (**text** instead of *text*)
    if echo "$content" | grep -qE "\*\*[^*]+\*\*" || echo "$content" | grep -qE "\*\*[^*]+$"; then
        error "Found Markdown-style bold (**text**). Use Jira format: *text*"
        echo "   Examples found:"
        echo "$content" | grep -oE "\*\*[^*]+\*\*" | head -3
    fi

    # Check for Markdown-style italic (_text_ is ok, but *text* for bold might be confused)
    if echo "$content" | grep -qE "\*[^*]+\*\*[^*]+\*"; then
        warning "Found potential Markdown-style italic mixed with bold"
    fi

    # Check for Markdown-style code blocks (``` instead of {code}).
    # NOTE: WARNING, not ERROR — example docs/templates may legitimately show
    # Markdown fences. In generated Jira bodies we must use {code:lang}.
    if echo "$content" | grep -qE "^\`\`\`"; then
        warning "Found Markdown code blocks (\`\`\`). In generated Jira body use: {code:language}"
        echo "   Lines with issue:"
        echo "$content" | grep -nE "^\`\`\`" | head -5
    fi

    # Check for Markdown-style inline code (` instead of {{)
    # Only warn if NO Jira {{code}} is present AND backticks exist — avoids
    # false positives when {{code}} is legitimately used alongside.
    if echo "$content" | grep -qE "\`[^\`]+\`"; then
        if ! echo "$content" | grep -qE "\{\{[^}]+\}\}"; then
            warning "Found Markdown inline code (\`code\`). Consider Jira format: {{code}}"
        fi
    fi

    # Check for Markdown-style links ([text](url) instead of [text|url]).
    # NOTE: inside an ERE character class, "]" must NOT be escaped — use [^]]
    # (NOT [^\]] which GNU grep rejects). This pattern catches [text](url).
    if echo "$content" | grep -qE '\[[^]]+\]\([^)]+\)'; then
        error "Found Markdown-style links ([text](url)). Use Jira format: [text|url]"
        echo "   Examples found:"
        echo "$content" | grep -oE '\[[^]]+\]\([^)]+\)' | head -3
    fi

    # Check for headings without space after period (h2.Title instead of h2. Title)
    if echo "$content" | grep -qE "^h[1-6]\.[^ ]"; then
        error "Found headings without space after period. Use: h2. Title (not h2.Title)"
        echo "   Lines with issue:"
        echo "$content" | grep -nE "^h[1-6]\.[^ ]" | head -5
    fi

    # NOTE: We intentionally do NOT warn on bare {code} (no language).
    # In Jira, {code} without a language is still a VALID code block (it just
    # doesn't apply syntax highlighting). The old regex "{code}[^{]" wrongly
    # matched {code:bash} and narrative "a {code} block", producing constant
    # false positives. Block balance is validated separately below.

    # Check for tables with incorrect header syntax (|Header| instead of ||Header||)
    # Only flag single-pipe header rows, NOT regular data rows.
    if echo "$content" | grep -qE "^\|[^|]+\|$" ; then
        # Only warn if it looks like a header (common header terms) OR no || header row exists
        header_terms=$(echo "$content" | grep -E "^\|[^|]+\|$")
        if [ -n "$header_terms" ]; then
            warning "Potential single-pipe row (used as header?). Headers should use: ||Header||"
        fi
    fi

    # Check for unclosed {code} blocks.
    # IMPORTANT: In Jira BOTH the opening ({code:lang}) and the CLOSING ({code})
    # use the same "{code}" token — there is NO "{/code}". So we only count
    # block markers that are a LINE BY THEMSELVES (avoids counting narrative
    # mentions like "a {code} block"). An ODD count means a block is left open.
    local code_markers=$(echo "$content" | grep -cE "^\s*\{code(:[a-zA-Z0-9]+)?\}\s*$")
    if [ $((code_markers % 2)) -ne 0 ]; then
        error "Possible unclosed {code} block: an odd number of {code}/{code:lang} markers ($code_markers)"
        echo "   Block markers found:"
        echo "$content" | grep -nE "^\s*\{code(:[a-zA-Z0-9]+)?\}\s*$" | head -5
    fi

    # NOTE: {panel} block balance is intentionally NOT validated. In Jira,
    # {panel:title=X} opens and {panel} closes, but a bare {panel} can ALSO be a
    # valid opening. Since the textual token is identical for open and close,
    # counting them produces constant false positives. Leave {panel} checking to
    # visual/manual review.

    # Check for unclosed {color} blocks
    local color_open=$(echo "$content" | grep -oE "\{color:[a-zA-Z#0-9]+\}" | wc -l)
    local color_close=$(echo "$content" | grep -c "{/color}")
    if [ "$color_open" -gt "$color_close" ]; then
        warning "Missing {/color} closing tags: $color_open opening, $color_close closing"
    fi

    # Check for Markdown-style headings without valid Jira heading (## used).
    # NOTE: WARNING, not ERROR — template/skill docs legitimately use Markdown
    # headings for their own structure. Only the BODY we generate must use h2.
    if echo "$content" | grep -qE "^#{1,6} "; then
        warning "Found Markdown-style headings (#). In generated Jira body use: h2. Heading"
        echo "   Lines with issue:"
        echo "$content" | grep -nE "^#{1,6} " | head -5
    fi

    # Check for Markdown-style fenced code blocks (```)
    if echo "$content" | grep -qE "^\`\`\`"; then
        error "Found Markdown-style fences (\`\`\`). Use Jira format: {code}...{code}"
        echo "   Lines with issue:"
        echo "$content" | grep -nE "^\`\`\`" | head -5
    fi

    # NOTE: the Markdown-style link check above already covers [text](url).
    # The old duplicated rule (with the broken [^\]] ERE class) is removed.

    # NOTE: Column-count consistency is intentionally NOT checked. Jira headers
    # use double pipes (||A||B||) while data rows use single pipes (|A|B|), so a
    # naive pipe-count heuristic produces constant false positives. Table
    # structure is validated by the double-pipe header check above.

    # Check for Markdown-style lists (- item instead of * item)
    if echo "$content" | grep -qE "^- [^-]" ; then
        warning "Found Markdown-style bullets (- item). Jira prefers: * item"
        echo "   Lines with issue:"
        echo "$content" | grep -nE "^- [^-]" | head -5
    fi

    # Check for bullet list item glued to inline code WITHOUT a space
    # (e.g. "* Fix{{.releaserc}}" instead of "* Fix {{.releaserc}}").
    # In Jira, a * bullet must be followed by a space, and inline {{code}}
    # must NOT be glued directly to the preceding word or the list marker.
    # Found in practice: sed stripping a space turned "* Fix {{...}}" into
    # "* Fix{{...}}", which the CLI/renders corruptly and the old validator
    # missed entirely.
    if echo "$content" | grep -qE '^\s*[*-] [A-Za-z][A-Za-z]*\{\{'; then
        error "Found Jira list item with inline code glued to text (* Word{{code}}). Add a space: * Word {{code}}"
        echo "   Lines with issue:"
        echo "$content" | grep -nE '^\s*[*-] [A-Za-z][A-Za-z]*\{\{' | head -5
    fi

    # Check for any inline code {{...}} glued to a preceding word or paren with
    # no space (e.g. "Rename{{package.json}}", "the tag{{x}}"), which Jira does
    # not render as intended. This is separate from bullets and catches the
    # same root cause (a space was dropped between text and {{code}}).
    if echo "$content" | grep -qE '[A-Za-z0-9_)]\{\{'; then
        warning "Found inline code {{...}} glued to text without a space. Add a space: text {{code}}"
        echo "   Examples found:"
        echo "$content" | grep -oE '[A-Za-z0-9_)]\{\{[^}]+\}\}' | head -5
    fi

    # Check for CLI-escaped Jira characters (the silent killer).
    # When the jira CLI escapes the body (--template/-b/stdin), the markup gets
    # backslash-escaped: \* (bullet), \_ , \[ , \{{ , \} , \( , \~ , \| . These
    # corrupt rendering and must be caught BEFORE submitting.
    # We match a literal backslash followed by any Jira-significant char EXCEPT
    # a second backslash (\\ is the legitimate Jira line-break marker) or a
    # slash used in {code}/{panel} URLs that we do not want to scare the user.
    # PCRE is used because ERE (grep -E) cannot express { } inside a character
    # class without a syntax error ("Invalid content of \{\}").
    # Jira-significant chars that get escaped by the CLI: * _ - [ ] { } ( ) ~ |
    if grep -Pq '\\[*_\-\[\]()~|{}]' <<< "$content"; then
        error "Found backslash-escaped Jira chars (CLI escaping trap). Remove the backslashes: \\* -> *, \\{{ -> {{, \\[ -> ["
        echo "   Examples found:"
        grep -Po '\\[*_\-\[\]()~|{}]' <<< "$content" | sort -u | head -10
    fi

    # Check for malformed code block language (e.g. {code::lang} double-colon).
    if echo "$content" | grep -qE "^\s*\{code::[a-zA-Z0-9]+\}\s*$"; then
        error "Found malformed code block language: {code::lang} -> use {code:lang}"
    fi

    # Positive checks
    if echo "$content" | grep -qE "^h[1-6]\. "; then
        success "Found correctly formatted Jira headings"
    fi

    if echo "$content" | grep -qE "{code:[a-z]+}"; then
        success "Found code blocks with language specification"
    fi

    if echo "$content" | grep -qE "\[~[a-z.]+\]"; then
        success "Found user mentions ([~username])"
    fi

    if echo "$content" | grep -qE "\[[A-Z]+-[0-9]+\]"; then
        success "Found issue links ([PROJ-123])"
    fi
}

# Main script
echo "Jira Wiki Markup Syntax Validator"
echo "=================================="

if [ $# -eq 0 ]; then
    echo "Usage: $0 <file1> [file2] [file3] ..."
    echo ""
    echo "Validates Jira wiki markup syntax in text files"
    echo ""
    echo "Example:"
    echo "  $0 issue-description.txt"
    echo "  $0 templates/*.md"
    exit 1
fi

# Validate each file
for file in "$@"; do
    validate_file "$file"
done

# Summary
echo ""
echo "=========================================="
echo "Validation Summary"
echo "=========================================="
echo "Files checked: $#"
echo -e "${RED}Errors: $ERRORS${NC}"
echo -e "${YELLOW}Warnings: $WARNINGS${NC}"

if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    echo -e "${GREEN}✅ All checks passed!${NC}"
    exit 0
elif [ $ERRORS -eq 0 ]; then
    echo -e "${YELLOW}⚠️  No errors, but $WARNINGS warnings found${NC}"
    exit 0
else
    echo -e "${RED}❌ $ERRORS errors found - please fix before submitting to Jira${NC}"
    exit 1
fi
