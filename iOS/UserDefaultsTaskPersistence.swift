import Foundation
import TodoCore

/// Implementación de `TaskPersisting` (definido en TodoCore) usando
/// UserDefaults + Codable. Esta es la capa de persistencia real que
/// solo tiene sentido correr en iOS (UserDefaults no es confiable en Linux),
/// por eso vive en la carpeta iOS y no en el paquete Core.
///
/// Requisito 8 (opcional): las tareas sobreviven a cerrar/abrir la app.
final class UserDefaultsTaskPersistence: TaskPersisting {

    private let key = "com.promoselect.todo.tasks"
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func load() -> [Task] {
        guard let data = defaults.data(forKey: key) else { return [] }
        do {
            return try JSONDecoder().decode([Task].self, from: data)
        } catch {
            print("⚠️ Error al leer tareas guardadas: \(error)")
            return []
        }
    }

    func save(_ tasks: [Task]) {
        do {
            let data = try JSONEncoder().encode(tasks)
            defaults.set(data, forKey: key)
        } catch {
            print("⚠️ Error al guardar tareas: \(error)")
        }
    }
}
