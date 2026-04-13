# Tests y validación por fase (gates)

**Regla:** no avanzar de fase (MVP → v1.0 → v1.1) sin checklist en verde. Los checks manuales cuentan; automatizar (CI) es mejora posterior.

## Test brutal (MVP)

En terminal nueva:

1. `devql files` → aparece `fzf`, eliges un archivo → se abre el editor.
2. `devql text "algo"` → `fzf` → editor; con VS Code / vim compatible, **línea** correcta.

Si esto falla, el resto es distracción hasta arreglarlo.

## Smoke manual (v1.0)

Checklist corto para regresiones humanas:

1. `devql files` → elegir un archivo en `fzf` → se abre el editor (o cancelar con exit 0).
2. `devql text <patrón-con-coincidencias>` → elegir una línea → abre archivo (y línea si el editor lo permite).
3. `devql text __unlikely_pattern_xyz__` → mensaje “No matches.”, código de salida **0**, **no** abre editor.
4. `devql help` y `devql --version` → muestran ayuda y `devql v…` alineado a [lib/VERSION](lib/VERSION).

## Onboarding time (evidencia ≤ 10 min)

**Hacer una vez antes del tag v1.0.0:** desde clone (o equivalente) hasta primer `devql files` / `devql text` funcional, con **cronómetro**. Anotar:

- **Tiempo real:** ___ min ___ s  
- **Si &gt; 10 min, causa:** (ej. `winget` lento, PATH, permisos, paso de doc poco claro)

Esto convierte el criterio en evidencia, no en teoría.

## Tras MVP

| Área | Prueba | OK si |
|------|--------|--------|
| `devql files` | bash + PowerShell en repo de prueba | Archivo correcto; cancelar `fzf` no crashea |
| `devql text` | Mismo | Archivo + línea cuando el editor lo permite |
| Preflight | Quitar `rg` o `fd` del PATH | Mensaje claro en inglés + **una** línea `winget` (Windows) o pista `apt` (Debian/Ubuntu), exit ≠ 0 |
| Spike PS | `rg --json \| Parse-RgJson \| fzf` (sin editor) | Sin líneas rotas; rutas `C:\` OK |
| Unitario | `tests/run-parse-rgjson-tests.ps1` | Sale 0 |

## Tras v1.0

| Área | Prueba | OK si |
|------|--------|--------|
| Setup Core | VM o máquina limpia | `setup` exit 0; `Get-Command` / `command -v` para Core |
| PATH / shims | Nueva sesión; otro directorio | `devql`, `qfiles`, `qtxt` resuelven |
| `fdfind`→`fd` | Ubuntu solo `fdfind` | `devql files` funciona |
| Guía | Colega solo con `GUIA-CLI.md` | Puede configurar PATH manual |

## Tras v1.1 (cuando exista menú / `DEVQL_*`)

Menú Guided, `DEVQL_DEBUG` / `DEVQL_LOG`, opción 0 / `~/.devql_last` si aplica — ver plan de producto.

## Regresión

Al añadir features en v1.1+, repetir smoke MVP: `files` + `text` en bash y PowerShell.

## Automatizado (Windows / PowerShell)

Tras instalar Core y refrescar PATH:

```powershell
powershell -File tests/run-parse-rgjson-tests.ps1
powershell -File tests/smoke-headless.ps1
powershell -File tests/run-devql-e2e-simulated.ps1
```

- **Unitario:** fixtures de `Parse-RgJson`.
- **smoke-headless:** `fd | fzf --filter` y `rg --json | Parse-RgJson | fzf --filter` sin TUI (no abre editor; útil en CI). **No** sustituye el Test brutal interactivo de arriba.
- **run-devql-e2e-simulated:** ejecuta **`devql files`** y **`devql text`** de verdad con `FZF_DEFAULT_OPTS=--filter …` y un editor `cmd` noop (`tests/devql-noop-editor.cmd`), para CI o terminales sin TTY. Quita temporalmente del PATH las rutas de **VS Code / Cursor** para que se pruebe el fallback a `EDITOR` (si no, `code -g` tiene prioridad).
