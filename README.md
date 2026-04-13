# devql

Blazing-fast code search and file navigation from your terminal.  
Powered by ripgrep, fd and fzf.

**devql** is a fast, interactive CLI for code search and file navigation powered by ripgrep, fd and fzf, with seamless editor integration.

## Why devql?

- **No need to wire ripgrep + fzf + your editor manually** — one command from search to the right file or line.
- **Consistent UX** across “find files” and “find text” flows.
- **Jump straight to files or lines** with a single entry point (`devql files` / `devql text`).

`devql` only **reads** the tree and **opens** your editor when you pick a result — it does not modify project files or system configuration (aside from whatever your editor does when opening a file).

## Real use case

Find where a React hook is used and open it in your editor:

```text
devql text useState
```

Pick a hit in `fzf`; your editor opens on that file (and line when the editor supports it, e.g. VS Code / Cursor via `code` on `PATH`).

## Quickstart (Windows PowerShell)

```powershell
git clone https://github.com/BSTCMX/devql-fast--cli-tools.git
cd devql-fast--cli-tools

winget install -e --id BurntSushi.ripgrep.MSVC
winget install -e --id sharkdp.fd
winget install -e --id junegunn.fzf
winget install -e --id sharkdp.bat

powershell -ExecutionPolicy Bypass -File .\setup.ps1
# New terminal, then:
devql files
devql text "test"
```

Full package list and WSL/Linux: [INSTALACION.md](INSTALACION.md). Usage and editor behaviour: [GUIA-CLI.md](GUIA-CLI.md).

## Requirements (Core)

- `rg`, `fd`, `fzf`, `bat` (preview; `type`/`cat` fallback if missing)
- **Windows:** PowerShell 5.1+ for `bin/devql.ps1`
- **WSL/Linux:** bash for `bin/devql`
- **Editor:** `code` on `PATH` recommended for line jumps in `devql text`; otherwise `EDITOR`, else Notepad on Windows / `vi` on Unix (see GUIA)

## Usage

```text
devql files
devql text "pattern"
devql help
devql --version
qfiles
qtxt "pattern"
```

On Windows, `text` uses **`rg --json`** → **`Parse-RgJson`** → **`fzf`** so paths like `C:\...` stay unambiguous.

## Tests

```powershell
powershell -File tests/run-parse-rgjson-tests.ps1
powershell -File tests/smoke-headless.ps1
powershell -File tests/run-devql-e2e-simulated.ps1
```

See [TESTING.md](TESTING.md).

## Repo layout

```text
bin/devql          # bash
bin/devql.ps1      # PowerShell
lib/VERSION        # single source of truth for devql --version
lib/devql-common.sh
lib/Parse-RgJson.ps1
path-shims/
setup.ps1 / setup.sh
```

## Versioning

Semantic tags (see [CHANGELOG.md](CHANGELOG.md)). Version string for `devql help` / `devql --version` comes from [lib/VERSION](lib/VERSION).

---

**v1.0 scope:** Windows path validated first; bash/WSL may be marked “best effort” until explicitly tested — see [RELEASE-CHECKLIST.md](RELEASE-CHECKLIST.md).
