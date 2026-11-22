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
/// - VM en NAT con reenvío de puerto (recomendado): `http://10.0.2.2:<PUERTO>/api`.
///   `10.0.2.2` es la dirección con la que el emulador ve al PC anfitrión, así
///   que la URL no cambia aunque cambie la IP de la VM o del PC.
/// - VM en red "solo anfitrión" (host-only): `http://<IP_DE_LA_VM>:<PUERTO>/api`,
///   ej. `http://192.168.56.101:3000/api` en VirtualBox.
const String kApiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://10.0.2.2:3000/api', // TODO: confirmar puerto con backend
);

/// Tiempo máximo de espera por petición HTTP.
const Duration kRequestTimeout = Duration(seconds: 10);
