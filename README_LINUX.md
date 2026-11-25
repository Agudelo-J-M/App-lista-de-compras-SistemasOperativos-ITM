# Instalación en Linux — Lista de Compras (Ubuntu 22.10)

Guía para montar el proyecto completo con **las dos VM en Ubuntu 22.10**:

- **SERVIDOR**: MySQL/MariaDB + API REST (Node.js + Express).
- **ESTACION-TRABAJO**: Flutter y la app.

> Esta guía asume la configuración descrita de las VM: Ubuntu 22.10, 2 GB de
> RAM, disco de 25 GB, VirtualBox, red NAT + adaptador **RedLaboratorio**, red
> sin internet el día de la sustentación.

## 0. Lee esto antes de empezar (dos limitaciones reales)

### 0.1 Ubuntu 22.10 está descontinuado (EOL)

22.10 dejó de tener soporte en julio de 2023, así que
`archive.ubuntu.com` ya no tiene sus paquetes y `apt update` falla con 404.
Hay que apuntar `apt` a `old-releases.ubuntu.com` (paso 2). Funciona, pero lo
ideal a futuro es reinstalar **Ubuntu 24.04 LTS**.

### 0.2 Con 2 GB de RAM el emulador de Android no es viable

Android Studio + un emulador x86_64 necesitan **6–8 GB de RAM** y unos
**15 GB de disco** solo para el SDK, la imagen y Gradle. Con 2 GB y 25 GB se
queda sin memoria o sin disco. Además, para que el emulador acelere dentro de
una VM hay que habilitar virtualización anidada en el anfitrión.

Caminos posibles, de más a menos recomendado:

| Camino | Qué se instala en la estación | RAM que necesita | Cumple "emulador" |
|--------|-------------------------------|------------------|-------------------|
| **A. Flutter Linux desktop** (recomendado) | Flutter SDK ~2.5 GB, sin Android | ~1.5 GB | No, corre como app de escritorio |
| **B. Celular Android real por USB** | Flutter + Android SDK + Java + Gradle ~10 GB | ~2.5 GB (ajustado) | No, pero es Android real |
| **C. Emulador Android** | Flutter + Android Studio + SDK + AVD ~15 GB | 8 GB | Sí |

Esta guía desarrolla **A** completo y deja **B** y **C** como secciones 6 y 7.

---

## 1. Arquitectura y direcciones

```
VM SERVIDOR (192.168.50.10)              VM ESTACION-TRABAJO (192.168.50.20)
┌───────────────────────────┐            ┌──────────────────────────────┐
│  API Node.js  :3000       │◄── HTTP ───│  App Flutter (Linux desktop) │
│        │                  │  RedLaboratorio                            │
│        ▼                  │            └──────────────────────────────┘
│  MySQL :3306 (localhost)  │
└───────────────────────────┘
```

Reglas:

- MySQL **nunca** se expone: la API corre en la misma VM y entra por
  `127.0.0.1:3306`. Solo se abre el puerto **3000**.
- Las dos VM se hablan por el adaptador **RedLaboratorio** con IP fija.
- **No uses `10.0.2.2`** en este montaje: esa dirección es el "PC anfitrión"
  *dentro* del emulador de Android, no el servidor. Aquí se usa la IP del
  servidor en RedLaboratorio.

---

## 2. Preparar Ubuntu 22.10 (en las DOS VM)

```bash
sudo cp /etc/apt/sources.list /etc/apt/sources.list.bak
sudo sed -i -E 's|https?://(archive|security|ports)\.ubuntu\.com/ubuntu/?|http://old-releases.ubuntu.com/ubuntu/|g' /etc/apt/sources.list
sudo apt update
sudo apt full-upgrade -y
```

Si hay archivos en `/etc/apt/sources.list.d/`, revisa que ninguno siga
apuntando a `archive.ubuntu.com`:

```bash
grep -R "ubuntu.com/ubuntu" /etc/apt/sources.list.d/ 2>/dev/null
```

Instala lo básico:

```bash
sudo apt install -y curl git unzip nano
```

En la estación agrega swap (con 2 GB hace falta):

```bash
free -h
sudo fallocate -l 2G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
free -h
```

---

## 3. SERVIDOR: base de datos

```bash
sudo apt install -y mysql-server
sudo systemctl enable --now mysql
sudo mysql          # root de Ubuntu entra por socket, sin contraseña
```

Antes de cargar el esquema, **cambia la contraseña** de `app_compras` en
[`backend/schema.sql`](backend/schema.sql), línea 32 (por defecto
`CambiarEstaClave123!`). Anótala: la API la usa.

Copia el repo al servidor y ejecuta los dos scripts:

```bash
sudo git clone https://github.com/Agudelo-J-M/App-lista-de-compras-SistemasOperativos-ITM.git /opt/lista-compras
cd /opt/lista-compras
sudo mysql < backend/schema.sql
sudo mysql < backend/datos_ejemplo.sql
sudo mysql -e "SELECT id, nombre, cantidad, unidad, estado FROM lista_compras.productos;"
```

Deben aparecer los 5 productos de ejemplo. `datos_ejemplo.sql` se puede
repetir antes de la sustentación para limpiar lo que dejaron los ensayos.

---

## 4. SERVIDOR: API REST

La API está en [`backend/api/`](backend/api/): Node.js + Express + mysql2.
Es un proceso único, usa ~60 MB de RAM y cumple el contrato de
`HANDOFF_BACKEND.md` §3 (incluidos los errores en español que muestra la app).

### 4.1 Instalar Node.js y dependencias

```bash
sudo apt install -y nodejs npm
node --version      # Ubuntu 22.10 trae Node 18.x, suficiente
```

```bash
cd /opt/lista-compras/backend/api
sudo npm install --omit=dev
```

### 4.2 Configurar credenciales

```bash
sudo cp .env.example .env
sudo nano .env       # DB_PASSWORD = la misma clave de schema.sql
```

`.env` está en `.gitignore`: la contraseña no se sube al repo.

### 4.3 Probar a mano

```bash
cd /opt/lista-compras/backend/api
sudo node server.js
```

Deja esa terminal abierta y en otra prueba:

```bash
curl -i http://localhost:3000/api/salud
curl -i http://localhost:3000/api/productos
```

`Ctrl+C` para detener.

### 4.4 Servicio systemd (arranca solo con la VM)

```bash
sudo useradd --system --create-home --shell /usr/sbin/nologin lista
sudo chown -R lista:lista /opt/lista-compras
sudo chmod 600 /opt/lista-compras/backend/api/.env
sudo cp /opt/lista-compras/backend/api/lista-compras-api.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable --now lista-compras-api
systemctl status lista-compras-api --no-pager
journalctl -u lista-compras-api -n 30 --no-pager
```

El servicio escucha en `0.0.0.0:3000` (así lo define `HOST` en `.env`), que es
lo que necesita la estación.

### 4.5 Firewall del servidor

```bash
sudo apt install -y ufw
sudo ufw allow OpenSSH
sudo ufw allow from 192.168.50.0/24 to any port 3000 proto tcp
sudo ufw enable
sudo ufw status
```

Así el 3000 solo lo ve la red del laboratorio. **No abras el 3306.**

---

## 5. Red RedLaboratorio entre las dos VM

En VirtualBox, en **cada** VM: *Configuración → Red → Adaptador 2* debe ser
**Red interna** (o *NAT Network*) con el nombre `RedLaboratorio`.

Averigua en cada VM el nombre de la interfaz del segundo adaptador (suele ser
`enp0s8`):

```bash
ip -br addr
```

### 5.1 Si RedLaboratorio es "Red interna" (no hay DHCP): IP fija

Con NetworkManager (Ubuntu Desktop), en el servidor:

```bash
sudo nmcli con add type ethernet ifname enp0s8 con-name labor ip4 192.168.50.10/24
sudo nmcli con up labor
```

En la estación, lo mismo con `192.168.50.20/24`.

Si es Ubuntu Server con netplan (`/etc/netplan/*.yaml`):

```yaml
network:
  version: 2
  ethernets:
    enp0s8:
      addresses: [192.168.50.10/24]   # .20 en la estación
```

```bash
sudo netplan apply
```

### 5.2 Si RedLaboratorio es "NAT Network" (hay DHCP)

No configures nada: mira la IP que asignó y úsala en los pasos siguientes.

```bash
ip -br addr show enp0s8
```

### 5.3 Comprobar la conexión (desde la estación)

```bash
ping -c 2 192.168.50.10
curl -i http://192.168.50.10:3000/api/productos
```

Si el `curl` devuelve `200` con el JSON de los 5 productos, la red y la API
están listas. **No sigas hasta que esto funcione.**

---

## 6. ESTACION-TRABAJO: app Flutter (Camino A, recomendado)

La app se compila como aplicación **Linux de escritorio**, sin Android Studio,
sin emulador y sin Android SDK. Es lo que sí aguanta una VM de 2 GB.

### 6.1 Dependencias de compilación

```bash
sudo apt install -y curl git unzip xz-utils zip libglu1-mesa clang cmake \
  ninja-build pkg-config libgtk-3-dev liblzma-dev libstdc++-12-dev mesa-utils
```

### 6.2 Instalar Flutter SDK (necesita internet)

Descarga el `.tar.xz` **stable para Linux** desde
<https://docs.flutter.dev/install/archive> y descomprímelo:

```bash
mkdir -p ~/development
cd ~/Downloads
tar xf flutter_linux_*stable*.tar.xz -C ~/development
echo 'export PATH="$PATH:$HOME/development/flutter/bin"' >> ~/.bashrc
source ~/.bashrc
flutter --version
flutter config --no-analytics
flutter doctor
```

`flutter doctor` va a marcar en rojo *Android toolchain* y *Chrome*: ignóralo,
no se usan en este camino.

### 6.3 Clonar el proyecto y habilitar Linux

```bash
cd ~
git clone https://github.com/Agudelo-J-M/App-lista-de-compras-SistemasOperativos-ITM.git
cd App-lista-de-compras-SistemasOperativos-ITM
flutter create --platforms=linux .
flutter pub get
```

`flutter create --platforms=linux .` solo **agrega** la carpeta `linux/`; no
toca `lib/`. Esa carpeta nueva hay que subirla al repo.

### 6.4 Ejecutar contra la API del servidor

```bash
flutter run -d linux \
  --dart-define=USE_MOCK=false \
  --dart-define=API_BASE_URL=http://192.168.50.10:3000/api
```

La URL debe terminar en **`/api`** (la app le agrega `/productos`).

- Si la ventana sale negra o la app no arranca por OpenGL, en VirtualBox:
  *Configuración → Pantalla → Aceleración 3D activada, 128 MB de video* e
  instala las **Guest Additions** (*Dispositivos → Insertar CD de Guest
  Additions*). Alternativa rápida:
  ```bash
  LIBGL_ALWAYS_SOFTWARE=1 flutter run -d linux --dart-define=USE_MOCK=false \
    --dart-define=API_BASE_URL=http://192.168.50.10:3000/api
  ```
- Si prefieres no escribir la URL cada vez, edítala como valor por defecto en
  [`lib/utils/constants.dart`](lib/utils/constants.dart) (`kApiBaseUrl` y
  `kUseMockData = false`).

### 6.5 Pruebas

```bash
flutter test          # pruebas del cliente HTTP (no necesitan la API)
cd backend/api && npm test   # pruebas de la API (no necesitan MySQL)
```

---

## 7. Camino B: celular Android real por USB (sin emulador)

Útil si necesitan sí o sí una app Android. Requiere un celular con depuración
USB y **unos 10 GB libres** en el disco de 25 GB.

1. En VirtualBox, con la VM apagada: *Configuración → USB → USB 2.0 (EHCI)* y
   crea un filtro con el celular conectado.
2. En la VM:
   ```bash
   sudo apt install -y android-tools-adb
   sudo usermod -aG plugdev $USER
   adb devices        # debe listar el celular como "device"
   ```
3. Instala Java 17 y el SDK de Android (solo `cmdline-tools` y
   `platform-tools`; **no** instales el emulador):
   ```bash
   sudo apt install -y openjdk-17-jdk
   mkdir -p ~/Android/Sdk/cmdline-tools && cd ~/Android/Sdk/cmdline-tools
   unzip ~/Downloads/commandlinetools-linux-*.zip
   mv cmdline-tools latest 2>/dev/null || true
   export ANDROID_HOME="$HOME/Android/Sdk"
   flutter config --android-sdk "$ANDROID_HOME"
   flutter doctor --android-licenses
   ```
4. Ejecuta con `-d <id_del_celular>` en lugar de `-d linux`.

Con 2 GB de RAM, cierra todo lo demás: Gradle es el que más memoria consume.
Si falla por memoria, este camino no es viable sin ampliar la VM.

---

## 8. Camino C: emulador Android (solo si amplías la VM)

**Android Studio y el emulador van SIEMPRE en ESTACION-TRABAJO**, nunca en el
servidor. El servidor es headless y solo necesita MySQL + Node.

### 8.1 Cuánto subir

| VM | RAM | Disco | vCPU | Video |
|---|---|---|---|---|
| **ESTACION-TRABAJO** | **8192 MB** (mínimo 6144) | **60 GB** | 4 | 128 MB + 3D |
| SERVIDOR | 2048 MB (hasta 3072 si el anfitrión da) | 25 GB | 2 | 16 MB |

Con 8 GB la estación reparte así: Ubuntu ~1 GB, Android Studio ~1.5 GB,
Gradle ~2 GB, emulador ~2.5 GB y margen para el resto. Con 6 GB funciona pero
justo; con 4 GB o menos, no.

El **anfitrión** necesita ~4 GB para sí mismo, así que debe tener como mínimo
**12 GB físicos** (recomendado 16 GB) para dar 8 GB a la estación y 2 GB al
servidor a la vez. Si el anfitrión tiene 8 GB, no alcance para el emulador:
usa el camino A o B.

Con 25 GB de disco el emulador no cabe (SDK + imagen + Gradle + Flutter pasan
de 25 GB). Hay que subirlo a 60 GB.

### 8.2 Comandos (desde el anfitrión, con las VM apagadas)

```bash
VBoxManage modifyvm "ESTACION-TRABAJO" --memory 8192 --cpus 4 \
  --vram 128 --accelerate3d on --nested-hw-virt on
VBoxManage modifyhd "ESTACION-TRABAJO.vdi" --resize 61440
```

- `--memory 8192` = 8 GB.
- `--nested-hw-virt on` habilita VT-x/AMD-V anidado; sin esto no hay
  `/dev/kvm` y el emulador no acelera. El CPU del anfitrión debe soportarlo y
  estar habilitado en la BIOS.
- `--resize 61440` = 60 GB. Después, dentro de Ubuntu, amplía la partición
  (`lsblk` para ver los nombres, luego `sudo growpart /dev/sda 3` y
  `sudo resize2fs /dev/sda3`).

Dentro de la VM comprueba que hay aceleración:

```bash
sudo apt install -y qemu-kvm cpu-checker
kvm-ok
ls -l /dev/kvm
```

Si `/dev/kvm` no existe, el emulador no servirá. Si existe:

```bash
sudo snap install android-studio --classic
sudo usermod -aG kvm $USER     # cerrar sesión y volver a entrar
```

Luego, como en el README de Windows: SDK Manager → *Command-line Tools*,
`flutter doctor --android-licenses`, plugin de Flutter, crear AVD con imagen
**x86_64** y `flutter run` con la misma `API_BASE_URL`.

> Con el emulador, `10.0.2.2` **tampoco** sirve aquí: dentro de la estación
> apunta a la propia estación, no al servidor. Sigue usando
> `http://192.168.50.10:3000/api`.

---

## 9. Ensayo sin internet

1. Con internet, deja todo instalado y ejecuta **una vez** la app contra la API
   (Flutter y `pub` guardan caché).
2. Apaga el Wi-Fi del anfitrión o pon modo avión en las VM.
3. Enciende la VM servidor (MySQL y la API arrancan solos por systemd) y
   comprueba:
   ```bash
   curl http://localhost:3000/api/productos
   ```
4. Limpia los datos de ensayo: `sudo mysql < /opt/lista-compras/backend/datos_ejemplo.sql`.
5. Enciende la estación y ejecuta la app.

**Plan B** si el servidor falla en plena sustentación: en
`lib/utils/constants.dart` pon `kUseMockData = true` (o ejecuta con
`--dart-define=USE_MOCK=true`) y la app arranca con datos de prueba.

---

## 10. Problemas comunes

| Síntoma | Causa / solución |
|---|---|
| `apt update` da 404 en `archive.ubuntu.com` | Falta el paso 2 (old-releases) |
| `curl` desde la estación: *Connection refused* | La API no está corriendo: `systemctl status lista-compras-api` |
| `curl` se queda colgado / *timed out* | IP equivocada o `ufw` bloqueando el 3000 (pasos 4.5 y 5.3) |
| La API arranca y muere al instante | Credenciales de `.env` distintas a las de `schema.sql`: `journalctl -u lista-compras-api -n 30` |
| `ER_ACCESS_DENIED_ERROR` | La clave de `app_compras` no coincide; vuelve a ejecutar el `GRANT`/`ALTER USER` |
| `ECONNREFUSED 127.0.0.1:3306` | MySQL apagado: `sudo systemctl start mysql` |
| App: "No se pudo conectar con el servidor" | `API_BASE_URL` mal, API caída o firewall (revisa la URL que muestra la pantalla) |
| App: "El servidor no respondió a tiempo" | IP del servidor incorrecta o VM apagada |
| App: "Error del servidor (500)" | Falla de MySQL en el servidor: `journalctl -u lista-compras-api` |
| `flutter: command not found` | Falta el `export PATH` del paso 6.2 o no abriste terminal nueva |
| `flutter run -d linux` falla por `libgtk-3-dev` | Repite las dependencias del paso 6.1 |
| Ventana negra / OpenGL | Paso 6.4: 3D + Guest Additions, o `LIBGL_ALWAYS_SOFTWARE=1` |
| La compilación de Flutter muere por memoria | Cierra todo, verifica swap (paso 2) y usa `-d linux` |
| `kvm-ok` dice que no hay aceleración | Virtualización anidada deshabilitada o CPU sin soporte (paso 8) |

---

## 11. Chuleta de comandos

```bash
# servidor
sudo systemctl status mysql lista-compras-api
sudo systemctl restart lista-compras-api
curl -i http://localhost:3000/api/productos
sudo mysql < /opt/lista-compras/backend/datos_ejemplo.sql

# estación
cd ~/App-lista-de-compras-SistemasOperativos-ITM
flutter pub get
flutter run -d linux --dart-define=USE_MOCK=false \
  --dart-define=API_BASE_URL=http://192.168.50.10:3000/api

# red
ip -br addr
ping -c 2 192.168.50.10
curl -i http://192.168.50.10:3000/api/productos
```
