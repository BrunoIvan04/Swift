import Foundation

/// Estructura que representa una tarea de la lista de pendientes.
///
/// Antes se llamaba `Task`; se renombró a `TodoTask` para no chocar con el
/// tipo `Task` de Swift Concurrency, que se usará con async/await al
/// integrar Firebase (defecto D-04).
///
/// Es un `struct` (tipo valor) que conforma `Codable` para guardarse como
/// JSON, `Equatable` para compararla en los tests e `Identifiable` para
/// localizarla por `id` aunque la lista esté filtrada.
public struct TodoTask: Codable, Equatable, Identifiable {
    public let id: UUID
    public var title: String
    public var isCompleted: Bool
    /// Fecha límite opcional (REQ-12). Es opcional para que las tareas
    /// guardadas con versiones anteriores (sin este campo) se sigan leyendo.
    public var dueDate: Date?

    public init(id: UUID = UUID(), title: String, isCompleted: Bool = false, dueDate: Date? = nil) {
        self.id = id
        self.title = title
        self.isCompleted = isCompleted
        self.dueDate = dueDate
    }

    /// Una tarea está vencida si tiene fecha límite, ya pasó y no se ha completado.
    public func isOverdue(now: Date = Date()) -> Bool {
        guard let dueDate = dueDate, !isCompleted else { return false }
        return dueDate < now
    }
}

/// Filtro de la lista principal (REQ-13).
public enum TaskFilter: Int, CaseIterable {
    case all = 0
    case pending = 1
    case completed = 2

    /// Texto que se muestra en el control segmentado.
    public var title: String {
        switch self {
        case .all: return "Todas"
        case .pending: return "Pendientes"
        case .completed: return "Completadas"
        }
    }

    /// Indica si una tarea debe mostrarse con este filtro.
    public func includes(_ task: TodoTask) -> Bool {
        switch self {
        case .all: return true
        case .pending: return !task.isCompleted
        case .completed: return task.isCompleted
        }
    }
}
