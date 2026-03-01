# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Personal reference site for camera lens repair and service notes, built with [MkDocs](https://www.mkdocs.org/) and the [Material theme](https://squidfunk.github.io/mkdocs-material/). Intended to be deployed as a standalone site, linked from stevenkasapi.net.

## Commands

All commands should be run from the repo root. Activate the venv first:

```bash
source .venv/bin/activate
```

The venv was created with Python 3.12 (`python3.12 -m venv .venv`).

```bash
# Serve locally with auto-reload
mkdocs serve

# Production build (output goes to site/)
mkdocs build
```

## Architecture

```
mkdocs.yml        # Site config: theme, plugins, navigation
docs/             # All content lives here as Markdown files
  index.md        # Home page
  Manufacturer/   # One subfolder per manufacturer (e.g. Canon/, Nikon/)
    lens-name.md  # One file per lens
site/             # Generated output — not committed
```

## Adding Content

MkDocs builds navigation automatically from the folder structure. To add a lens:

1. Create `docs/{Manufacturer}/{lens-name}.md`
2. Run `mkdocs serve` — it will appear in the nav immediately

To control nav order or labels explicitly, add a `nav:` section to `mkdocs.yml`.

## Configuration Notes

- Theme is Material with `navigation.sections` and `navigation.top` enabled
- Search is enabled via the built-in `search` plugin
- `site_dir: site/` is gitignored — only source files are committed
- The site is meant to be portable; no hostname is hardcoded in `mkdocs.yml`
