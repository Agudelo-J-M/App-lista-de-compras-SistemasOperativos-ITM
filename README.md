# Lista de Compras — App Flutter (Sistemas Operativos, ITM)

App Android de lista de compras (CRUD de productos) que consume una API REST
alojada en una máquina virtual. Se ejecuta desde **Android Studio**, en el
**emulador de Android**.

## Roles y flujo de trabajo (igual en todos los documentos)

| Quién                        | Responsabilidad                                                        | Su documento |
|------------------------------|------------------------------------------------------------------------|--------------|
| **Mauro**                    | App Flutter: pantallas, lógica y cliente HTTP. **Ya está hecha.**      | —            |
| **Compañero de BD/API**      | Base de datos + API en una VM en su PC. Al final ejecuta la app desde Android Studio, en el emulador, y presenta. | [HANDOFF_BACKEND.md](HANDOFF_BACKEND.md) |
| **Compañero de integración** | Ajusta la app en el repo para que se conecte a la API real del compañero de BD/API. | [HANDOFF_APP.md](HANDOFF_APP.md) |

1. **BD/API** construye y prueba la API en su VM, llena
   [`backend/FICHA_API.md`](backend/FICHA_API.md) y la sube al repo.
2. **Integración** lee la ficha, ajusta la app, la prueba y sube los cambios al repo.
3. **BD/API** hace `git pull`, abre el proyecto en **Android Studio** y lo
   ejecuta en el **emulador** contra su VM. Si algo falla, se lo reporta a
   integración y se repiten los pasos 2 y 3.
4. **Sustentación:** BD/API presenta desde su PC, **sin internet**. La app corre
   desde Android Studio en el emulador y se conecta a la VM local.

---

## Ejecutar la app en Android Studio (paso a paso)

Para Windows. **Haz todo esto con internet**: la primera vez se descargan el
SDK, la imagen del emulador y las dependencias. Después funciona sin conexión.

**Antes de empezar:** el repo es de Mauro en GitHub. Pídele que te agregue
como colaborador (Settings → Collaborators) para poder clonar y subir cambios.
Versión con la que se desarrolló: **Flutter 3.50.1 (stable)**. Usa esa o una
más nueva.

### 1. Instalar Android Studio

1. Descarga Android Studio desde https://developer.android.com/studio e
   instálalo con las opciones por defecto.
2. Ábrelo y deja que el asistente inicial (*Setup Wizard*) descargue el
   Android SDK.

### 2. Instalar el Flutter SDK

1. Descarga el `.zip` más reciente del canal **stable** para Windows desde
   https://docs.flutter.dev/install/archive.
2. Descomprímelo en `C:\src\flutter`. Evita rutas con espacios y
   `C:\Program Files`.
3. Agrega `C:\src\flutter\bin` al PATH: menú Inicio → escribe *"variables de
   entorno"* → **Editar las variables de entorno de esta cuenta** → `Path` →
   **Editar** → **Nuevo** → `C:\src\flutter\bin` → Aceptar.
4. Abre una terminal **nueva** (PowerShell) y verifica:
   ```
   flutter --version
   ```

### 3. Completar el Android SDK y aceptar licencias

1. En Android Studio: **More Actions → SDK Manager** (o, con un proyecto
   abierto, **File → Settings → Languages & Frameworks → Android SDK**).
2. Pestaña **SDK Tools** → marca **Android SDK Command-line Tools (latest)** →
   **Apply** → OK.
3. En PowerShell:
   ```
   flutter doctor --android-licenses
   ```
   Responde `y` a todo.
4. Verifica con `flutter doctor`. **Flutter** y **Android toolchain** deben
   salir con ✓. Lo de Chrome y Visual Studio se puede ignorar: no se usan.

### 4. Instalar el plugin de Flutter

1. En Android Studio: **More Actions → Plugins** (o **File → Settings →
   Plugins**).
2. Pestaña **Marketplace** → busca **Flutter** → **Install**. Acepta también
   instalar **Dart**.
3. Reinicia Android Studio.

### 5. Abrir el proyecto

1. Clona el repo. En la pantalla de bienvenida de Android Studio: **Clone
   Repository** (o **File → New → Project from Version Control**) → URL:
   ```
   https://github.com/Agudelo-J-M/App-lista-de-compras-SistemasOperativos-ITM.git
   ```
   → **Clone**. Si ya lo tienes clonado: **Open** → selecciona la carpeta del
   proyecto (la que contiene `pubspec.yaml`).
2. Si pide la ruta del Flutter SDK: **File → Settings → Languages &
   Frameworks → Flutter → Flutter SDK path** → `C:\src\flutter` → OK.
3. Cuando aparezca el aviso **"Pub get has not been run"**, haz clic en
   **Get dependencies**. O en la terminal de Android Studio (pestaña
   **Terminal**, abajo):
   ```
   flutter pub get
   ```

### 6. Crear el emulador

1. Abre **Device Manager**: icono de teléfono en la barra lateral derecha, o
   **View → Tool Windows → Device Manager**.
2. **+ → Create Virtual Device**.
3. Elige un teléfono (ej. **Pixel 8**) → **Next**.
4. Elige una imagen del sistema reciente con **x86_64**, ej. **API 35**. Si
   tiene icono de descarga, haz clic para descargarla (~1.5 GB) → **Next** →
   **Finish**.
5. Inicia el emulador con **▶** en Device Manager. La primera vez tarda en
   arrancar.

### 7. Ejecutar la app

1. En la barra superior, en el selector de dispositivos, elige el emulador
   (ej. *Pixel 8 API 35*). En el selector de configuración debe estar
   **main.dart**.
2. Clic en **Run ▶** (o `Shift+F10`).
3. **La primera compilación tarda varios minutos** (descarga Gradle y
   componentes de Android). Las siguientes son rápidas.
4. La app abre con la lista de compras. Si dice **DEMO** debajo del título,
   está usando datos de prueba, no la API.

Mientras la app corre, al guardar cambios en el código se aplican al instante
(*hot reload*). Si cambias `lib/utils/constants.dart`, usa **Hot Restart**
(icono de flecha circular en la barra de Run) o detén la app y dale Run ▶ de
nuevo.

### Problemas comunes

| Problema                                       | Solución                                                     |
|------------------------------------------------|--------------------------------------------------------------|
| No aparece el botón Run ni "main.dart"         | Falta el plugin de Flutter (paso 4) o la ruta del SDK (paso 5.2) |
| "No devices" en el selector                    | Inicia el emulador desde Device Manager y espera a que arranque |
| `flutter` no se reconoce en la terminal        | Revisa el PATH (paso 2.3) y abre una terminal nueva          |
| `Android license status unknown`               | Paso 3: instalar Command-line Tools y aceptar licencias      |
| Gradle falla sin internet                      | La primera compilación necesita internet; ejecútala una vez conectado |
| El emulador no arranca o va muy lento con la VM encendida | Activa **Plataforma del hipervisor de Windows** (ver HANDOFF_BACKEND.md, sección 4) |
| La app muestra "No se pudo conectar con el servidor" | La API no responde en la URL que muestra la pantalla: revisa HANDOFF_BACKEND.md, secciones 4 y 5 |

---

## Configuración

Todo está en [lib/utils/constants.dart](lib/utils/constants.dart):

| Constante      | Qué hace                                             | Por defecto                 |
|----------------|------------------------------------------------------|-----------------------------|
| `kUseMockData` | `true` = datos de prueba en memoria, sin backend     | `true` (hasta que integración lo cambie) |
| `kApiBaseUrl`  | URL base de la API                                   | `http://10.0.2.2:3000/api`  |

`10.0.2.2` es la dirección con la que el emulador ve al PC donde corre. No
usar `localhost`: dentro del emulador apunta al propio emulador.

## Pruebas

```
flutter test
```

`test/api_repository_test.dart` prueba el cliente HTTP con un servidor
simulado, sin necesitar la VM (ver HANDOFF_APP.md, sección 2).

## Estructura

```
lib/
  main.dart                                  Inyección del repositorio según kUseMockData
  utils/constants.dart                       Configuración de conexión
  models/shopping_item.dart                  Modelo + conversión a/desde el JSON de la API
  repositories/shopping_repository.dart      Interfaz
  repositories/api_shopping_repository.dart  Implementación HTTP real
  repositories/mock_shopping_repository.dart Implementación en memoria (datos de prueba)
  providers/shopping_provider.dart           Lógica de negocio (ChangeNotifier)
  screens/                                   Lista y formulario (solo leen el provider)
backend/
  schema.sql                                 Script de la base de datos (MySQL/MariaDB)
  datos_ejemplo.sql                          Borra todo y carga 5 productos de ejemplo
  FICHA_API.md                               Datos de la API real (la llena BD/API)
test/                                        Pruebas
```
