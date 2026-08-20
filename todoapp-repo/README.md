# To-Do List — UIKit (Develop in Swift Collections)

## Estructura

```
todoapp/
├── Core/                          ← lógica de negocio, sin UIKit (testeable en WSL/Linux)
│   ├── Package.swift
│   ├── Sources/TodoCore/
│   │   ├── Task.swift             ← struct Task (requisito 2)
│   │   └── TaskStore.swift        ← agregar/completar/eliminar/persistencia (requisitos 3,4,6,7,8)
│   └── Tests/TodoCoreTests/
│       └── TaskStoreTests.swift   ← pruebas unitarias (requisito 9)
└── iOS/                           ← capa de interfaz, solo compila en Xcode/macOS
    ├── TaskCell.swift             ← celda personalizada (requisitos 1, 5)
    ├── TaskListViewController.swift ← tabla + textfield + botón (requisitos 1,4,5,6,7)
    ├── UserDefaultsTaskPersistence.swift ← persistencia real (requisito 8)
    └── SceneDelegate.swift        ← arranque sin storyboard
```

La idea de separar `Core` de `iOS` es justamente resolver tu problema de no
tener Mac: **toda la lógica que no depende de UIKit vive en `Core`**, y esa
parte sí la puedes compilar y testear en WSL con el toolchain de Swift para
Linux. La parte de `iOS` (UIKit) solo se puede compilar en Xcode, pero para
esa parte el código ya está escrito y comentado línea por línea, así que la
integración es prácticamente copiar y pegar.

## 1. Probar la lógica en WSL (sin Mac)

Instala el toolchain de Swift para Linux (una sola vez):

```bash
# En tu WSL Ubuntu
sudo apt update
sudo apt install -y binutils git gnupg2 libc6-dev libcurl4-openssl-dev \
  libedit2 libgcc-9-dev libpython3.8 libsqlite3-0 libstdc++-9-dev \
  libxml2-dev libz3-dev pkg-config tzdata zlib1g-dev

# Instala swiftly (gestor de versiones oficial) o descarga el .tar.gz
# de https://www.swift.org/install/linux/ para tu versión de Ubuntu
```

Luego, dentro de `Core/`:

```bash
cd todoapp/Core
swift test
```

Esto compila `Task.swift` y `TaskStore.swift` y corre los 6 tests de
`TaskStoreTests.swift`, que cubren: agregar tarea, ignorar título vacío,
recortar espacios, marcar/desmarcar completada, eliminar, y persistencia.
Si algo en la lógica está mal, lo verás fallar ahí mismo, sin necesitar
un simulador de iOS.

## 2. Integrar la parte de UI en Xcode

1. Crea un proyecto nuevo en Xcode: **App**, interfaz **Storyboard** o
   **SwiftUI** (da igual, la vamos a ignorar), lenguaje **Swift**.
2. Arrastra la carpeta `Core/` completa al proyecto (member of target: tu app).
   Alternativa más "correcta": en Xcode ve a *File → Add Package Dependencies →
   Add Local...* y selecciona la carpeta `Core/` para agregarla como paquete
   Swift local; luego añade `import TodoCore` donde haga falta (ya está en
   los archivos de `iOS/`).
3. Arrastra los 4 archivos de `iOS/` al proyecto.
4. Borra `Main.storyboard` (o si no quieres borrarlo, simplemente ignóralo)
   y en el target, en la pestaña **General → Main Interface**, deja el
   campo vacío.
5. Reemplaza el `SceneDelegate.swift` que Xcode generó por el que está en
   `iOS/SceneDelegate.swift`.
6. Corre en el simulador (Cmd+R). Ahí sí ya necesitas Xcode/Mac para ver
   la interfaz gráfica final, pero para ese punto la lógica ya la
   verificaste con `swift test`.

## Checklist de requisitos del ejercicio

- [x] **1. UI**: tabla (`UITableView`) + textfield + botón, celda personalizada `TaskCell`.
- [x] **2. Modelo**: `struct Task { title, isCompleted }`.
- [x] **3. Almacenamiento**: `TaskStore.tasks: [Task]` (array en memoria).
- [x] **4. Agregar**: `TaskStore.addTask(title:)`, conectado al botón y a Return del teclado.
- [x] **5. Mostrar**: `TaskCell.configure` tacha y pone en gris las completadas.
- [x] **6. Completar**: tap en la celda → `didSelectRowAt` → `toggleCompletion`.
- [x] **7. Eliminar**: swipe-to-delete → `commit editingStyle: .delete`.
- [x] **8. Persistencia (opcional)**: `UserDefaultsTaskPersistence` + Codable.
- [x] **9. Pruebas**: `TaskStoreTests.swift`, corribles con `swift test` en WSL.

## Notas / posibles mejoras si te sobra tiempo

- Podrías agregar una `UITextField` de edición al hacer swipe (acción
  "Editar" además de "Eliminar"), usando `UISwipeActionsConfiguration`.
- Si el profesor pide explícitamente Storyboard con `@IBOutlet`/`@IBAction`,
  dime y te paso la misma lógica pero conectada por Interface Builder en
  vez de layout programático — el `TaskStore` no cambia nada.
