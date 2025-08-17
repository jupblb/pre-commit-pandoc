#!/usr/bin/env bash
#
# Test suite for pandoc-format script

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Get script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
PANDOC_FORMAT="$PROJECT_ROOT/pandoc-format"

# Temporary directory for test files
TEST_TEMP_DIR=$(mktemp -d)
trap "rm -rf $TEST_TEMP_DIR" EXIT

# Helper functions
print_test_header() {
    echo -e "${YELLOW}Running test: $1${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_failure() {
    echo -e "${RED}✗ $1${NC}"
}

assert_exit_code() {
    local expected=$1
    local actual=$2
    local test_name=$3
    
    TESTS_RUN=$((TESTS_RUN + 1))
    
    if [ "$expected" -eq "$actual" ]; then
        print_success "$test_name: exit code $actual"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        return 0
    else
        print_failure "$test_name: expected exit code $expected, got $actual"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        return 1
    fi
}

assert_file_changed() {
    local file1=$1
    local file2=$2
    local test_name=$3
    
    TESTS_RUN=$((TESTS_RUN + 1))
    
    if ! cmp -s "$file1" "$file2"; then
        print_success "$test_name: file was changed as expected"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        return 0
    else
        print_failure "$test_name: file was not changed"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        return 1
    fi
}

assert_file_unchanged() {
    local file1=$1
    local file2=$2
    local test_name=$3
    
    TESTS_RUN=$((TESTS_RUN + 1))
    
    if cmp -s "$file1" "$file2"; then
        print_success "$test_name: file unchanged as expected"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        return 0
    else
        print_failure "$test_name: file was unexpectedly changed"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        return 1
    fi
}

assert_contains() {
    local file=$1
    local pattern=$2
    local test_name=$3
    
    TESTS_RUN=$((TESTS_RUN + 1))
    
    if grep -q -- "$pattern" "$file"; then
        print_success "$test_name: contains '$pattern'"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        return 0
    else
        print_failure "$test_name: does not contain '$pattern'"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        return 1
    fi
}

assert_not_contains() {
    local file=$1
    local pattern=$2
    local test_name=$3
    
    TESTS_RUN=$((TESTS_RUN + 1))
    
    if ! grep -q -- "$pattern" "$file"; then
        print_success "$test_name: does not contain '$pattern'"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        return 0
    else
        print_failure "$test_name: unexpectedly contains '$pattern'"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        return 1
    fi
}

# Check if pandoc is installed
check_pandoc() {
    if ! command -v pandoc &> /dev/null; then
        echo -e "${RED}Error: pandoc is not installed${NC}"
        echo "Please install pandoc to run tests"
        exit 1
    fi
}

# Test 1: Basic formatting with defaults
test_basic_formatting() {
    print_test_header "Basic formatting with defaults"
    
    cp "$SCRIPT_DIR/fixtures/simple.md" "$TEST_TEMP_DIR/test1.md"
    local original="$TEST_TEMP_DIR/test1.md"
    
    # Run pandoc-format
    set +e
    "$PANDOC_FORMAT" "$TEST_TEMP_DIR/test1.md" > /dev/null 2>&1
    local exit_code=$?
    set -e
    
    # Should exit with code 1 when file is modified
    assert_exit_code 1 $exit_code "Default formatting"
    
    # Should have reference-style links
    assert_contains "$TEST_TEMP_DIR/test1.md" "\[inline link\]:" "Reference links"
    
    # Check line wrapping (approximate check for 80 columns)
    local long_lines=$(awk 'length > 85' "$TEST_TEMP_DIR/test1.md" | wc -l)
    TESTS_RUN=$((TESTS_RUN + 1))
    if [ "$long_lines" -eq 0 ]; then
        print_success "Lines wrapped at ~80 columns"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        print_failure "Found lines longer than 85 characters"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
}

# Test 2: Custom column width
test_custom_columns() {
    print_test_header "Custom column width"
    
    cp "$SCRIPT_DIR/fixtures/simple.md" "$TEST_TEMP_DIR/test2.md"
    
    # Run with custom column width
    set +e
    "$PANDOC_FORMAT" --columns 60 "$TEST_TEMP_DIR/test2.md" > /dev/null 2>&1
    local exit_code=$?
    set -e
    
    assert_exit_code 1 $exit_code "Custom columns formatting"
    
    # Check line wrapping (approximate check for 60 columns)
    local long_lines=$(awk 'length > 65' "$TEST_TEMP_DIR/test2.md" | wc -l)
    TESTS_RUN=$((TESTS_RUN + 1))
    if [ "$long_lines" -eq 0 ]; then
        print_success "Lines wrapped at ~60 columns"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        print_failure "Found lines longer than 65 characters"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
}

# Test 3: No reference links
test_no_reference_links() {
    print_test_header "No reference links option"
    
    cp "$SCRIPT_DIR/fixtures/simple.md" "$TEST_TEMP_DIR/test3.md"
    
    # Run without reference links
    set +e
    "$PANDOC_FORMAT" --no-reference-links "$TEST_TEMP_DIR/test3.md" > /dev/null 2>&1
    local exit_code=$?
    set -e
    
    assert_exit_code 1 $exit_code "No reference links formatting"
    
    # Should still have inline links
    assert_contains "$TEST_TEMP_DIR/test3.md" "\[inline link\](https://example.com)" "Inline links preserved"
    
    # Should not have reference-style links
    assert_not_contains "$TEST_TEMP_DIR/test3.md" "\[inline link\]:" "No reference links"
}

# Test 4: Already formatted file
test_already_formatted() {
    print_test_header "Already formatted file"
    
    cp "$SCRIPT_DIR/fixtures/already-formatted.md" "$TEST_TEMP_DIR/test4.md"
    cp "$TEST_TEMP_DIR/test4.md" "$TEST_TEMP_DIR/test4_backup.md"
    
    # Run pandoc-format
    set +e
    "$PANDOC_FORMAT" "$TEST_TEMP_DIR/test4.md" > /dev/null 2>&1
    local exit_code=$?
    set -e
    
    # Should exit with code 0 when no changes needed
    assert_exit_code 0 $exit_code "Already formatted file"
    
    # File should be unchanged
    assert_file_unchanged "$TEST_TEMP_DIR/test4.md" "$TEST_TEMP_DIR/test4_backup.md" "File unchanged"
}

# Test 5: Multiple files
test_multiple_files() {
    print_test_header "Multiple files"
    
    cp "$SCRIPT_DIR/fixtures/simple.md" "$TEST_TEMP_DIR/test5a.md"
    cp "$SCRIPT_DIR/fixtures/complex.md" "$TEST_TEMP_DIR/test5b.md"
    
    # Run on multiple files
    set +e
    "$PANDOC_FORMAT" "$TEST_TEMP_DIR/test5a.md" "$TEST_TEMP_DIR/test5b.md" > /dev/null 2>&1
    local exit_code=$?
    set -e
    
    # Should exit with code 1 if any file was modified
    assert_exit_code 1 $exit_code "Multiple files formatting"
    
    # Both files should have reference links
    assert_contains "$TEST_TEMP_DIR/test5a.md" "\[inline link\]:" "First file has reference links"
    assert_contains "$TEST_TEMP_DIR/test5b.md" "\[a link to GitHub\]:" "Second file has reference links"
}

# Test 6: Custom format options
test_custom_formats() {
    print_test_header "Custom input/output formats"
    
    cp "$SCRIPT_DIR/fixtures/simple.md" "$TEST_TEMP_DIR/test6.md"
    
    # Run with custom formats
    set +e
    "$PANDOC_FORMAT" --from markdown --to markdown "$TEST_TEMP_DIR/test6.md" > /dev/null 2>&1
    local exit_code=$?
    set -e
    
    # Should still work with different format specifications
    assert_exit_code 1 $exit_code "Custom format options"
}

# Test 7: Error handling - no files provided
test_no_files_error() {
    print_test_header "Error handling - no files"
    
    set +e
    output=$("$PANDOC_FORMAT" 2>&1)
    local exit_code=$?
    set -e
    
    assert_exit_code 1 $exit_code "No files error"
    
    TESTS_RUN=$((TESTS_RUN + 1))
    if [[ "$output" == *"No files provided"* ]]; then
        print_success "Correct error message for no files"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        print_failure "Wrong error message for no files"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
}

# Test 8: Error handling - missing argument value
test_missing_argument_value() {
    print_test_header "Error handling - missing argument value"
    
    set +e
    output=$("$PANDOC_FORMAT" --columns 2>&1)
    local exit_code=$?
    set -e
    
    assert_exit_code 1 $exit_code "Missing argument value error"
    
    TESTS_RUN=$((TESTS_RUN + 1))
    if [[ "$output" == *"requires an argument"* ]]; then
        print_success "Correct error message for missing argument"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        print_failure "Wrong error message for missing argument"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
}

# Test 9: Complex document formatting
test_complex_document() {
    print_test_header "Complex document formatting"
    
    cp "$SCRIPT_DIR/fixtures/complex.md" "$TEST_TEMP_DIR/test9.md"
    
    # Run pandoc-format
    set +e
    "$PANDOC_FORMAT" "$TEST_TEMP_DIR/test9.md" > /dev/null 2>&1
    local exit_code=$?
    set -e
    
    assert_exit_code 1 $exit_code "Complex document formatting"
    
    # Check that various elements are preserved
    assert_contains "$TEST_TEMP_DIR/test9.md" '``` python' "Code blocks preserved"
    assert_contains "$TEST_TEMP_DIR/test9.md" '| Column 1' "Tables preserved"
    assert_contains "$TEST_TEMP_DIR/test9.md" '> This is a blockquote' "Blockquotes preserved"
    assert_contains "$TEST_TEMP_DIR/test9.md" '1.  First ordered item' "Ordered lists preserved"
    assert_contains "$TEST_TEMP_DIR/test9.md" '\*\*bold text\*\*' "Bold text preserved"
    assert_contains "$TEST_TEMP_DIR/test9.md" '---' "Horizontal rule preserved"
}

# Main test runner
main() {
    echo "========================================="
    echo "Running pandoc-format test suite"
    echo "========================================="
    echo
    
    # Check prerequisites
    check_pandoc
    
    # Run all tests
    test_basic_formatting
    echo
    test_custom_columns
    echo
    test_no_reference_links
    echo
    test_already_formatted
    echo
    test_multiple_files
    echo
    test_custom_formats
    echo
    test_no_files_error
    echo
    test_missing_argument_value
    echo
    test_complex_document
    echo
    
    # Print summary
    echo "========================================="
    echo "Test Summary"
    echo "========================================="
    echo -e "Tests run: $TESTS_RUN"
    echo -e "${GREEN}Tests passed: $TESTS_PASSED${NC}"
    echo -e "${RED}Tests failed: $TESTS_FAILED${NC}"
    echo
    
    if [ $TESTS_FAILED -eq 0 ]; then
        echo -e "${GREEN}All tests passed!${NC}"
        exit 0
    else
        echo -e "${RED}Some tests failed!${NC}"
        exit 1
    fi
}

# Run tests
main "$@"
