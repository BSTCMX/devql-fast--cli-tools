#!/usr/bin/env bash
# Instala tier Core (rg, fd, fzf, zoxide, bat) en Linux/WSL — idempotente en lo posible.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$SCRIPT_DIR"

EXTENDED=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    --extended) EXTENDED=1; CORE_ONLY=0 ;;
    --help|-h)
      echo "Uso: ./setup.sh [--extended]"
      exit 0
      ;;
    *) echo "Opcion desconocida: $1" >&2; exit 1 ;;
  esac
  shift
done

if command -v apt-get >/dev/null 2>&1; then
  sudo apt-get update -y
  sudo apt-get install -y ripgrep fd-find fzf bat || true
  if ! command -v zoxide >/dev/null 2>&1; then
    sudo apt-get install -y zoxide 2>/dev/null || echo "Aviso: instala zoxide manualmente si no hay paquete."
  fi
else
  echo "No se detecto apt. Instala rg, fd, fzf, bat, zoxide con tu gestor de paquetes (ver INSTALACION.md)."
fi

# Debian/Ubuntu: fdfind -> fd
if command -v fdfind >/dev/null 2>&1 && ! command -v fd >/dev/null 2>&1; then
  mkdir -p "${HOME}/.local/bin"
  ln -sf "$(command -v fdfind)" "${HOME}/.local/bin/fd"
  echo "Enlace creado: ~/.local/bin/fd -> fdfind"
  case ":${PATH}:" in
    *:"${HOME}/.local/bin":*) ;;
    *) echo "Anade a ~/.bashrc: export PATH=\"\$HOME/.local/bin:\$PATH\"" ;;
  esac
fi

# Shims en ~/bin
mkdir -p "${HOME}/bin"

cat > "${HOME}/bin/devql" <<EOF
#!/usr/bin/env bash
exec "${REPO_ROOT}/bin/devql" "\$@"
EOF
cat > "${HOME}/bin/qfiles" <<EOF
#!/usr/bin/env bash
exec "${REPO_ROOT}/bin/devql" files "\$@"
EOF
cat > "${HOME}/bin/qtxt" <<EOF
#!/usr/bin/env bash
exec "${REPO_ROOT}/bin/devql" text "\$@"
EOF
chmod +x "${HOME}/bin/devql" "${HOME}/bin/qfiles" "${HOME}/bin/qtxt"

echo "Shims instalados en ~/bin apuntando a: ${REPO_ROOT}/bin/devql"

case ":${PATH}:" in
  *:"${HOME}/bin":*) ;;
  *) echo "Advertencia: ~/bin no esta en PATH. Anade: export PATH=\"\$HOME/bin:\$PATH\" (persiste en ~/.bashrc)." ;;
esac

if [[ "$EXTENDED" -eq 1 ]]; then
  echo "Modo --extended: instala delta, jq, eza segun tu distro (best-effort)."
  command -v apt-get >/dev/null 2>&1 && sudo apt-get install -y delta jq 2>/dev/null || true
fi

echo "Setup Core terminado. Verifica: command -v rg fd fzf bat"
exit 0
