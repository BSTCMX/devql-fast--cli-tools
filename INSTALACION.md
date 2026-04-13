# Instalación — comandos por entorno (Core)

Ejecuta las herramientas **donde vive el repo** (PowerShell en Windows nativo; bash en WSL). No mezcles binarios de Windows dentro de WSL ni al revés sin saber lo que haces.

**Notas v1.0:** los mensajes del launcher en consola están en **inglés** (README y esta guía pueden seguir en español). Objetivo de tiempo: **instalación + primer uso funcional en ≤ 10 minutos** — mídelo una vez con cronómetro y anota el resultado en [TESTING.md](TESTING.md) (sección *Onboarding time*).

## Windows (winget)

```powershell
winget install -e --id BurntSushi.ripgrep.MSVC
winget install -e --id sharkdp.fd
winget install -e --id junegunn.fzf
winget install -e --id ajeetdsouza.zoxide
winget install -e --id sharkdp.bat
```

Luego el script del repo:

```powershell
cd "ruta\al\repo\devql"
.\setup.ps1
```

## WSL / Ubuntu / Debian (apt)

```bash
sudo apt update
sudo apt install -y ripgrep fzf bat
sudo apt install -y fd-find   # el binario suele llamarse fdfind
sudo apt install -y zoxide    # si no existe en tu version, ver upstream
```

En Debian/Ubuntu, crea el enlace `fd` si solo existe `fdfind` (el `setup.sh` lo hace en `~/.local/bin`).

## Verificación rápida

```bash
rg --version
fd --version   # o fdfind --version
fzf --version
zoxide --version
bat --version
```

```powershell
rg --version
fd --version
fzf --version
bat --version
```

## Extended (opcional)

- **Windows:** `winget install -e --id dandavison.delta`, `jqlang.jq`, y opcionalmente `Install-Module PSFzf -Scope CurrentUser`.
- **Linux:** paquetes `delta`, `jq`, etc., según distro.

Si algo de Extended falla (proxy, permisos), Core puede seguir siendo válido: revisa `GUIA-CLI.md` (política best-effort).
