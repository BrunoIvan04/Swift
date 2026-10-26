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

### Versión 1.1

- Agregar, completar y eliminar tareas (deslizar a la izquierda → «Eliminar»).
- Pantalla de detalle para editar el título y asignar una fecha límite (deslizar a la derecha → «Editar», o botón ⓘ). Las vencidas se ven en rojo.
- Filtro Todas / Pendientes / Completadas y contador de pendientes.
- Persistencia con UserDefaults + Codable y migración de los datos de la versión 1.0.
- Dynamic Type, modo oscuro y VoiceOver.

### Evidencias

- **Video demostrativo (1 min 51 s):** [`evidencias/demo_app_funcional.mp4`](evidencias/demo_app_funcional.mp4)
- **Pruebas unitarias (15/15):** [`evidencias/resultado-pruebas-unitarias.txt`](evidencias/resultado-pruebas-unitarias.txt)
- **Pruebas de interfaz XCUITest (2/2):** flujo principal, y filtro + detalle + fecha límite: [`evidencias/resultado-pruebas-ui.txt`](evidencias/resultado-pruebas-ui.txt)
- **Capturas del simulador:** carpeta [`evidencias/`](evidencias/) (ui_01 a ui_10 y 01 a 05)
- **Diseño editable:** [`docs/diseno/`](docs/diseno/) · **Documentos de la Fase III:** [`docs/`](docs/)
