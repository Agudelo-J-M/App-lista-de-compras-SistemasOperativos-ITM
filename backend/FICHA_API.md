# Ficha de la API real

> **La llena el compañero de BD/API** cuando su API ya funcione en la VM, y la
> sube al repo. **La usa el compañero de integración** para conectar la app
> sin tener acceso a la VM. Si algo cambia después, actualizar esta ficha y
> avisar.

## Datos de conexión

Lo que ya se sabe por el código de `backend/api/` viene lleno. Completa los
campos marcados con ✏️ (`lsb_release -d`, `mysql --version`, `node --version`
en la VM).

| Dato                                      | Valor                     |
|-------------------------------------------|---------------------------|
| ✏️ Sistema operativo de la VM             | _ej. Ubuntu Server 24.04_ |
| ✏️ Versión de VirtualBox                  | _ej. 7.1_                 |
| Red de la VM                              | NAT + reenvío de puerto 3000 → 3000 |
| Puerto de la API                          | 3000                      |
| **URL base que debe usar la app**         | `http://10.0.2.2:3000/api` |
| Lenguaje / framework de la API            | Node.js + Express + mysql2 (`backend/api/`) |
| ✏️ Versión de Node.js                     | _ej. v20.18.0_            |
| ✏️ Motor de BD y versión                  | _ej. MySQL 8.0.40_        |

## Diferencias con el contrato

Cualquier cosa que **no** sea igual a lo de HANDOFF_BACKEND.md, sección 3
(nombres de campos, rutas, códigos de respuesta, formato de errores...). Si
todo es igual, escribir "Ninguna".

- Ninguna. Extra que no afecta a la app: `GET /api/salud` → `{"ok": true}`.

## Respuestas reales

Copiar la salida **real** de estos comandos, ejecutados desde el PC anfitrión
(ver HANDOFF_BACKEND.md, sección 5). Incluir el código HTTP (`curl -i` lo
muestra en la primera línea).

### GET /api/productos

```
(pegar aquí)
```

### POST /api/productos

```
(pegar aquí)
```

### PUT /api/productos/{id}

```
(pegar aquí)
```

### DELETE /api/productos/{id}

```
(pegar aquí)
```

### POST con nombre vacío (error 400)

```
(pegar aquí)
```

### GET /api/productos/999 (error 404)

```
(pegar aquí)
```
