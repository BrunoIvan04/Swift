import Foundation

/// Estado y lógica de la lista «Mis tareas».
///
/// - Escucha el repositorio y publica el estado cargando / lista / error
///   (REQ-09); el ViewController solo refleja ese estado.
/// - Valida y recorta títulos (REQ-01, REQ-02), completa (REQ-04),
///   elimina (REQ-05), edita título y fecha (REQ-11, REQ-12), filtra y
///   cuenta pendientes (REQ-13) y migra tareas locales (REQ-10).
/// - Trabaja en el hilo principal (@MainActor) y las escrituras son
///   asíncronas, así que la interfaz nunca se congela (REQ-17).
@MainActor
public final class TaskStore {

    public enum State: Equatable {
        case loading
        case loaded
        case failed(String)
    }

    /// Tareas en el orden en que se crearon.
    public private(set) var tasks: [TodoTask] = []
    public private(set) var state: State = .loading
    /// Se llama cada vez que cambian las tareas o el estado.
    public var onChange: (() -> Void)?

    private let repository: TaskRepository
    private let errorMessage: (Error) -> String
    private var observation: TaskObservation?

    /// - Parameter errorMessage: convierte un error en un texto para el usuario.
    public init(repository: TaskRepository,
                errorMessage: @escaping (Error) -> String = { $0.localizedDescription }) {
        self.repository = repository
        self.errorMessage = errorMessage
    }

    // MARK: - Carga

    /// Empieza (o reintenta) la escucha de las tareas.
    public func start() {
        observation?.cancel()
        state = .loading
        onChange?()
        observation = repository.observeTasks { [weak self] result in
            self?.apply(result)
        }
    }

    public func stop() {
        observation?.cancel()
        observation = nil
    }

    private func apply(_ result: Result<[TodoTask], Error>) {
        switch result {
        case .success(let list):
            tasks = list
            state = .loaded
        case .failure(let error):
            state = .failed(errorMessage(error))
        }
        onChange?()
    }

    // MARK: - Escrituras

    /// Devuelve el título sin espacios sobrantes, o `nil` si queda vacío.
    public static func normalizedTitle(_ title: String) -> String? {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    @discardableResult
    public func addTask(title: String, dueDate: Date? = nil) async throws -> TodoTask? {
        guard let title = Self.normalizedTitle(title) else { return nil }
        let task = TodoTask(title: title, dueDate: dueDate)
        try await repository.add(task)
        return task
    }

    public func toggleCompletion(id: UUID) async throws {
        guard var task = task(id: id) else { return }
        task.isCompleted.toggle()
        try await repository.update(task)
    }

    public func removeTask(id: UUID) async throws {
        guard task(id: id) != nil else { return }
        try await repository.delete(id: id)
    }

    /// Cambia el título y la fecha límite. Devuelve `false` si la tarea no
    /// existe o si el título queda vacío.
    @discardableResult
    public func updateTask(id: UUID, title: String, dueDate: Date?) async throws -> Bool {
        guard let title = Self.normalizedTitle(title), var task = task(id: id) else { return false }
        task.title = title
        task.dueDate = dueDate
        try await repository.update(task)
        return true
    }

    /// Sube a la cuenta las tareas guardadas en el teléfono (REQ-10).
    /// Omite las que ya existen (mismo id), así que se puede repetir sin duplicar.
    /// - Returns: cuántas tareas se subieron.
    @discardableResult
    public func importTasks(_ localTasks: [TodoTask]) async throws -> Int {
        var imported = 0
        for local in localTasks where task(id: local.id) == nil {
            try await repository.add(local)
            imported += 1
        }
        return imported
    }

    // MARK: - Consultas

    public func task(id: UUID) -> TodoTask? {
        tasks.first { $0.id == id }
    }

    /// Tareas visibles con el filtro indicado (REQ-13).
    public func tasks(matching filter: TaskFilter) -> [TodoTask] {
        tasks.filter { filter.includes($0) }
    }

    /// Número de tareas que aún no se completan.
    public var pendingCount: Int {
        tasks.filter { !$0.isCompleted }.count
    }
}
