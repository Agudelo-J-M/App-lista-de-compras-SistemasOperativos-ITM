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

**La API ya está escrita** (Node.js + Express, en [`backend/api/`](backend/api/)).
Lo que falta es montarla en la VM. Los comandos exactos, paso a paso, están en
**[backend/README.md](backend/README.md)**. Este documento explica el qué y
el porqué: contrato, red, pruebas y el día de la sustentación.

Si algo de aquí no se puede cumplir (otro puerto, otra forma de un campo,
etc.), anótalo en `backend/FICHA_API.md` en "Diferencias con el contrato" y
avísale al compañero de integración.

## Resumen de tareas

- [ ] 1. Crear la VM Ubuntu en VirtualBox con red NAT ([backend/README.md](backend/README.md), pasos 1–3).
- [ ] 2. Instalar MySQL, cargar `schema.sql` y `datos_ejemplo.sql`, y cambiar la clave de `app_compras` con `ALTER USER` (paso 4).
- [ ] 3. Instalar la API de `backend/api/` y dejarla como servicio (pasos 5–6).
- [ ] 4. Abrir el puerto 3000 en el firewall y crear el reenvío de puerto 3000 → 3000 en VirtualBox (paso 7).
- [ ] 5. Probar todos los endpoints desde el PC físico (sección 5 de este documento).
- [ ] 6. Llenar `backend/FICHA_API.md` con las respuestas reales y subirla al repo (sección 6).
- [ ] 7. **Con internet**, instalar Android Studio y Flutter **en el PC físico** y ejecutar la app una vez (README.md).
- [ ] 8. Cuando integración avise: `git pull`, ejecutar la app contra la VM y reportar errores (sección 7).
- [ ] 9. Ensayar la sustentación completa **sin internet** (sección 8).

---

## 1. Arquitectura

```
Tu PC (el día de la sustentación, sin internet)

  Android Studio
  └─ Emulador Android (AVD)                    VM Ubuntu (VirtualBox)
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
- **Una sola VM.** Android Studio y el emulador corren en el PC físico, no en
  una VM.

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
sudo mysql < schema.sql
sudo mysql < datos_ejemplo.sql
```

- La API se conecta con el usuario `app_compras`, no con root. `schema.sql`
  lo crea con una clave provisional: **cámbiala con `ALTER USER`** después de
  ejecutarlo ([backend/README.md](backend/README.md), paso 4) y **no editando
  el script**, para que la clave real nunca termine subida al repo.

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
| `cantidad` falta, no numérica, ≤ 0 o con más de 2 decimales | `400`  |
| `unidad` > 30 caracteres                               | `400`  |
| `estado` distinto de `pendiente`/`comprado`            | `400`  |
| `estado` falta en un PUT (en POST, si falta, queda `pendiente`) | `400`  |
| `id` no es un entero positivo (ej. `abc`)              | `400`  |
| JSON mal formado                                       | `400`  |
| `id` no existe (GET/PUT/DELETE)                        | `404`  |
| Error de BD u otro inesperado                          | `500`  |

Ejemplo: `400 {"error": "El nombre es obligatorio."}`

### Implementación

Ya está hecha en [`backend/api/`](backend/api/), con Node.js + Express +
mysql2, y cumple todo lo anterior:

| Archivo | Qué hace |
|---------|----------|
| `server.js` | Arranca la API en `0.0.0.0:3000` (valores de `.env`) |
| `app.js` | Rutas, validaciones y mensajes de error |
| `repository.js` | Consultas SQL, todas parametrizadas (`?`) |
| `db.js` | Conexión a MySQL; devuelve `cantidad` como número |
| `.env.example` | Plantilla de configuración. Se copia a `.env`, que no se sube al repo |
| `lista-compras-api.service` | Servicio `systemd`: la API arranca sola con la VM |
| `test/api.test.js` | Pruebas de los endpoints, sin necesitar MySQL (`npm test`) |

Además del contrato tiene `GET /api/salud`, que responde `{"ok": true}`:
sirve para comprobar que la API está viva sin tocar la BD.

Si cambias la API, mantén estas reglas: escuchar en **`0.0.0.0`** (si escucha
solo en `127.0.0.1`, el emulador no llega), puerto **3000**, consultas
**parametrizadas** y credenciales solo en `.env`.

## 4. Red de la VM (sin internet)

La VM usa la red **NAT** de VirtualBox, con un **reenvío de puerto**: lo que
llega al puerto 3000 del PC físico se pasa al puerto 3000 de la VM. El
emulador llama a `10.0.2.2:3000`, que es el PC físico, y de ahí llega a la
API. Con esto la URL de la app es **`http://10.0.2.2:3000/api`** y no
depende de ninguna IP, así que funciona igual sin internet ni router.

Dos cosas que configurar (comandos en [backend/README.md](backend/README.md), paso 7):

1. **Firewall de la VM:** abrir el 3000 (`sudo ufw allow 3000/tcp`). **El
   3306 de MySQL no se abre:** la API llega por localhost.
2. **VirtualBox:** Configuración → Red → Adaptador 1 (**NAT**) → Avanzado →
   **Reenvío de puertos** → regla TCP, puerto anfitrión `3000`, puerto
   invitado `3000`, IPs vacías.

No uses el modo **puente (bridged)**: sin router ni internet la VM puede
quedarse sin IP.

### Emulador y VM en el mismo PC

El emulador de Android y la VM usan virtualización por hardware al mismo
tiempo. En Windows, si el emulador no arranca o va muy lento con la VM
encendida, activa **Plataforma del hipervisor de Windows** (Panel de control →
Programas → Activar o desactivar características de Windows) y reinicia.
VirtualBox 6.1+ y VMware 16+ funcionan con ella activada. Pruébalo con
tiempo, no el día de la sustentación.

## 5. Probar la API

Desde **tu PC físico** (no desde la VM), en el **Símbolo del sistema (cmd)**,
no en PowerShell: PowerShell maneja distinto las comillas y los JSON llegan
dañados. `localhost:3000` llega a la VM gracias al reenvío de puerto.

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

:: Error esperado: 400 (PUT sin estado)
curl -i -X PUT http://localhost:3000/api/productos/1 -H "Content-Type: application/json" -d "{\"nombre\":\"Leche\",\"cantidad\":2,\"unidad\":\"litros\"}"

:: Error esperado: 404
curl -i http://localhost:3000/api/productos/999
```

`-i` muestra el código HTTP en la primera línea (ej. `HTTP/1.1 201 Created`):
verifica que coincida con la tabla de la sección 3. Si `localhost:3000`
responde desde tu PC, el emulador también llegará por `10.0.2.2:3000`. Para
confirmarlo, abre Chrome **dentro del emulador** y visita
`http://10.0.2.2:3000/api/productos`.

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

- [ ] VM encendida; MySQL y la API corriendo (`systemctl status mysql lista-compras-api`).
- [ ] `curl http://localhost:3000/api/productos` responde.
- [ ] Datos limpios: en la VM, `sudo mysql < /opt/lista-compras/backend/datos_ejemplo.sql`
      para quitar lo que quedó de los ensayos.
- [ ] Android Studio abierto, emulador iniciado, app ejecutándose.

**Plan B** si la VM falla en plena sustentación: en
`lib/utils/constants.dart` cambia `kUseMockData` a `true` y dale Run ▶ otra
vez. La app arranca con datos de prueba y se puede mostrar el front completo.
