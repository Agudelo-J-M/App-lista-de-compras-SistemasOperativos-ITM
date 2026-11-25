# Handoff para el compañero de integración — conectar la app a la API

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

**Este documento es para ti, compañero de integración.**

## Qué ya está hecho

La app ya tiene el cliente HTTP completo, escrito según el contrato de
[HANDOFF_BACKEND.md](HANDOFF_BACKEND.md), sección 3. Hoy corre con datos de
prueba en memoria (`kUseMockData = true`). Si la API del compañero cumple el
contrato al pie de la letra, tu trabajo se reduce a cambiar **dos líneas**.
Si se desvía en algo, aquí está dónde ajustarlo.

**La API del compañero ya está en el repo**, en [`backend/api/`](backend/api/)
(Node.js + Express). Se revisó contra el contrato y lo cumple, en el puerto
3000. Puedes leer `backend/api/app.js` para ver exactamente qué responde cada
endpoint. Lo único que todavía falta de su parte son las respuestas reales en
`backend/FICHA_API.md`.

## Resumen de tareas

- [ ] 1. Preparar tu entorno y ejecutar la app con datos de prueba (README.md).
- [ ] 2. Leer `backend/FICHA_API.md` cuando el compañero de BD/API la suba.
- [ ] 3. Pegar las respuestas reales en `test/api_repository_test.dart` y correr las pruebas.
- [ ] 4. Si hay diferencias con el contrato, ajustar el modelo o las rutas.
- [ ] 5. Configurar la URL y apagar los datos de prueba en `lib/utils/constants.dart`.
- [ ] 6. Subir los cambios al repo y avisar al compañero de BD/API.
- [ ] 7. Corregir lo que él reporte al probar contra la VM.

## 1. Mapa del código

Solo vas a tocar archivos marcados con ✏️.

| Archivo                                         | Qué hace                                              |
|-------------------------------------------------|-------------------------------------------------------|
| ✏️ `lib/utils/constants.dart`                   | `kUseMockData` y `kApiBaseUrl`: **la configuración**  |
| ✏️ `lib/models/shopping_item.dart`              | `fromJson` / `toJson`: traduce el JSON de la API      |
| ✏️ `lib/repositories/api_shopping_repository.dart` | Rutas HTTP y códigos de respuesta aceptados        |
| ✏️ `test/api_repository_test.dart`              | Pruebas del cliente HTTP con respuestas simuladas     |
| `lib/repositories/mock_shopping_repository.dart`| Datos de prueba (no tocar)                            |
| `lib/providers/shopping_provider.dart`          | Lógica de negocio (no tocar)                          |
| `lib/screens/`                                  | Pantallas (no tocar)                                  |
| `lib/main.dart`                                 | Elige el repositorio según `kUseMockData` (no tocar)  |

Por la arquitectura (patrón Repository + Provider), **las pantallas y la
lógica no saben si hablan con la API o con datos de prueba**. Por eso
conectar la API no requiere tocar nada fuera de esos archivos.

## 2. Probar sin la VM

Tú no tienes la VM del compañero, así que no puedes llamar a su API desde tu
PC. (Si quieres probar en vivo, puedes correr la API en tu PC: Node.js +
MySQL locales y los pasos 4–5 de [backend/README.md](backend/README.md).
Es opcional.) En su lugar, `test/api_repository_test.dart` simula el servidor con
`MockClient` y comprueba que la app:

- lea la lista, el producto creado y el actualizado;
- envíe el body correcto en POST y PUT;
- acepte `204` en DELETE;
- muestre el mensaje de `{"error": ...}` en un 400 y detecte el 404.

**Qué hacer:**

1. Abre `test/api_repository_test.dart`. Arriba están las constantes
   `respuestaListar`, `respuestaCrear`, `respuestaActualizar` y
   `respuestaError400`.
2. Reemplaza su contenido por el JSON **real** de `backend/FICHA_API.md`
   (solo el cuerpo, sin las cabeceras HTTP).
3. Si un código de respuesta real es distinto (ej. POST devuelve `200` en vez
   de `201`), cámbialo también en la clase `ServidorFalso`.
4. Ejecuta las pruebas: en Android Studio, clic derecho sobre la carpeta
   `test` → **Run 'tests in test'**. O en la terminal:
   ```
   flutter test
   ```

Si todas pasan con las respuestas reales, la app va a entender la API.

> Si están juntos en la misma red, o en el mismo PC, también pueden probar
> directo contra la VM. Pero las pruebas con `MockClient` quedan en el repo y
> sirven para demostrar en la sustentación que la integración está probada.

## 3. Si la API no cumple el contrato

Lo ideal es que el compañero de BD/API corrija su API para que cumpla el
contrato. Si deciden adaptarse desde la app, estos son los puntos:

| Diferencia                                   | Dónde se ajusta                                                    |
|----------------------------------------------|--------------------------------------------------------------------|
| Otro nombre de campo (ej. `producto` en vez de `nombre`) | `fromJson` y `toJson` en `shopping_item.dart`          |
| `estado` con otros valores (ej. `true/false`, `0/1`) | `fromJson` y `toJson`, y las constantes `estadoPendiente` / `estadoComprado` |
| Otra ruta (ej. `/api/producto` en singular)  | Las llamadas a `_uri(...)` en `api_shopping_repository.dart`       |
| Otro código de éxito (ej. POST → `200`)      | La lista que recibe `_expect(...)` en cada método. POST ya acepta `200` y `201`; DELETE acepta `200` y `204` |
| La lista viene envuelta (ej. `{"data": [...]}`) | `getItems()`: leer `data['data']` antes de convertir             |
| Errores con otra clave (ej. `{"message": ...}`) | `_expect(...)`: leer esa clave en lugar de `error`              |
| POST/PUT no devuelven el producto            | Pedirle al compañero que lo devuelva. Si no puede, en `createItem`/`updateItem` construir el resultado a partir de lo enviado (y en POST obtener el `id` de alguna forma) |

Después de cada ajuste, actualiza las pruebas y vuelve a correr `flutter test`.

## 4. Configurar la conexión

En `lib/utils/constants.dart`:

```dart
const bool kUseMockData = bool.fromEnvironment('USE_MOCK', defaultValue: false); // antes: true
const String kApiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://10.0.2.2:3000/api', // la "URL base" de FICHA_API.md
);
```

- La URL es `http://10.0.2.2:3000/api` (ya es el valor por defecto; solo
  cámbiala si la ficha dice otra cosa). La VM usa NAT con reenvío del puerto
  3000, y `10.0.2.2` es la forma en que el emulador ve al PC donde corre, así
  que funciona aunque cambien las IPs.
- **No uses `localhost` ni `127.0.0.1`:** dentro del emulador apuntan al
  propio emulador, no al PC.

Cambia el **valor por defecto** (`defaultValue`), no los nombres. Así el
compañero de BD/API solo tiene que dar clic en Run en Android Studio, sin
configurar nada más.

Ya está habilitado en `android/app/src/main/AndroidManifest.xml` el tráfico
`http://` sin cifrar y el permiso de internet. No hace falta tocarlo.

## 5. Entregar

1. `flutter test`: todo en verde.
2. `flutter analyze`: sin errores. Los avisos `info` sobre
   `material.dart` son normales en Flutter 3.50 y se pueden ignorar.
3. Ejecuta la app una vez en tu emulador o celular. Con `kUseMockData = false`
   y sin la VM debe mostrar el error de conexión **con la URL configurada**:
   eso confirma que está intentando llegar a la API.
4. Sube los cambios al repo (commit + push) y avisa al compañero de BD/API
   para que haga `git pull` y pruebe.

## 6. Cuando el compañero reporte errores

La pantalla de error muestra el mensaje y la URL. Pídele una captura.

| Lo que ve el compañero                  | Causa probable                                  | Quién lo arregla |
|-----------------------------------------|-------------------------------------------------|------------------|
| "No se pudo conectar con el servidor"   | URL o puerto mal, API caída, firewall, falta el reenvío de puerto | Revisar URL (tú); red y API (él) |
| "El servidor no respondió a tiempo"     | VM apagada, IP incorrecta                        | Él               |
| "Error del servidor (500)"              | Falla en la API o la BD                          | Él               |
| "Respuesta inesperada" / "JSON inválido"| El formato no coincide con lo que espera la app | Tú (sección 3) o él |
| La lista carga pero faltan datos o salen vacíos | Nombre de campo distinto                 | Tú (`fromJson`)  |
| Agregar/editar devuelve error 400       | El body que envía la app no es el que espera la API | Tú (`toJson`) o él |
