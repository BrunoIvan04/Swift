import Foundation

/// Estructura que representa una tarea de la lista de pendientes.
/// Es un `struct` (tipo valor) y conforma `Codable` para poder
/// guardarla y leerla fácilmente con JSONEncoder/JSONDecoder,
/// y `Equatable` para poder compararla en los tests.
public struct Task: Codable, Equatable, Identifiable {
    public let id: UUID
    public var title: String
    public var isCompleted: Bool

    public init(id: UUID = UUID(), title: String, isCompleted: Bool = false) {
        self.id = id
        self.title = title
        self.isCompleted = isCompleted
    }
}
