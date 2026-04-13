# Guía CLI — devql (rg, fd, fzf, zoxide)

Guía para **principiantes** y equipos. Objetivo: **buscar en el repo, filtrar con fzf y abrir en el editor** sin memorizar tuberías largas.

**Producto (v1.0):** posicionamiento y “Why devql?” viven en [README.md](README.md). **`devql` no modifica archivos del repo** ni configuración del sistema: solo lectura (`fd`/`rg`), selección (`fzf`) y apertura en el editor.

**Idioma en consola:** mensajes del CLI en **inglés**; documentación del kit puede estar en español en este repositorio.

## Regla mental de equipos

**Empieza amplio (fd o rg), reduce con fzf, termina en el editor.** Así evitas bloquearte: primero candidatos, luego selección, luego acción.

## Contenido vs estructura

| Mental model | Herramienta |
|--------------|-------------|
| Texto dentro de archivos | **rg** (ripgrep) |
| Nombres, rutas, árbol | **fd** |

No uses `rg` para “buscar un archivo por nombre” si `fd` es más natural, ni `fd` para buscar texto en contenido.

## Fases del producto (MVP → v1.0 → v1.1)

- **MVP:** solo `devql files`, `devql text`, `devql help` (sin menú interactivo). *El plan define el destino; el MVP define el primer paso.*
- **v1.0:** setup Core, PATH, shims `qfiles` / `qtxt`, guía mínima, preview con **bat**.
- **v1.1+:** menú Guided opcional, `DEVQL_DEBUG` / `DEVQL_LOG`, Extended best-effort.

Para quien **implementa:** no adelantar fases en el mismo bloque de código; ver [TESTING.md](TESTING.md).

## Métricas (benchmark)

Objetivo orientativo: **&lt; 3 s** desde que usas `fzf` hasta que el editor abre, en **máquina y repo de referencia**. **No** es un fallo automático del proyecto: en `/mnt/c` en WSL, monorepos enormes o antivirus, la latencia puede ser mayor — no confundas I/O lento con un bug de `devql`.

## Tiers (Core / Extended / Advanced)

| Tier | Rol |
|------|-----|
| **Core** | `rg`, `fd`, `fzf`, `zoxide`, `bat` — flujo devql |
| **Extended** | `delta`, `jq`, `eza`, `PSFzf` (Windows), etc. |
| **Advanced** | `rga`, `ast-grep` — no bloquean Core |

`setup.ps1` / `setup.sh` instalan **Core** por defecto; Extended suele ser opt-in o best-effort.

## Instalación

Resumen: [INSTALACION.md](INSTALACION.md). Tras instalar herramientas, ejecuta **`setup.ps1`** (Windows) o **`setup.sh`** (WSL/Linux) desde la raíz del repo.

### PATH manual (si el setup no pudo tocar PATH)

- **Windows:** comprueba que `%USERPROFILE%\bin` exista y esté en el PATH del **usuario**; abre una **nueva** terminal tras cambiarlo (`setx` no actualiza la sesión actual).
- **WSL:** `export PATH="$HOME/bin:$PATH"` en `~/.bashrc` si los shims están en `~/bin`.

### Validación PATH

Si `devql` no se encuentra, el kit “no existe” para el usuario: corrige PATH antes de depurar scripts.

## Variables de editor

- **Linux / WSL:** `EDITOR` / `VISUAL`. Fallback típico `vi`.
- **Windows:** define `EDITOR` o usa **`code`** en PATH. Para **línea** en `devql text`, lo más fiable es **`code -g "ruta:linea"`** (el script intenta `code -g` si `code` existe).

### VS Code en Windows (lectura obligatoria)

- **`code --wait`** no espera “cerrar la pestaña”; suele asociarse a **ventana** / proceso. Para ir a una línea concreta, usa **`code -g "archivo:linea"`**, no confíes solo en `--wait`.
- **Notepad:** abre archivo **sin** línea — UX degradada aceptada.

### bash: patrón seguro con editor con argumentos

Evita `xargs $EDITOR` si `EDITOR` es `code --wait`. Patrón recomendado:

```bash
fd --type f | fzf | xargs -r -I{} sh -c '"${EDITOR:-vi}" "$1"' _ {}
```

`devql` ya encapsula esto.

## Integración shell

- **zoxide:** `eval "$(zoxide init bash)"` (o `zsh` / `powershell` según doc actual).
- **fzf:** carga keybindings del paquete en bash/zsh.
- **Extended (Windows):** `PSFzf` + perfil PowerShell — **no** asumas que Ctrl+T queda igual que en Linux sin configurar el perfil.

### Extended: `FZF_DEFAULT_COMMAND` (WSL / bash)

Cuando **fd** está en PATH (o `fdfind` con alias `fd`):

```bash
export FZF_DEFAULT_COMMAND='fd --type f --hidden --exclude .git'
```

Efecto: el widget de archivos de fzf (p. ej. Ctrl+T) usa ese comando por defecto. En Ubuntu, si solo existe `fdfind`, usa `fdfind` en la variable o crea el enlace `fd` (el `setup.sh` ayuda con `~/.local/bin/fd`).

### Dónde vive el repo (coherencia con búsquedas)

Ejecuta `fd` / `rg` / `devql` **desde el directorio del proyecto** (o ámbito que elijas). `rg` respeta `.gitignore` por defecto; en WSL, para rendimiento, conviene clonar en `~/…` (ext4) frente a trabajar solo sobre `/mnt/c/…` cuando el cuello de botella sea I/O.

## Modos Guided vs Direct (v1.1+)

| Modo | Invocación | Notas |
|------|------------|--------|
| **Guided** | `devql` sin args (cuando exista menú) | Onboarding |
| **Direct** | `devql files`, `devql text`, `qfiles`, `qtxt` | Núcleo del valor |

En el **MVP actual**, `devql` sin argumentos muestra **ayuda** (no menú).

## Contrato `devql` (MVP)

```text
devql files           # fd -> fzf -> editor
devql text [PATRON] # rg -> fzf -> editor (linea si el editor lo permite)
devql help
devql --version
qfiles                # atajo
qtxt                  # atajo
```

- **`devql text`** sin patrón: pide el patrón de forma interactiva (no lanza `rg` vacío).

### Ejemplo “caso real” (ahorro de tiempo)

En un proyecto front, localizar usos de un hook y abrir el resultado en el editor:

```text
devql text useState
```

## Pipeline `text`

### bash / WSL (rutas POSIX)

- `rg` con líneas tipo `ruta:linea:texto` y `fzf` con `--delimiter ':'` (válido cuando la ruta no lleva `:` como en `C:\`).

### Windows (PowerShell)

- **Opción A (oficial):** `rg --json` → **`Parse-RgJson`** → líneas `archivo<TAB>linea<TAB>texto` → `fzf`. Así se evita el conflicto del **`:`** en rutas `C:\...` con `--delimiter ':'` sobre salida cruda de `rg`.

Referencia `jq` (opcional, no sustituye `Parse-RgJson` en el kit):

```bash
rg --json PATRON | jq -r 'select(.type=="match") | "\(.data.path.text)\t\(.data.line_number)\t\(.data.lines.text)"'
```

(Ajusta al esquema exacto de tu versión de ripgrep.)

## Preview en fzf

- Por defecto se usa **bat** si está en PATH; si no, **cat** / `type` (Windows).

## Tabla rápida: rg vs git grep vs fd

| Herramienta | Uso |
|-------------|-----|
| **rg** | Árbol de trabajo; respeta `.gitignore` por defecto; búsqueda de texto. |
| **git grep** | Lo que Git tiene en índice / commit; útil para “lo trackeado”, no sustituye un barrido amplio del working tree. |
| **fd** | Nombres, extensiones, profundidad; no busca “texto dentro” de archivos. |

## Qué **no** duplicar

- **ack** / **ag** si ya usas **rg**.
- **find** cotidiano si **fd** cubre el caso.
- Varios fuzzy finders si ya tienes **fzf**.

## Matriz rápida (empresa / repos grandes)

| Herramienta | Tier | Nota |
|-------------|------|------|
| rg / fd / fzf / zoxide / bat | Core | Base devql |
| delta / jq / eza / PSFzf | Extended | Tras Core |
| rga / ast-grep | Advanced | Opcional |
| ag / ack | Evitar | Solapan con rg |
| tokei / cloc | Doc opcional | Una convención por equipo |

## Errores típicos

- **`fdfind` vs `fd` (Debian/Ubuntu):** el paquete instala `fdfind`; el `setup.sh` crea enlace `fd` en `~/.local/bin` cuando hace falta.
- **Dos PATH:** WSL y Windows **no** comparten PATH por defecto; instala shims en **cada** entorno que uses.
- **Rendimiento WSL:** repos bajo **`/mnt/c/...`** suelen ser más lentos que en `~/...` (ext4 en el VHD). No atribuyas eso a “bug” de `devql` sin leer esta sección.

## Observabilidad (v1.1+)

- `DEVQL_DEBUG=1` — trazas.
- `DEVQL_LOG=1` — log en archivo por usuario (ruta documentada cuando se implemente).

## Automatización

- Scripts en el repo; shims en PATH; opcional **`DEV_ENV_ROOT`** apuntando al clone (Windows setup ya puede fijar variable de usuario).

## Spike aislado (Windows)

Desde la raíz del repo:

```powershell
powershell -File scripts/spike-rgjson.ps1 "patron"
```

Flujo: `rg --json` → `Parse-RgJson` → `fzf` (sin editor) para validar el pipeline.

## Tests

```powershell
powershell -File tests/run-parse-rgjson-tests.ps1
```

Tablas completas de gates: [TESTING.md](TESTING.md).

## Edge cases y límites

- Rutas con espacios: los launchers cotizan rutas al invocar el editor.
- **Symlinks / case:** Git y el FS pueden comportarse distinto entre Windows y Linux.
- **No** uses el cwd del proceso para localizar el kit: los scripts resuelven rutas desde su propia ubicación (`BASH_SOURCE` / `$PSScriptRoot`).

---

**Última nota:** si algo no está cubierto por el setup, suele vivir aquí o en [INSTALACION.md](INSTALACION.md), no solo en la cabeza del equipo.
