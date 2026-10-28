# Nathpeando (`mando`)

Herramienta de terminal para **conectar, reconectar, inspeccionar, probar mandos y arreglar funcionamiento de mandos para su uso por bluetooth** en Linux.

La interfaz se llama **Nathpeando** (nombre a cambiar ? ) y el ejecutable `mando`, versión **1.2.1**.

## Características

- Menú interactivo y comandos directos.
- Escaneo en vivo: conecta en cuanto detecta el mando.
- Comprobación de estabilidad del enlace y del nodo HID durante varios segundos.
- Detección de errores HID del driver `nintendo` en el kernel.
- Lista de **mandos conocidos** por MAC, leyendo siempre el nombre actual de Bluez
- Prueba de botones y ejes con `evtest`; si Steam captura el mando, usa la interfaz `/dev/input/jsN` como respaldo.
- Comando `fix-bt` para evitar que el adaptador Bluetooth USB entre en autosuspend.

## Requisitos

- Linux con **BlueZ** (`bluetoothctl`).
- **Python 3**.
- `evtest` para `mando test`.
- `pkexec` para pedir permisos de lectura de `/dev/input/event*` y para `fix-bt`.
- Opcional: `tput` (ncurses) para ajustar el banner al tamaño de la terminal.

No hace falta root para conectar mandos. Solo `fix-bt` y, si hace falta, la lectura de nodos de entrada piden permisos con `pkexec`.

## Instalación

```bash
git clone https://github.com/Nathan0Sad/nathpeando.git
cd nathpeando
./install.sh
```

El instalador copia el script a `~/.local/bin/mando` y crea el lanzador en `~/.local/share/applications/conectar-mando.desktop`. No necesita `sudo`.

Asegúrate de que `~/.local/bin` esté en tu `PATH`. Si ya tienes un `mando` distinto, el instalador guarda una copia de respaldo antes de reemplazarlo.

También puedes ejecutarlo sin instalar:

```bash
./mando
```

### Desinstalar

```bash
./install.sh --uninstall
```

Elimina el ejecutable y el lanzador, pero conserva logs y estado en `~/.local/state/mando/`.

## Uso

```text
mando                 Menú interactivo
mando list            Lista mandos conocidos y su estado
mando scan [seg]      Busca y conecta el primer mando que aparezca
mando connect [MAC]   Conecta/reconecta un mando sin borrar el vínculo
mando auto [seg]      Igual que scan
mando test [MAC] [s]  Captura y resume botones/ejes (defecto 60 s)
mando info [MAC]      Estado, nodos y capacidades
mando fix-bt          Evita que el adaptador Bluetooth se suspenda
```

Ejemplos:

```bash
mando
mando list
mando scan 20
mando connect AA:BB:CC:DD:EE:FF
mando test AA:BB:CC:DD:EE:FF 60
mando info
mando fix-bt

```bash
mando rider
mando rider --mono
```

## Cómo reconoce los mandos

`mando list` y el menú obtienen los dispositivos de BlueZ con `bluetoothctl devices`. Para cada dispositivo consultan `bluetoothctl info` y lo aceptan como mando si tiene:

- `Icon: input-gaming`, o
- `Class: 0x00000508` / `0x00002508`.

Así no depende de que el nombre contenga “Xbox”, “Controller” o “Gamepad”: un mando renombrado sigue apareciendo con el mismo MAC y con el alias actual de BlueZ. Los audífonos y otros dispositivos HID quedan fuera.

## Seguridad y reversibilidad

- Nunca se borra un emparejamiento.
- Solo se usan `trust`, `connect` y, si hace falta, `pair`.
- Si el enlace se cae, se intenta reconectar sin desemparejar.
- `fix-bt` escribe estos archivos y muestra cómo revertirlos:
  - `/etc/modprobe.d/btusb-no-autosuspend.conf`
  - `/etc/tlp.d/50-bluetooth-mando.conf`
  - `/etc/udev/rules.d/99-bluetooth-no-autosuspend.rules`
- Los logs y ayudantes generados viven en `~/.local/state/mando/`.
- No hay telemetría ni conexiones de red.

## Estado y limitaciones

- La comprobación de estabilidad cubre una ventana de varios segundos; no puede garantizar el comportamiento de todos los juegos o drivers.
- Si Steam está abierto y captura el mando, `mando test` intenta usar la interfaz de joystick.
- `mando test` necesita `evtest` y permisos sobre el nodo de entrada.
- El proyecto está probado en Linux Mint 22.3 Cinnamon con BlueZ y Python 3.

## Archivos del repositorio

- `mando`: ejecutable principal.
- `install.sh`: instalador/desinstalador para el usuario.
- `conectar-mando.desktop`: plantilla del lanzador.
- `README.md`: este documento.
