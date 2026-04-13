# Changelog

## [1.0.0] — 2026-04-13

- v1.0 product close: English CLI messages, `lib/VERSION`, deterministic empty-result behaviour (exit 0, no editor).
- Preflight: Windows shows a single `winget` install line per missing Core tool; apt hints on Debian/Ubuntu when `apt-get` is present.
- Editor resolution: `code -g` when available; then `EDITOR`; then Notepad on Windows / `vi` on Unix.
- README: positioning, Why devql, real use case, quickstart, no side-effects statement.
- `.gitignore` expanded for tooling repos.

## [Unreleased]

- Post–v1.1 backlog only after real friction (menu, `DEVQL_*`, etc.).
