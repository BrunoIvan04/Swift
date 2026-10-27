import Foundation

/// Almacenamiento local de tareas en el dispositivo (versiones 1.0 y 1.1).
///
/// Desde la versión 2.0 las tareas viven en Firestore; este protocolo se
/// conserva para leer las tareas que quedaron guardadas en el teléfono y
/// subirlas a la cuenta en el primer inicio de sesión (REQ-10).
public protocol TaskPersisting {
    func load() -> [TodoTask]
    func save(_ tasks: [TodoTask])
}

/// Implementación en memoria, útil para pruebas.
public final class InMemoryTaskPersistence: TaskPersisting {
    private var storage: [TodoTask] = []
    public init(initial: [TodoTask] = []) { self.storage = initial }
    public func load() -> [TodoTask] { storage }
    public func save(_ tasks: [TodoTask]) { storage = tasks }
}
