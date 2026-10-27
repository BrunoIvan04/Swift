import Foundation

/// Suscripción activa a los cambios de las tareas. `cancel()` deja de escuchar.
public protocol TaskObservation {
    func cancel()
}

/// Acceso a las tareas del usuario (REQ-08, REQ-18).
///
/// TodoCore no sabe nada de Firebase: la app usa `FirestoreTaskRepository`
/// y las pruebas usan `InMemoryTaskRepository`, sin internet.
///
/// - `observeTasks` entrega la lista completa cada vez que cambia
///   (en Firestore es un listener en tiempo real).
/// - Las escrituras son `async throws`: la interfaz no se bloquea mientras
///   el servidor responde (REQ-17) y los errores llegan como excepciones.
@MainActor
public protocol TaskRepository: AnyObject {
    func observeTasks(_ onUpdate: @escaping @MainActor (Result<[TodoTask], Error>) -> Void) -> TaskObservation
    func add(_ task: TodoTask) async throws
    func update(_ task: TodoTask) async throws
    func delete(id: UUID) async throws
}

/// Repositorio en memoria para pruebas. Se comporta como Firestore con caché
/// local: cada escritura avisa de inmediato a los observadores.
@MainActor
public final class InMemoryTaskRepository: TaskRepository {

    public private(set) var tasks: [TodoTask]
    /// Si tiene valor, la siguiente carga (observeTasks) falla con este error.
    public var nextLoadError: Error?
    /// Si tiene valor, la siguiente escritura falla con este error.
    public var nextWriteError: Error?

    private var observers: [UUID: @MainActor (Result<[TodoTask], Error>) -> Void] = [:]

    public init(tasks: [TodoTask] = []) {
        self.tasks = tasks
    }

    public func observeTasks(_ onUpdate: @escaping @MainActor (Result<[TodoTask], Error>) -> Void) -> TaskObservation {
        if let error = nextLoadError {
            nextLoadError = nil
            onUpdate(.failure(error))
            return Observation {}
        }
        let key = UUID()
        observers[key] = onUpdate
        onUpdate(.success(tasks))
        return Observation { [weak self] in
            Task { @MainActor in self?.observers[key] = nil }
        }
    }

    public func add(_ task: TodoTask) async throws {
        try failIfNeeded()
        tasks.append(task)
        notify()
    }

    public func update(_ task: TodoTask) async throws {
        try failIfNeeded()
        guard let index = tasks.firstIndex(where: { $0.id == task.id }) else { return }
        tasks[index] = task
        notify()
    }

    public func delete(id: UUID) async throws {
        try failIfNeeded()
        tasks.removeAll { $0.id == id }
        notify()
    }

    private func failIfNeeded() throws {
        if let error = nextWriteError {
            nextWriteError = nil
            throw error
        }
    }

    private func notify() {
        for observer in observers.values { observer(.success(tasks)) }
    }

    private struct Observation: TaskObservation {
        let onCancel: () -> Void
        func cancel() { onCancel() }
    }
}
