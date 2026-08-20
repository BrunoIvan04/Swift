import Foundation

/// Protocolo de persistencia. Al abstraerlo así, la lógica de negocio
/// (TaskStore) no depende de UserDefaults directamente, lo cual nos
/// permite escribir tests que corren en Linux/WSL con `swift test`,
/// sin necesitar Xcode ni un Mac.
public protocol TaskPersisting {
    func load() -> [Task]
    func save(_ tasks: [Task])
}

/// Implementación en memoria, útil para tests y para previews.
public final class InMemoryTaskPersistence: TaskPersisting {
    private var storage: [Task] = []
    public init(initial: [Task] = []) { self.storage = initial }
    public func load() -> [Task] { storage }
    public func save(_ tasks: [Task]) { storage = tasks }
}

/// TaskStore contiene TODA la lógica de negocio de la app:
/// - guarda las tareas en un Array en memoria (requisito 3)
/// - agregar (requisito 4)
/// - marcar como completada (requisito 6)
/// - eliminar (requisito 7)
/// - persistencia opcional a través de `TaskPersisting` (requisito 8)
///
/// El ViewController de UIKit solo debe llamar a estos métodos y
/// refrescar la tabla; no debe manipular el array directamente.
/// Esto separa la lógica de la interfaz, y es justo lo que nos permite
/// probar la lógica sin necesitar un simulador de iOS.
public final class TaskStore {

    public private(set) var tasks: [Task]
    private let persistence: TaskPersisting

    public init(persistence: TaskPersisting = InMemoryTaskPersistence()) {
        self.persistence = persistence
        self.tasks = persistence.load()
    }

    @discardableResult
    public func addTask(title: String) -> Task? {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        let newTask = Task(title: trimmed)
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

    private func persist() {
        persistence.save(tasks)
    }
}
