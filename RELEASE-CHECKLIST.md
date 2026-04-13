# Release checklist — v1.0.x

Antes de **`git tag v1.0.0`** (o siguiente parche):

## Automatizado (Windows)

- [ ] `powershell -File tests/run-parse-rgjson-tests.ps1` — OK
- [ ] `powershell -File tests/smoke-headless.ps1` — OK
- [ ] `powershell -File tests/run-devql-e2e-simulated.ps1` — OK

## Manual

- [ ] [TESTING.md](TESTING.md) — **Test brutal** + **Smoke manual** (secciones arriba)
- [ ] **Onboarding time:** rellenar evidencia ≤ 10 min en TESTING (una vez con cronómetro)
- [ ] `devql help` / `devql --version` — texto en inglés; versión = contenido de [lib/VERSION](lib/VERSION)

## Documentación

- [ ] [README.md](README.md) — hook, Why devql, Real use case, quickstart, sin side-effects
- [ ] [INSTALACION.md](INSTALACION.md) — alineado a `winget` / `apt` y a mensajes de preflight
- [ ] [GUIA-CLI.md](GUIA-CLI.md) — coherente con comportamiento y editor
- [ ] [CHANGELOG.md](CHANGELOG.md) — entrada de release

## Contrato código

- [ ] Cambio de comportamiento aplicado en **`bin/devql.ps1` y `lib/devql-common.sh`** (y [bin/devql](bin/devql) si aplica)
- [ ] [.gitignore](.gitignore) presente y razonable

## bash / WSL

- [ ] **Declaración:** si no se ha probado `bin/devql` en WSL en este tag, indicarlo en README o aquí: *bash/WSL no validado en v1.0.0* **o** marcar verificado tras prueba real.

## GitHub (publicación)

- [ ] Remoto `origin` → `https://github.com/BSTCMX/devql-fast--cli-tools.git` (o SSH equivalente)
- [ ] Push rama principal + **`git push origin v1.0.0`**
- [ ] En GitHub **About:** descripción y topics (`cli`, `developer-tools`, `fzf`, `ripgrep`, `search`, `productivity`, `terminal`, `code-search`)

## Congelado post v1.0

No implementar menú interactivo, `DEVQL_*`, `~/.devql_last`, Extended “completo” hasta haber usado el producto y tener fricción real.
