import Foundation
import TodoCore

/// Implementación de `TaskPersisting` (definido en TodoCore) usando
/// UserDefaults + Codable. Solo tiene sentido en iOS, por eso vive en el
/// target de la app y no en el paquete Core.
///
/// D-05: la clave ahora usa el identificador de la app. Si existen tareas
/// guardadas con la clave anterior, se migran una sola vez a la nueva.
final class UserDefaultsTaskPersistence: TaskPersisting {

    static let key = "com.brunoivan.SwiftTodoApp.tasks"
    static let legacyKey = "com.promoselect.todo.tasks"

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func load() -> [TodoTask] {
        if let data = defaults.data(forKey: Self.key) {
            return decode(data)
        }
        // Migración desde la clave de la versión 1.0.
        if let legacyData = defaults.data(forKey: Self.legacyKey) {
            let tasks = decode(legacyData)
            save(tasks)
            defaults.removeObject(forKey: Self.legacyKey)
            return tasks
        }
        return []
    }

    func save(_ tasks: [TodoTask]) {
        do {
            let data = try JSONEncoder().encode(tasks)
            defaults.set(data, forKey: Self.key)
        } catch {
            print("⚠️ Error al guardar tareas: \(error)")
        }
    }

    /// Borra todas las tareas guardadas (lo usan las pruebas de UI).
    static func resetAll(in defaults: UserDefaults = .standard) {
        defaults.removeObject(forKey: key)
        defaults.removeObject(forKey: legacyKey)
    }

    private func decode(_ data: Data) -> [TodoTask] {
        do {
            return try JSONDecoder().decode([TodoTask].self, from: data)
        } catch {
            print("⚠️ Error al leer tareas guardadas: \(error)")
            return []
        }
    }
}
