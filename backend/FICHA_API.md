# Ficha de la API real

> **La llena el compañero de BD/API** cuando su API ya funcione en la VM, y la
> sube al repo. **La usa el compañero de integración** para conectar la app
> sin tener acceso a la VM. Si algo cambia después, actualizar esta ficha y
> avisar.

## Datos de conexión

| Dato                                      | Valor                     |
|-------------------------------------------|---------------------------|
| Sistema operativo de la VM                | _ej. Ubuntu Server 24.04_ |
| Hipervisor                                | _ej. VirtualBox 7_        |
| Red de la VM (A: NAT + reenvío / B: solo anfitrión) | _A_             |
| Puerto de la API                          | _3000_                    |
| IP de la VM (solo si es opción B)         | _—_                       |
| **URL base que debe usar la app**         | _`http://10.0.2.2:3000/api`_ |
| Lenguaje / framework de la API            | _ej. Node.js + Express_   |
| Motor de BD y versión                     | _ej. MySQL 8.0.36_        |

## Diferencias con el contrato

Cualquier cosa que **no** sea igual a lo de HANDOFF_BACKEND.md, sección 3
(nombres de campos, rutas, códigos de respuesta, formato de errores...). Si
todo es igual, escribir "Ninguna".

- _Ninguna_

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
