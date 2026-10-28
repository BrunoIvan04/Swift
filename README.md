Objetivo: Crear una aplicación de lista de tareas que permita al usuario agregar tareas, marcar tareas como completadas y eliminar tareas no deseadas. 
Requisitos previos: 

Conocimiento básico de Swift y Xcode. 
Acceso a un entorno de desarrollo Swift (preferiblemente Xcode). 
Instrucciones: 

Creación de la interfaz de usuario: 
Crea una interfaz de usuario simple en Xcode que incluya una tabla para mostrar la lista de tareas y un campo de texto con un botón para agregar nuevas tareas. 
Asegúrate de que la tabla tenga una celda personalizada para mostrar las tareas. 
Definición de una estructura de datos para las tareas: 
Define una estructura de datos para representar una tarea, que debe incluir un título y un indicador de estado (completada o no completada). 
Almacenamiento de tareas: 
Utiliza una matriz (Array) en Swift para almacenar las tareas en memoria. 
Agregar tareas: 
Implementa la lógica para agregar nuevas tareas cuando el usuario escriba una tarea en el campo de texto y haga clic en el botón "Agregar". 
Mostrar tareas: 
Muestra la lista de tareas en la tabla. 
Las tareas completadas deben mostrarse con un estilo diferente (por ejemplo, tachadas o en un color diferente). 
Marcar tareas como completadas: 
Permite a los usuarios marcar las tareas como completadas tocando la celda de la tarea en la tabla. 
Actualiza la representación visual de las tareas completadas en la tabla. 
7. Eliminar tareas: 
Agrega la capacidad de eliminar tareas al deslizar una celda hacia la izquierda y tocar un botón de eliminación. 
Opcional: persistencia de datos. 
Si deseas llevar la aplicación al siguiente nivel, puedes implementar la persistencia de datos para que las tareas se guarden entre sesiones de la aplicación. 
Prueba y depuración: 
Prueba la aplicación para asegurarte de que todas las funciones trabajen correctamente. 
Realiza pruebas adicionales para encontrar y solucionar posibles errores. 

---

## Evidencias del proyecto integrador (Fase III)

Las pruebas y capturas se generan automáticamente en una Mac de GitHub Actions (`.github/workflows/ios.yml`), en un simulador de iPhone 17 con iOS 26.2.

### Versión 2.0 (con Firebase)

- **Cuenta:** crear cuenta (nombre, correo y contraseña), iniciar y cerrar sesión con Firebase Authentication. La sesión se recuerda al reabrir la app.
- **Nube:** las tareas viven en Cloud Firestore (`users/{uid}/tasks`) y se actualizan en tiempo real. Las que quedaron guardadas en el teléfono (versiones 1.x) se suben solas en el primer inicio de sesión.
- **Estados:** indicador de carga, lista vacía y error de conexión con «Reintentar».
- Agregar, completar, eliminar (deslizar → «Eliminar»), detalle con fecha límite (deslizar a la derecha o botón ⓘ), filtro Todas / Pendientes / Completadas y contador.
- Dynamic Type, modo oscuro y VoiceOver.
- **Seguridad:** reglas de Firestore en [`firestore.rules`](firestore.rules): cada usuario solo ve sus datos.

### Proyecto guiado: Restaurant

El proyecto guiado de la Fase III está en [`Restaurant/`](Restaurant/), con su servidor de prueba y sus capturas en [`Restaurant/evidencias/`](Restaurant/evidencias/).

### Configurar Firebase

El repositorio es público, así que **no incluye** el `GoogleService-Info.plist` real (está en `.gitignore`).

- **En una Mac:** descarga el archivo desde la consola de Firebase (proyecto `mis-tareas`, app de iOS `com.brunoivan.SwiftTodoApp`) y colócalo en `SwiftTodoApp/GoogleService-Info.plist`.
- **En CI:** `ci/write_demo_firebase_config.sh` escribe una configuración de prueba (`demo-mis-tareas`). Con un proyecto `demo-*`, la app se conecta sola al emulador de Firebase, así que las pruebas nunca tocan datos reales.
- **Opcional:** si guardas el contenido del archivo real como secreto del repositorio `GOOGLE_SERVICE_INFO_PLIST`, CI también comprueba que la app compila con el proyecto real.

### Evidencias (GitHub Actions, macOS 15, iPhone 17 con iOS 26.2)

- **Video demostrativo (2 min 27 s):** [`evidencias/demo_app_funcional.mp4`](evidencias/demo_app_funcional.mp4)
- **Pruebas unitarias (18/18):** [`evidencias/resultado-pruebas-unitarias.txt`](evidencias/resultado-pruebas-unitarias.txt)
- **Pruebas de reglas de Firestore (6/6):** [`evidencias/resultado-pruebas-reglas.txt`](evidencias/resultado-pruebas-reglas.txt)
- **Pruebas de interfaz XCUITest (4/4):** flujo principal; filtro y detalle; crear cuenta, salir y volver a entrar; error de conexión y «Reintentar». Ver [`evidencias/resultado-pruebas-ui.txt`](evidencias/resultado-pruebas-ui.txt)
- **Datos guardados en el emulador:** [`evidencias/firestore_tareas_cuenta_demo.json`](evidencias/firestore_tareas_cuenta_demo.json) y [`evidencias/auth_cuentas_emulador.json`](evidencias/auth_cuentas_emulador.json)
- **Capturas del simulador:** carpeta [`evidencias/`](evidencias/) (ui_01 a ui_16 y 01 a 05)
- **Diseño editable:** [`docs/diseno/`](docs/diseno/) · **Documentos de la Fase III:** [`docs/`](docs/)
