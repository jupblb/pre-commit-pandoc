# pre-commit-pandoc

[![Test][]][1] [![pre-commit]][2]

A [pre-commit][3] hook for formatting Markdown files using [pandoc].

## Features

This hook formats Markdown files with pandoc using the following settings:

- 80 column width for better readability
- Reference-style links for cleaner markdown
- GitHub Flavored Markdown (GFM) input and output
- Standalone document mode

## Prerequisites

- [pre-commit][3] installed
- [pandoc][4] installed

## Installation

Add this to your `.pre-commit-config.yaml`:

``` yaml
repos:
  - repo: https://github.com/jupblb/pre-commit-pandoc
    rev: v1.0.0  # Use the latest version
    hooks:
      - id: pandoc
```

Then run:

``` bash
pre-commit install
```

## Usage

The hook will automatically format your Markdown files when you commit. You can
also run it manually:

``` bash
# Run on all files
pre-commit run pandoc --all-files

# Run on specific files
pre-commit run pandoc --files README.md CONTRIBUTING.md
```

## Configuration

The pandoc hook uses the following default settings:

- `--columns=80` - Wrap text at 80 columns
- `--reference-links` - Use reference-style links
- `-s` - Standalone document (always enabled)
- `-f gfm` - From GitHub Flavored Markdown
- `-t gfm` - To GitHub Flavored Markdown

You can customize these settings using args in your `.pre-commit-config.yaml`:

``` yaml
repos:
  - repo: https://github.com/jupblb/pre-commit-pandoc
    rev: v1.0.0
    hooks:
      - id: pandoc
        args:
          - --columns=100  # Set column width to 100
          - --no-reference-links  # Disable reference-style links
          - --from=markdown  # Change input format
          - --to=markdown  # Change output format
```

### Available Arguments

- `--columns <number>` - Set the column width (default: 80)
- `--no-reference-links` - Disable reference-style links (default: enabled)
- `--from <format>` - Set input format (default: gfm)
- `--to <format>` - Set output format (default: gfm)

Common format values include: `gfm` (GitHub Flavored Markdown), `markdown`,
`markdown_strict`, `commonmark`. See [pandoc documentation] for all supported
formats.

## How it Works

The hook runs pandoc on each Markdown file with the specified flags. If the file
content changes after formatting, the hook will:

1.  Update the file with the formatted content
2.  Exit with a non-zero status to prevent the commit
3.  Allow you to review and stage the changes

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

MIT License - see LICENSE file for details.

  [Test]: https://github.com/jupblb/pre-commit-pandoc/actions/workflows/test.yml/badge.svg
  [1]: https://github.com/jupblb/pre-commit-pandoc/actions/workflows/test.yml
  [pre-commit]: https://img.shields.io/badge/pre--commit-enabled-brightgreen?logo=pre-commit
  [2]: https://github.com/pre-commit/pre-commit
  [3]: https://pre-commit.com
  [pandoc]: https://pandoc.org/
  [4]: https://pandoc.org/installing.html
  [pandoc documentation]: https://pandoc.org/MANUAL.html#general-options
