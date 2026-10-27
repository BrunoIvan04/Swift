import Foundation
import FirebaseFirestore
import TodoCore

/// Documento de Firestore en users/{uid}/tasks/{taskId}.
///
/// Es un objeto de transferencia: Firestore lo codifica y decodifica con
/// Codable y luego se convierte al modelo de dominio `TodoTask`, así TodoCore
/// no depende de Firebase.
struct TaskDocument: Codable {
    @DocumentID var id: String?
    var title: String
    var isCompleted: Bool
    var dueDate: Date?          // Timestamp <-> Date
    var createdAt: Date
    var updatedAt: Date

    init(task: TodoTask, now: Date = Date()) {
        title = task.title
        isCompleted = task.isCompleted
        dueDate = task.dueDate
        createdAt = now
        updatedAt = now
    }

    func toDomain() -> TodoTask? {
        guard let id = id, let uuid = UUID(uuidString: id) else { return nil }
        return TodoTask(id: uuid, title: title, isCompleted: isCompleted, dueDate: dueDate)
    }
}

/// Repositorio de tareas en Cloud Firestore (REQ-08).
///
/// - Lectura: listener en tiempo real ordenado por fecha de creación. Con la
///   caché de Firestore, los cambios propios llegan al instante aunque el
///   servidor tarde o no haya conexión (REQ-15).
/// - Escrituras: funciones async; el id del documento es el UUID de la tarea.
@MainActor
final class FirestoreTaskRepository: TaskRepository {

    private let collection: CollectionReference

    init(uid: String, db: Firestore = .firestore()) {
        collection = db.collection("users").document(uid).collection("tasks")
    }

    func observeTasks(_ onUpdate: @escaping @MainActor (Result<[TodoTask], Error>) -> Void) -> TaskObservation {
        let registration = collection.order(by: "createdAt").addSnapshotListener { snapshot, error in
            let result: Result<[TodoTask], Error>
            if let error = error {
                result = .failure(error)
            } else {
                let tasks = snapshot?.documents.compactMap { document in
                    try? document.data(as: TaskDocument.self).toDomain()
                } ?? []
                result = .success(tasks)
            }
            Task { @MainActor in onUpdate(result) }
        }
        return ListenerObservation(registration: registration)
    }

    func add(_ task: TodoTask) async throws {
        let data = try Firestore.Encoder().encode(TaskDocument(task: task))
        try await collection.document(task.id.uuidString).setData(data)
    }

    func update(_ task: TodoTask) async throws {
        var fields: [String: Any] = [
            "title": task.title,
            "isCompleted": task.isCompleted,
            "updatedAt": Timestamp(date: Date())
        ]
        fields["dueDate"] = task.dueDate.map { Timestamp(date: $0) as Any } ?? FieldValue.delete()
        try await collection.document(task.id.uuidString).updateData(fields)
    }

    func delete(id: UUID) async throws {
        try await collection.document(id.uuidString).delete()
    }

    /// Mensaje en español para los errores de Firestore.
    nonisolated static func message(for error: Error) -> String {
        let nsError = error as NSError
        if nsError.domain == FirestoreErrorDomain {
            switch nsError.code {
            case FirestoreErrorCode.unavailable.rawValue, FirestoreErrorCode.deadlineExceeded.rawValue:
                return "No se pudo conectar con el servidor."
            case FirestoreErrorCode.permissionDenied.rawValue, FirestoreErrorCode.unauthenticated.rawValue:
                return "No tienes permiso para ver estas tareas. Cierra sesión y vuelve a entrar."
            default:
                break
            }
        }
        return (error as? LocalizedError)?.errorDescription ?? "Ocurrió un error al sincronizar."
    }

    private struct ListenerObservation: TaskObservation {
        let registration: ListenerRegistration
        func cancel() { registration.remove() }
    }
}

#if DEBUG
/// Solo para pruebas de UI (`-simularFalloDeRed`): la primera carga falla para
/// mostrar el estado de error con «Reintentar» (REQ-09).
@MainActor
final class FailFirstLoadRepository: TaskRepository {

    struct SimulatedNetworkError: LocalizedError {
        var errorDescription: String? { "No se pudo conectar con el servidor." }
    }

    private let base: TaskRepository
    private var hasFailed = false

    init(base: TaskRepository) { self.base = base }

    func observeTasks(_ onUpdate: @escaping @MainActor (Result<[TodoTask], Error>) -> Void) -> TaskObservation {
        guard hasFailed else {
            hasFailed = true
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 1_500_000_000)
                onUpdate(.failure(SimulatedNetworkError()))
            }
            return NoObservation()
        }
        return base.observeTasks(onUpdate)
    }

    func add(_ task: TodoTask) async throws { try await base.add(task) }
    func update(_ task: TodoTask) async throws { try await base.update(task) }
    func delete(id: UUID) async throws { try await base.delete(id: id) }

    private struct NoObservation: TaskObservation { func cancel() {} }
}
#endif
