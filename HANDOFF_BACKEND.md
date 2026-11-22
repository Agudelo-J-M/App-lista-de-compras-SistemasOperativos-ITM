# Handoff para el compañero de BD/API — Lista de Compras

## Roles y flujo de trabajo (igual en todos los documentos)

| Quién                        | Responsabilidad                                                        |
|------------------------------|------------------------------------------------------------------------|
| **Mauro**                    | App Flutter: pantallas, lógica y cliente HTTP. **Ya está hecha.**      |
| **Compañero de BD/API**      | Base de datos + API en una VM en su PC. Al final ejecuta la app desde Android Studio, en el emulador, y presenta. |
| **Compañero de integración** | Ajusta la app en el repo para que se conecte a la API real del compañero de BD/API. |

1. **BD/API** construye y prueba la API en su VM, llena
   [`backend/FICHA_API.md`](backend/FICHA_API.md) y la sube al repo.
2. **Integración** lee la ficha, ajusta la app, la prueba y sube los cambios al repo.
3. **BD/API** hace `git pull`, abre el proyecto en **Android Studio** y lo
   ejecuta en el **emulador** contra su VM. Si algo falla, se lo reporta a
   integración y se repiten los pasos 2 y 3.
4. **Sustentación:** BD/API presenta desde su PC, **sin internet**. La app corre
   desde Android Studio en el emulador y se conecta a la VM local.

Cómo abrir y ejecutar el proyecto en Android Studio, paso a paso:
[README.md](README.md).

---

**Este documento es para ti, compañero de BD/API.**

Si algo de aquí no se puede cumplir (otro puerto, otra forma de un campo,
etc.), anótalo en `backend/FICHA_API.md` en "Diferencias con el contrato" y
avísale al compañero de integración.

## Resumen de tareas

- [ ] 1. Crear la VM (Windows Server o Linux) e instalar MySQL o MariaDB.
- [ ] 2. Ejecutar [`backend/schema.sql`](backend/schema.sql) (base, tabla `productos` y usuario) y luego [`backend/datos_ejemplo.sql`](backend/datos_ejemplo.sql).
- [ ] 3. Programar la API REST con los 5 endpoints de la sección 3 (lenguaje libre).
- [ ] 4. Hacer que la API escuche en `0.0.0.0:3000` y abrir el puerto 3000 en el firewall de la VM.
- [ ] 5. Configurar la red de la VM con reenvío de puerto 3000 → 3000 (sección 4).
- [ ] 6. Probar la API desde el PC anfitrión (sección 5).
- [ ] 7. Llenar `backend/FICHA_API.md` y subirla al repo (sección 6). Opcional: subir también el código de la API en `backend/api/`.
- [ ] 8. **Con internet**, instalar Android Studio y Flutter y ejecutar la app una vez (README.md).
- [ ] 9. Cuando integración avise: `git pull`, ejecutar la app contra la VM y reportar errores (sección 7).
- [ ] 10. Ensayar la sustentación completa **sin internet** (sección 8).

---

## 1. Arquitectura

```
Tu PC (el día de la sustentación, sin internet)

  Android Studio
  └─ Emulador Android (AVD)                    VM (Windows Server / Linux)
     ┌─────────────┐   http://10.0.2.2:3000/api   ┌──────────────────┐
     │ App Flutter │ ───────────────────────────► │ API REST :3000   │
     └─────────────┘   (reenvío de puerto NAT     │        │         │
                        de tu PC a la VM)         │        ▼         │
                                                  │ MySQL :3306      │
                                                  └──────────────────┘
```

- La app **solo habla con la API**, nunca con MySQL directamente.
- La API y MySQL corren en la **misma VM**, así que MySQL no necesita
  exponerse fuera de la VM: la API se conecta a `localhost:3306`.
- `10.0.2.2` es la dirección con la que el emulador de Android ve a tu PC.
  Con el reenvío de puerto, esa dirección llega a la VM.

## 2. Base de datos

Motor: **MySQL 8.0.16+ o MariaDB 10.4+** (con versiones anteriores los `CHECK`
no se aplican).

Tabla única `productos`:

| Columna    | Tipo                                 | Reglas                           |
|------------|--------------------------------------|----------------------------------|
| `id`       | `INT AUTO_INCREMENT PRIMARY KEY`     | Lo genera la BD                  |
| `nombre`   | `VARCHAR(120) NOT NULL`              | Obligatorio, no vacío            |
| `cantidad` | `DECIMAL(10,2) NOT NULL DEFAULT 1`   | Mayor que 0, admite decimales (1.5 kg) |
| `unidad`   | `VARCHAR(30) NOT NULL DEFAULT ''`    | Opcional (puede ser `''`)        |
| `estado`   | `ENUM('pendiente','comprado')`       | Por defecto `'pendiente'`        |

Dos scripts, ambos se ejecutan **como root dentro de la VM**:

| Script | Qué hace | Cuándo |
|--------|----------|--------|
| [`backend/schema.sql`](backend/schema.sql) | Crea la base `lista_compras`, la tabla y el usuario `app_compras` (solo puede leer y escribir esa tabla) | Una vez |
| [`backend/datos_ejemplo.sql`](backend/datos_ejemplo.sql) | **Borra todo** y carga 5 productos de ejemplo | Al inicio, y antes de la sustentación para limpiar lo de los ensayos |

```
mysql -u root -p < schema.sql
mysql -u root -p < datos_ejemplo.sql
```

- **Cambia la contraseña** de `app_compras` en `schema.sql` antes de
  ejecutarlo. La API se conecta con ese usuario, no con root.
- En Windows Server, si `mysql` no se reconoce, usa la ruta completa, ej.
  `"C:\Program Files\MySQL\MySQL Server 8.0\bin\mysql.exe"`, o ábrelo desde
  **MySQL Command Line Client** y usa `source C:/ruta/schema.sql`.

## 3. Contrato de la API

Base: `http://<host>:3000/api`. Todo en JSON, UTF-8.

### Objeto `producto`

```json
{
  "id": 1,
  "nombre": "Leche",
  "cantidad": 2,
  "unidad": "litros",
  "estado": "pendiente"
}
```

- `cantidad` debe ir como **número** (`2` o `1.5`). Ojo: muchos drivers de
  MySQL devuelven `DECIMAL` como texto (`"2.00"`). La app lo tolera, pero lo
  correcto es convertirlo a número.
- `estado` es exactamente `"pendiente"` o `"comprado"`, en minúsculas.

### Endpoints

| Método   | Ruta                   | Body                                    | Éxito                         |
|----------|------------------------|-----------------------------------------|-------------------------------|
| `GET`    | `/api/productos`       | —                                       | `200` + array de productos    |
| `GET`    | `/api/productos/{id}`  | —                                       | `200` + producto              |
| `POST`   | `/api/productos`       | `{nombre, cantidad, unidad, estado}`    | `201` + producto creado (con `id`) |
| `PUT`    | `/api/productos/{id}`  | `{nombre, cantidad, unidad, estado}` (los 4 campos) | `200` + producto actualizado |
| `DELETE` | `/api/productos/{id}`  | —                                       | `204` sin cuerpo (o `200`)    |

Detalles importantes:

- **POST y PUT deben devolver el producto completo** como quedó en la BD
  (después del `INSERT`/`UPDATE`, haz un `SELECT` por id). La app usa esa
  respuesta para actualizar la pantalla.
- **PUT reemplaza los 4 campos.** Marcar como comprado es un PUT con
  `"estado": "comprado"` y los demás campos iguales. No hace falta PATCH.
- La app envía `Content-Type: application/json`.
- No hace falta CORS: es una app nativa, no un navegador.
- No hay autenticación.

### Validaciones y errores

Errores en el formato `{ "error": "mensaje en español" }`. **La app le muestra
ese mensaje al usuario**, así que escríbelo legible.

| Caso                                                   | Código |
|--------------------------------------------------------|--------|
| `nombre` falta, vacío o > 120 caracteres               | `400`  |
| `cantidad` falta, no numérica o ≤ 0                    | `400`  |
| `unidad` > 30 caracteres                               | `400`  |
| `estado` distinto de `pendiente`/`comprado`            | `400`  |
| JSON mal formado                                       | `400`  |
| `id` no existe (GET/PUT/DELETE)                        | `404`  |
| Error de BD u otro inesperado                          | `500`  |

Ejemplo: `400 {"error": "El nombre es obligatorio."}`

### Implementación

El lenguaje y el framework son libres: Node.js + Express, Python + Flask o
FastAPI, PHP, C# / ASP.NET, etc. Solo debe cumplir:

1. Escuchar en **`0.0.0.0`** (todas las interfaces), **no** en `127.0.0.1`.
   Si escucha solo en localhost, el emulador no podrá conectarse.
2. Puerto **3000**. Si usas otro, anótalo en la ficha.
3. **Consultas parametrizadas** (`?` / `%s` / `@param`). Nunca concatenes
   strings al armar SQL.
4. Leer el usuario y la contraseña de MySQL de un archivo de configuración o
   de variables de entorno, no dejarlos fijos en el código del repo (`.env`
   ya está en `.gitignore`).
5. Ideal: que la API arranque sola con la VM (servicio `systemd` en Linux,
   servicio de Windows o tarea programada en Windows Server). Así el día de
   la sustentación no se te olvida iniciarla.

## 4. Red de la VM (sin internet)

### En la VM

- **Firewall**, abrir el 3000:
  - Windows Server (PowerShell como administrador):
    ```
    New-NetFirewallRule -DisplayName "API Lista Compras" -Direction Inbound -Protocol TCP -LocalPort 3000 -Action Allow
    ```
  - Linux: `sudo ufw allow 3000/tcp`
- **MySQL no se abre** al exterior; con que la API llegue por localhost basta.

### En el hipervisor (opción A, recomendada: NAT + reenvío de puerto)

- **VirtualBox:** Configuración de la VM → Red → Adaptador 1: **NAT** →
  Avanzado → **Reenvío de puertos** → nueva regla: TCP, puerto anfitrión
  `3000`, puerto invitado `3000`, IPs vacías.
- **VMware Workstation:** Editar → Editor de red virtual → VMnet8 (NAT) →
  Configuración NAT → Agregar: puerto anfitrión `3000` → IP de la VM, puerto `3000`.
- **Hyper-V:** no tiene reenvío de puertos simple; usa la opción B.

Con esto la URL de la app es **`http://10.0.2.2:3000/api`**.

### Opción B: red "solo anfitrión" (host-only)

VirtualBox "Adaptador solo anfitrión" (IPs `192.168.56.x`) o un conmutador
**interno** de Hyper-V con IP fija en la VM. La URL de la app pasa a ser
`http://<IP_DE_LA_VM>:3000/api`.

**Evita el modo puente (bridged):** sin router o sin internet la VM puede
quedarse sin IP.

### Emulador y VM en el mismo PC

El emulador de Android y la VM usan virtualización por hardware al mismo
tiempo. En Windows, si el emulador no arranca o va muy lento con la VM
encendida, activa **Plataforma del hipervisor de Windows** (Panel de control →
Programas → Activar o desactivar características de Windows) y reinicia.
VirtualBox 6.1+ y VMware 16+ funcionan con ella activada. Pruébalo con
tiempo, no el día de la sustentación.

## 5. Probar la API

Desde **tu PC** (no desde la VM), en el **Símbolo del sistema (cmd)**, no en
PowerShell: PowerShell maneja distinto las comillas y los JSON llegan dañados.
Con la opción B, cambia `localhost` por la IP de la VM.

```bat
:: Listar
curl -i http://localhost:3000/api/productos

:: Crear
curl -i -X POST http://localhost:3000/api/productos -H "Content-Type: application/json" -d "{\"nombre\":\"Queso\",\"cantidad\":1,\"unidad\":\"kg\",\"estado\":\"pendiente\"}"

:: Marcar comprado (reemplaza 6 por el id que devolvió "Crear")
curl -i -X PUT http://localhost:3000/api/productos/6 -H "Content-Type: application/json" -d "{\"nombre\":\"Queso\",\"cantidad\":1,\"unidad\":\"kg\",\"estado\":\"comprado\"}"

:: Eliminar
curl -i -X DELETE http://localhost:3000/api/productos/6

:: Error esperado: 400
curl -i -X POST http://localhost:3000/api/productos -H "Content-Type: application/json" -d "{\"nombre\":\"\",\"cantidad\":0}"

:: Error esperado: 404
curl -i http://localhost:3000/api/productos/999
```

`-i` muestra el código HTTP en la primera línea (ej. `HTTP/1.1 201 Created`):
verifica que coincida con la tabla de la sección 3. Si `localhost:3000`
responde desde tu PC, el emulador también llegará por `10.0.2.2:3000`. Para confirmarlo, abre Chrome **dentro del emulador** y
visita `http://10.0.2.2:3000/api/productos`.

## 6. Entregar la ficha al compañero de integración

El compañero de integración **no tiene tu VM**, así que no puede llamar a tu
API. Todo lo que sabe de ella sale de la ficha:

1. Llena [`backend/FICHA_API.md`](backend/FICHA_API.md): URL base, puerto,
   tipo de red, diferencias con el contrato y **la salida real** de cada
   comando de la sección 5.
2. Súbela al repo (commit + push) y avísale.

Él pega tus respuestas reales en las pruebas de la app y ajusta lo necesario.

## 7. Ejecutar la app contra tu VM

Cuando integración avise que subió los cambios:

1. `git pull` (o en Android Studio: **Git → Pull**).
2. Enciende la VM y verifica la API con `curl` (sección 5).
3. En Android Studio, inicia el emulador y dale **Run ▶** (pasos en README.md).
4. Prueba todo: listar, agregar, editar, marcar comprado/pendiente,
   eliminar, y deslizar hacia abajo para recargar.
5. Si algo falla, toma captura de la pantalla de error (muestra el mensaje y
   la URL que usa la app) y envíasela a integración. La tabla de la sección 6
   de [HANDOFF_APP.md](HANDOFF_APP.md) dice qué significa cada error.

**La app no debe necesitar que cambies nada.** La URL y la configuración ya
vienen puestas por integración en `lib/utils/constants.dart`.

## 8. Preparación para la sustentación (sin internet)

Android Studio y Flutter **descargan cosas la primera vez**: la imagen del
emulador, Gradle y las dependencias del proyecto. Sin internet esa primera vez
falla. Por eso:

- [ ] Con internet: instalar todo, crear el emulador y ejecutar la app **al
      menos una vez** con la versión final del repo. Queda todo en caché.
- [ ] Después de cualquier `git pull` que cambie `pubspec.yaml`, volver a
      ejecutar **con internet**.
- [ ] Ensayo: desconectar internet (Wi-Fi apagado o modo avión), encender la
      VM, abrir Android Studio, Run ▶ y hacer la demo completa.

**El día:**

- [ ] VM encendida; MySQL y la API corriendo.
- [ ] `curl http://localhost:3000/api/productos` responde.
- [ ] Datos limpios: ejecuta `datos_ejemplo.sql` para quitar lo que quedó de
      los ensayos.
- [ ] Android Studio abierto, emulador iniciado, app ejecutándose.

**Plan B** si la VM falla en plena sustentación: en
`lib/utils/constants.dart` cambia `kUseMockData` a `true` y dale Run ▶ otra
vez. La app arranca con datos de prueba y se puede mostrar el front completo.
