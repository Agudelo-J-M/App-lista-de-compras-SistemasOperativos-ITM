# Guía de la VM — MySQL + API (Ubuntu en VirtualBox)

Paso a paso para dejar lista la VM del compañero de BD/API. Es la parte
"servidor" del flujo acordado:

```
PC físico del compañero de BD/API (Windows), sin internet el día de la sustentación

  Android Studio
  └─ Emulador Android (AVD)                   VM Ubuntu (VirtualBox, red NAT)
     ┌─────────────┐  http://10.0.2.2:3000/api  ┌───────────────────────────┐
     │ App Flutter │ ─────────────────────────► │ API Node.js :3000         │
     └─────────────┘  reenvío de puerto 3000    │        │                  │
                      del PC a la VM            │        ▼                  │
                                                │ MySQL :3306 (solo local)  │
                                                └───────────────────────────┘
```

- **Una sola VM**, con MySQL y la API. Android Studio y el emulador van en el
  **PC físico**, nunca dentro de la VM. Cómo instalarlos: [README.md](../README.md).
- La app llega a la VM por `10.0.2.2:3000`. `10.0.2.2` es la forma en que el
  emulador ve al PC, y VirtualBox reenvía ese puerto a la VM (paso 7).
- MySQL **no** se expone fuera de la VM: la API entra por `127.0.0.1:3306`.
- Contrato de la API y del esquema: [HANDOFF_BACKEND.md](../HANDOFF_BACKEND.md), sección 3.

Todos los pasos hasta el 8 necesitan **internet** en la VM. El día de la
sustentación ya no.

---

## 1. Crear la VM

En VirtualBox:

| Opción | Valor |
|--------|-------|
| Sistema | **Ubuntu Server 24.04 LTS** (recomendado). Si ya tienes Ubuntu 22.10, sirve: ver paso 2 |
| RAM | 2048 MB (MySQL + Node usan ~600 MB) |
| CPU | 1–2 |
| Disco | 20–25 GB |
| Red → Adaptador 1 | **NAT** (el de por defecto) |

Ojo con la RAM del **PC físico**: el emulador de Android necesita unos 4 GB y
Android Studio otros 2 GB, además de los 2 GB de la VM. Con 8 GB físicos va
justo; con 16 GB va bien.

---

## 2. Solo si la VM es Ubuntu 22.10

22.10 ya no tiene soporte y `apt update` falla con 404. Hay que apuntar `apt`
al archivo de versiones viejas:

```bash
sudo cp /etc/apt/sources.list /etc/apt/sources.list.bak
sudo sed -i -E 's|https?://([a-z]+\.)?(archive|security)\.ubuntu\.com/ubuntu/?|http://old-releases.ubuntu.com/ubuntu/|g' /etc/apt/sources.list
sudo apt update
```

Con 24.04 LTS sáltate este paso.

---

## 3. Paquetes básicos y el repo

```bash
sudo apt update
sudo apt install -y git curl
sudo git clone https://github.com/Agudelo-J-M/App-lista-de-compras-SistemasOperativos-ITM.git /opt/lista-compras
```

---

## 4. Base de datos

```bash
sudo apt install -y mysql-server
sudo systemctl enable --now mysql

cd /opt/lista-compras/backend
sudo mysql < schema.sql          # base, tabla y usuario app_compras
sudo mysql < datos_ejemplo.sql   # 5 productos de ejemplo
```

En Ubuntu, `sudo mysql` entra como root sin contraseña.

**Pon una contraseña propia al usuario de la API.** Hazlo con este comando y
**no** editando `schema.sql`: así la clave real nunca termina subida al repo.

```bash
sudo mysql -e "ALTER USER 'app_compras'@'localhost' IDENTIFIED BY 'TuClaveAqui';"
```

Anótala: va en el `.env` del paso 5. Comprueba:

```bash
sudo mysql -e "SELECT id, nombre, cantidad, unidad, estado FROM lista_compras.productos;"
```

---

## 5. API (Node.js)

### 5.1 Node.js

```bash
sudo apt install -y nodejs npm
node --version
```

Necesita **Node 18 o más nuevo**. Si sale una versión menor, instala Node 20
LTS:

```bash
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt install -y nodejs
```

### 5.2 Dependencias y configuración

```bash
cd /opt/lista-compras/backend/api
sudo npm ci --omit=dev
sudo cp .env.example .env
sudo nano .env
```

En `.env`, cambia `DB_PASSWORD` por la clave del paso 4. El resto queda igual:

```
PORT=3000
HOST=0.0.0.0
DB_HOST=127.0.0.1
DB_PORT=3306
DB_USER=app_compras
DB_PASSWORD=TuClaveAqui
DB_NAME=lista_compras
```

`.env` está en `.gitignore`, así que la contraseña no se sube al repo.

### 5.3 Probar a mano

```bash
cd /opt/lista-compras/backend/api
node server.js
```

Debe decir `API Lista de Compras escuchando en http://0.0.0.0:3000/api`. En
otra terminal:

```bash
curl -i http://localhost:3000/api/salud
curl -i http://localhost:3000/api/productos
```

El segundo debe devolver `200` y los 5 productos. Detén con `Ctrl+C`.

---

## 6. API como servicio (arranca sola con la VM)

```bash
sudo useradd --system --create-home --shell /usr/sbin/nologin lista
sudo chown -R lista:lista /opt/lista-compras
sudo chmod 600 /opt/lista-compras/backend/api/.env
sudo cp /opt/lista-compras/backend/api/lista-compras-api.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable --now lista-compras-api
systemctl status lista-compras-api --no-pager
```

Debe decir `active (running)`. Si no: `journalctl -u lista-compras-api -n 30 --no-pager`.

---

## 7. Red: firewall y reenvío de puerto

### 7.1 Firewall de la VM

```bash
sudo ufw allow OpenSSH
sudo ufw allow 3000/tcp
sudo ufw enable
sudo ufw status
```

**No abras el 3306.**

### 7.2 Reenvío de puerto en VirtualBox

Con la VM encendida o apagada: **Configuración → Red → Adaptador 1 (NAT) →
Avanzado → Reenvío de puertos → +**

| Nombre | Protocolo | IP anfitrión | Puerto anfitrión | IP invitado | Puerto invitado |
|--------|-----------|--------------|------------------|-------------|-----------------|
| api    | TCP       | *(vacío)*    | 3000             | *(vacío)*   | 3000            |

### 7.3 Probar desde el PC físico

En el **Símbolo del sistema (cmd)** de Windows, no en PowerShell:

```bat
curl -i http://localhost:3000/api/productos
```

Si responde `200` con el JSON, el emulador también va a llegar por
`http://10.0.2.2:3000/api`. Para confirmarlo, abre Chrome **dentro del
emulador** y visita esa URL. Las pruebas de cada endpoint están en
[HANDOFF_BACKEND.md](../HANDOFF_BACKEND.md), sección 5.

---

## 8. Actualizar la API después de un cambio en el repo

```bash
cd /opt/lista-compras
sudo -u lista git pull
cd backend/api
sudo -u lista npm ci --omit=dev
sudo systemctl restart lista-compras-api
```

(`sudo -u lista` porque la carpeta es del usuario del servicio.)

---

## 9. Pruebas de la API (opcional)

No necesitan MySQL: usan una base en memoria. Requieren las dependencias de
desarrollo, así que hazlo en una copia aparte o en tu PC, no en `/opt`:

```bash
cd backend/api
npm ci
npm test
```

---

## 10. Antes de la sustentación

1. Ensaya **sin internet**: apaga el Wi-Fi del PC, enciende la VM (MySQL y la
   API arrancan solas) y comprueba `curl -i http://localhost:3000/api/productos`
   desde el PC.
2. Limpia lo que dejaron los ensayos:
   ```bash
   sudo mysql < /opt/lista-compras/backend/datos_ejemplo.sql
   ```
3. Abre Android Studio, inicia el emulador y dale Run ▶. Checklist completo:
   [HANDOFF_BACKEND.md](../HANDOFF_BACKEND.md), sección 8.

---

## Problemas comunes

| Síntoma | Causa / solución |
|---------|------------------|
| `apt update` da 404 | Ubuntu 22.10: falta el paso 2 |
| `systemctl status` muestra `failed` | `journalctl -u lista-compras-api -n 30`. Lo más común: clave de `.env` distinta a la del `ALTER USER` |
| `ER_ACCESS_DENIED_ERROR` en el log | La clave no coincide: repite el `ALTER USER` del paso 4 y ajusta `.env` |
| `ECONNREFUSED 127.0.0.1:3306` en el log | MySQL apagado: `sudo systemctl start mysql` |
| `curl` en la VM funciona pero desde el PC no | Falta el reenvío de puerto (7.2) o `ufw` bloquea el 3000 (7.1) |
| Desde el PC funciona pero la app no conecta | La app no está usando `http://10.0.2.2:3000/api`: la pantalla de error muestra la URL |
| La app muestra "Error del servidor (500)" | Falla de MySQL: revisa `journalctl -u lista-compras-api` |
| El emulador va muy lento o no arranca con la VM encendida | Activa **Plataforma del hipervisor de Windows** ([HANDOFF_BACKEND.md](../HANDOFF_BACKEND.md), sección 4) |

## Chuleta

```bash
sudo systemctl status mysql lista-compras-api
sudo systemctl restart lista-compras-api
journalctl -u lista-compras-api -n 30 --no-pager
curl -i http://localhost:3000/api/productos
sudo mysql < /opt/lista-compras/backend/datos_ejemplo.sql
```
