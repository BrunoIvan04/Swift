import Foundation

/// Protocolo de persistencia. Al abstraerlo así, la lógica de negocio
/// (TaskStore) no depende de UserDefaults directamente, lo cual nos
/// permite escribir tests que corren en Linux/WSL con `swift test`,
/// sin necesitar Xcode ni un Mac.
public protocol TaskPersisting {
    func load() -> [TodoTask]
    func save(_ tasks: [TodoTask])
}

/// Implementación en memoria, útil para tests y para previews.
public final class InMemoryTaskPersistence: TaskPersisting {
    private var storage: [TodoTask] = []
    public init(initial: [TodoTask] = []) { self.storage = initial }
    public func load() -> [TodoTask] { storage }
    public func save(_ tasks: [TodoTask]) { storage = tasks }
}

/// TaskStore contiene TODA la lógica de negocio de la app:
/// - guarda las tareas en un Array en memoria (requisito 3)
/// - agregar (requisito 4)
/// - marcar como completada (requisito 6)
/// - eliminar (requisito 7)
/// - persistencia opcional a través de `TaskPersisting` (requisito 8)
/// - editar título y fecha límite (REQ-11, REQ-12)
/// - filtrar y contar pendientes (REQ-13)
///
/// El ViewController de UIKit solo debe llamar a estos métodos y
/// refrescar la tabla; no debe manipular el array directamente.
/// Esto separa la lógica de la interfaz, y es justo lo que nos permite
/// probar la lógica sin necesitar un simulador de iOS.
public final class TaskStore {

    public private(set) var tasks: [TodoTask]
    private let persistence: TaskPersisting

    public init(persistence: TaskPersisting = InMemoryTaskPersistence()) {
        self.persistence = persistence
        self.tasks = persistence.load()
    }

    @discardableResult
    public func addTask(title: String) -> TodoTask? {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        let newTask = TodoTask(title: trimmed)
        tasks.append(newTask)
        persist()
        return newTask
    }

    public func toggleCompletion(at index: Int) {
        guard tasks.indices.contains(index) else { return }
        tasks[index].isCompleted.toggle()
        persist()
    }

    public func toggleCompletion(id: UUID) {
        guard let index = tasks.firstIndex(where: { $0.id == id }) else { return }
        toggleCompletion(at: index)
    }

    public func removeTask(at index: Int) {
        guard tasks.indices.contains(index) else { return }
        tasks.remove(at: index)
        persist()
    }

    public func removeTask(id: UUID) {
        guard let index = tasks.firstIndex(where: { $0.id == id }) else { return }
        removeTask(at: index)
    }

    // MARK: - Edición (REQ-11, REQ-12)

    /// Actualiza el título y la fecha límite de una tarea.
    /// Devuelve `false` si la tarea no existe o si el título queda vacío.
    @discardableResult
    public func updateTask(id: UUID, title: String, dueDate: Date?) -> Bool {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty,
              let index = tasks.firstIndex(where: { $0.id == id }) else { return false }
        tasks[index].title = trimmed
        tasks[index].dueDate = dueDate
        persist()
        return true
    }

    // MARK: - Filtro y contador (REQ-13)

    /// Tareas visibles con el filtro indicado, en el mismo orden en que se agregaron.
    public func tasks(matching filter: TaskFilter) -> [TodoTask] {
        tasks.filter { filter.includes($0) }
    }

    /// Número de tareas que aún no se completan.
    public var pendingCount: Int {
        tasks.filter { !$0.isCompleted }.count
    }

    private func persist() {
        persistence.save(tasks)
    }
}
