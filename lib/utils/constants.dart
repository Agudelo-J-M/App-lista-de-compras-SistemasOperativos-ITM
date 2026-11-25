// Configuración de conexión. ESTE es el único archivo que hay que tocar
// para conectar la app con el backend.
//
// Escenario de la sustentación (sin internet, todo en el PC del presentador):
//
//   [Emulador Android] --10.0.2.2--> [PC anfitrión] --reenvío de puerto--> [VM con API + BD]
//
// Red de la VM: HANDOFF_BACKEND.md, sección 4. Quién y cómo cambia estos
// valores: HANDOFF_APP.md, sección 4. También se pueden sobrescribir al
// compilar sin editar este archivo:
//   flutter run --dart-define=USE_MOCK=false --dart-define=API_BASE_URL=http://10.0.2.2:3000/api

/// `true`  → usa datos de prueba en memoria (no necesita backend).
/// `false` → usa la API real en [kApiBaseUrl].
const bool kUseMockData = bool.fromEnvironment('USE_MOCK', defaultValue: true);

/// URL base de la API (sin "/" al final).
///
/// La VM usa NAT con reenvío del puerto 3000 (backend/README.md, paso 7).
/// `10.0.2.2` es la dirección con la que el emulador ve al PC físico, así que
/// la URL no depende de ninguna IP. Puerto 3000 confirmado por la API
/// (backend/api/.env.example).
const String kApiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://10.0.2.2:3000/api',
);

/// Tiempo máximo de espera por petición HTTP.
const Duration kRequestTimeout = Duration(seconds: 10);
