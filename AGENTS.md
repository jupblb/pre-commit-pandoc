# AGENTS.md - AI Agent Instructions

This file contains information to help AI agents understand and work with this
codebase effectively.

## Project Overview

This is a pre-commit hook that wraps pandoc for formatting Markdown files. It's
designed to be used by others as an open-source tool via pre-commit framework.

## Frequently Used Commands

### Testing

``` bash
# Run the full test suite
./tests/test_pandoc_format.sh

# Test the pandoc-format script on a specific file
./pandoc-format README.md

# Test with different options
./pandoc-format --columns 60 --no-reference-links test.md
```

### Linting

``` bash
# Run shellcheck on all shell scripts
shellcheck pandoc-format tests/test_pandoc_format.sh
```

### Git Operations

``` bash
# View commit history
git log --oneline

# Run pre-commit hooks (excluding test fixtures)
pre-commit run --all-files
```

## Project Structure

    .
    ├── .github/
    │   └── workflows/
    │       └── test.yml          # CI workflow for GitHub Actions
    ├── tests/
    │   ├── fixtures/             # Test markdown files (must remain unformatted)
    │   │   ├── already-formatted.md
    │   │   ├── complex.md
    │   │   └── simple.md
    │   └── test_pandoc_format.sh # Test suite script
    ├── .pre-commit-config.yaml   # Example configuration for testing
    ├── .pre-commit-hooks.yaml    # Hook definition for pre-commit
    ├── pandoc-format             # Main wrapper script (executable)
    ├── README.md                 # Documentation (must be pandoc-formatted)
    └── LICENSE                   # MIT License

## Code Style & Conventions

### Shell Scripts

- Use `#!/usr/bin/env bash` shebang
- Set `set -euo pipefail` for error handling
- Use shellcheck and fix all warnings
- Prefer `[[ ]]` over `[ ]` for conditionals
- Quote variables to prevent word splitting
- Use meaningful variable names in UPPER_CASE for globals
- Declare and assign variables separately when capturing command output

### Markdown Files

- README.md and documentation should be formatted with pandoc
- Test fixtures in `tests/fixtures/` must NOT be formatted (they're test input)
- Use reference-style links by default
- 80-column width by default

### Git Commits

- Use conventional commit style when appropriate
- Keep commits focused on a single change
- Include tests with feature additions

## Important Notes

### Test Fixtures

**CRITICAL**: Files in `tests/fixtures/` must remain unformatted. These are
input files for the test suite. The tests expect to format these files and
detect changes. If they're already formatted, tests will fail.

### CI Configuration

The GitHub Actions workflow excludes test fixtures from pre-commit formatting by
creating a custom configuration. This ensures the idempotency test works
correctly.

### Pandoc Behavior

- Pandoc adds spaces after triple backticks in code blocks: ````  ```python ````
  becomes ````  ``` python ````
- Pandoc uses two spaces after list numbers: `1. Item` becomes `1.  Item`
- Pandoc may add blank lines between list items for better readability
- Reference links are placed at the end of the document

### Pre-commit Hook Usage

Users will include this hook in their `.pre-commit-config.yaml` like:

``` yaml
repos:
  - repo: https://github.com/jupblb/pre-commit-pandoc
    rev: <version>
    hooks:
      - id: pandoc
        args: [--columns=80]  # optional customization
```

## Development Workflow

1.  Make changes to the code
2.  Run shellcheck to ensure no linting issues
3.  Run the test suite to ensure all tests pass
4.  Format README.md with pandoc if modified
5.  Commit changes with descriptive messages

## Debugging Tips

- Use `bash -x ./pandoc-format <file>` to see execution trace
- Check exit codes: 0 = no changes, 1 = formatted
- Test fixtures can be temporarily formatted to see expected output
- The CI workflow can be tested locally with act or similar tools
