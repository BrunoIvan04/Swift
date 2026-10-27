import XCTest
@testable import TodoCore

/// Pruebas de la lógica de TodoCore con un repositorio en memoria.
/// No necesitan internet, Firebase ni un simulador.
@MainActor
final class TaskStoreTests: XCTestCase {

    private struct FalloDePrueba: LocalizedError {
        var errorDescription: String? { "Sin conexión con el servidor." }
    }

    private var repo: InMemoryTaskRepository!
    private var store: TaskStore!

    override func setUp() async throws {
        repo = InMemoryTaskRepository()
        store = TaskStore(repository: repo)
        store.start()
    }

    // MARK: - Carga y estados (REQ-08, REQ-09)

    func test_start_loadsTasksAndReportsLoaded() {
        let repo = InMemoryTaskRepository(tasks: [TodoTask(title: "Desde la nube")])
        let store = TaskStore(repository: repo)
        XCTAssertEqual(store.state, .loading)
        store.start()
        XCTAssertEqual(store.state, .loaded)
        XCTAssertEqual(store.tasks.map(\.title), ["Desde la nube"])
    }

    func test_loadFailure_reportsErrorAndRetryRecovers() {
        let repo = InMemoryTaskRepository(tasks: [TodoTask(title: "A")])
        repo.nextLoadError = FalloDePrueba()
        let store = TaskStore(repository: repo)
        store.start()
        XCTAssertEqual(store.state, .failed("Sin conexión con el servidor."))
        store.start()   // «Reintentar»
        XCTAssertEqual(store.state, .loaded)
        XCTAssertEqual(store.tasks.count, 1)
    }

    func test_onChange_isCalledOnEveryUpdate() async throws {
        var llamadas = 0
        store.onChange = { llamadas += 1 }
        try await store.addTask(title: "Una")
        try await store.addTask(title: "Dos")
        XCTAssertEqual(llamadas, 2)
    }

    // MARK: - Agregar (REQ-01, REQ-02)

    func test_addTask_appendsToList() async throws {
        try await store.addTask(title: "Comprar leche")
        XCTAssertEqual(store.tasks.count, 1)
        XCTAssertEqual(store.tasks.first?.title, "Comprar leche")
        XCTAssertFalse(store.tasks[0].isCompleted)
        XCTAssertEqual(repo.tasks.count, 1, "La tarea debe llegar al repositorio")
    }

    func test_addTask_ignoresEmptyOrWhitespaceTitle() async throws {
        let vacia = try await store.addTask(title: "   ")
        let nada = try await store.addTask(title: "")
        XCTAssertNil(vacia)
        XCTAssertNil(nada)
        XCTAssertTrue(store.tasks.isEmpty)
    }

    func test_addTask_trimsWhitespace() async throws {
        try await store.addTask(title: "  Estudiar Swift  ")
        XCTAssertEqual(store.tasks.first?.title, "Estudiar Swift")
    }

    func test_writeFailure_throwsAndKeepsList() async throws {
        try await store.addTask(title: "A")
        repo.nextWriteError = FalloDePrueba()
        do {
            try await store.addTask(title: "B")
            XCTFail("Debió lanzar un error")
        } catch {
            XCTAssertEqual(store.tasks.map(\.title), ["A"])
        }
    }

    // MARK: - Completar y eliminar (REQ-04, REQ-05)

    func test_toggleCompletion_flipsStatus() async throws {
        let tarea = try await store.addTask(title: "Tarea 1")!
        try await store.toggleCompletion(id: tarea.id)
        XCTAssertTrue(store.tasks[0].isCompleted)
        try await store.toggleCompletion(id: tarea.id)
        XCTAssertFalse(store.tasks[0].isCompleted)
    }

    func test_removeTask_removesOnlyThatTask() async throws {
        try await store.addTask(title: "A")
        let b = try await store.addTask(title: "B")!
        try await store.removeTask(id: b.id)
        XCTAssertEqual(store.tasks.map(\.title), ["A"])
    }

    func test_unknownID_doesNothing() async throws {
        try await store.addTask(title: "A")
        try await store.toggleCompletion(id: UUID())
        try await store.removeTask(id: UUID())
        XCTAssertEqual(store.tasks.count, 1)
        XCTAssertFalse(store.tasks[0].isCompleted)
    }

    // MARK: - Edición (REQ-11, REQ-12)

    func test_updateTask_changesTitleAndDueDate() async throws {
        let tarea = try await store.addTask(title: "Entregar reporte")!
        let fecha = Date(timeIntervalSince1970: 1_800_000_000)
        let ok = try await store.updateTask(id: tarea.id, title: "  Entregar reporte final ", dueDate: fecha)
        XCTAssertTrue(ok)
        XCTAssertEqual(store.tasks[0].title, "Entregar reporte final")
        XCTAssertEqual(store.tasks[0].dueDate, fecha)
    }

    func test_updateTask_rejectsEmptyTitle() async throws {
        let tarea = try await store.addTask(title: "No se borra")!
        let ok = try await store.updateTask(id: tarea.id, title: "   ", dueDate: nil)
        XCTAssertFalse(ok)
        XCTAssertEqual(store.tasks[0].title, "No se borra")
    }

    func test_updateTask_canRemoveDueDate() async throws {
        let tarea = try await store.addTask(title: "Con fecha", dueDate: Date())!
        try await store.updateTask(id: tarea.id, title: "Con fecha", dueDate: nil)
        XCTAssertNil(store.tasks[0].dueDate)
    }

    // MARK: - Filtro y contador (REQ-13)

    func test_filterAndPendingCount() async throws {
        try await store.addTask(title: "A")
        let b = try await store.addTask(title: "B")!
        try await store.addTask(title: "C")
        try await store.toggleCompletion(id: b.id)
        XCTAssertEqual(store.tasks(matching: .all).map(\.title), ["A", "B", "C"])
        XCTAssertEqual(store.tasks(matching: .pending).map(\.title), ["A", "C"])
        XCTAssertEqual(store.tasks(matching: .completed).map(\.title), ["B"])
        XCTAssertEqual(store.pendingCount, 2)
    }

    func test_isOverdue() {
        let ahora = Date(timeIntervalSince1970: 1_800_000_000)
        let vencida = TodoTask(title: "Vencida", dueDate: ahora.addingTimeInterval(-60))
        let futura = TodoTask(title: "Futura", dueDate: ahora.addingTimeInterval(60))
        let completada = TodoTask(title: "Hecha", isCompleted: true, dueDate: ahora.addingTimeInterval(-60))
        XCTAssertTrue(vencida.isOverdue(now: ahora))
        XCTAssertFalse(futura.isOverdue(now: ahora))
        XCTAssertFalse(completada.isOverdue(now: ahora))
        XCTAssertFalse(TodoTask(title: "Sin fecha").isOverdue(now: ahora))
    }

    // MARK: - Migración de tareas locales (REQ-10)

    func test_importTasks_uploadsLocalTasksInOrder() async throws {
        let locales = [TodoTask(title: "Local 1", isCompleted: true), TodoTask(title: "Local 2")]
        let subidas = try await store.importTasks(locales)
        XCTAssertEqual(subidas, 2)
        XCTAssertEqual(store.tasks, locales)
        XCTAssertEqual(repo.tasks, locales)
    }

    func test_importTasks_skipsTasksAlreadyInTheCloud() async throws {
        let local = TodoTask(title: "Ya subida")
        try await store.importTasks([local])
        let otraVez = try await store.importTasks([local, TodoTask(title: "Nueva")])
        XCTAssertEqual(otraVez, 1)
        XCTAssertEqual(store.tasks.map(\.title), ["Ya subida", "Nueva"])
    }

    /// Las tareas guardadas por la versión 1.0 no tienen `dueDate`:
    /// deben seguir leyéndose para poder migrarlas (RNF-06).
    func test_decodesTasksSavedByVersion1() throws {
        let json = #"[{"id":"6F9619FF-8B86-D011-B42D-00C04FC964FF","title":"Vieja","isCompleted":true}]"#
        let tareas = try JSONDecoder().decode([TodoTask].self, from: Data(json.utf8))
        XCTAssertEqual(tareas.count, 1)
        XCTAssertEqual(tareas[0].title, "Vieja")
        XCTAssertTrue(tareas[0].isCompleted)
        XCTAssertNil(tareas[0].dueDate)
    }
}
