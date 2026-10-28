#!/usr/bin/env bash
# Instalador de Nathpeando (`mando`) para el usuario actual.
# No necesita root. No modifica Bluetooth ni borra emparejamientos.

set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
BIN_DIR="${HOME}/.local/bin"
APPS_DIR="${XDG_DATA_HOME:-${HOME}/.local/share}/applications"
STATE_DIR="${XDG_STATE_HOME:-${HOME}/.local/state}/mando"
DESKTOP_SRC="${SCRIPT_DIR}/conectar-mando.desktop"
DESKTOP_DST="${APPS_DIR}/conectar-mando.desktop"
TARGET="${BIN_DIR}/mando"

usage() {
  cat <<EOF
Uso: ./install.sh [--uninstall]

  (sin opciones)  Instala mando en ${BIN_DIR}
                  y el lanzador en ${APPS_DIR}
  --uninstall     Elimina el ejecutable y el lanzador.
                  Conserva logs y estado en ${STATE_DIR}
  -h, --help      Muestra esta ayuda
EOF
}

case "${1:-}" in
  -h|--help)
    usage
    exit 0
    ;;
  --uninstall)
    removed=0
    if [ -e "$TARGET" ]; then
      rm -f "$TARGET"
      echo "Eliminado: $TARGET"
      removed=1
    fi
    if [ -e "$DESKTOP_DST" ]; then
      rm -f "$DESKTOP_DST"
      echo "Eliminado: $DESKTOP_DST"
      removed=1
    fi
    if command -v update-desktop-database >/dev/null 2>&1; then
      update-desktop-database "$APPS_DIR" >/dev/null 2>&1 || true
    fi
    if [ "$removed" = 0 ]; then
      echo "No había nada instalado en las rutas habituales."
    fi
    echo "Se conserva el estado en: $STATE_DIR"
    exit 0
    ;;
  "")
    ;;
  *)
    echo "Opción desconocida: $1" >&2
    usage >&2
    exit 1
    ;;
esac

if [ ! -f "${SCRIPT_DIR}/mando" ]; then
  echo "No encuentro ${SCRIPT_DIR}/mando" >&2
  exit 1
fi
if [ ! -f "$DESKTOP_SRC" ]; then
  echo "No encuentro $DESKTOP_SRC" >&2
  exit 1
fi

mkdir -p "$BIN_DIR" "$APPS_DIR"

# Respaldo si ya existe una versión distinta.
if [ -e "$TARGET" ] && ! cmp -s "${SCRIPT_DIR}/mando" "$TARGET"; then
  backup="${TARGET}.bak-$(date '+%Y%m%d-%H%M%S')"
  cp -a "$TARGET" "$backup"
  echo "Respaldo del mando anterior: $backup"
fi

install -m 0755 "${SCRIPT_DIR}/mando" "$TARGET"

# Lanzador con la ruta absoluta del ejecutable instalado.
exec_value="$TARGET"
case "$exec_value" in
  *[[:space:]]*) exec_value="\"$exec_value\"" ;;
esac
awk -v e="$exec_value" '
  /^Exec=/ { print "Exec=" e; next }
  { print }
' "$DESKTOP_SRC" >"$DESKTOP_DST"
chmod 0644 "$DESKTOP_DST"

if command -v update-desktop-database >/dev/null 2>&1; then
  update-desktop-database "$APPS_DIR" >/dev/null 2>&1 || true
fi

echo
echo "Nathpeando instalado:"
echo "  ejecutable: $TARGET"
echo "  lanzador:   $DESKTOP_DST"
echo

missing=0
for cmd in bluetoothctl python3; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "Falta '$cmd'. Instálalo antes de conectar mandos." >&2
    missing=1
  fi
done
if ! command -v evtest >/dev/null 2>&1; then
  echo "Aviso: falta 'evtest'; 'mando test' no podrá capturar botones." >&2
fi
if ! command -v pkexec >/dev/null 2>&1; then
  echo "Aviso: falta 'pkexec'; algunas funciones pueden requerir permisos manuales." >&2
fi
if [ "$missing" = 1 ]; then
  echo "La instalación quedó copiada, pero faltan dependencias." >&2
fi

case ":${PATH}:" in
  *":${BIN_DIR}:"*) ;;
  *)
    echo "Añade ${BIN_DIR} a tu PATH para ejecutar 'mando':" >&2
    echo "  export PATH=\"\$HOME/.local/bin:\$PATH\"" >&2
    ;;
esac

echo "Prueba con: mando"
