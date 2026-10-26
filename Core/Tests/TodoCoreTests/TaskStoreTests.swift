import XCTest
@testable import TodoCore

final class TaskStoreTests: XCTestCase {

    func test_addTask_appendsToArray() {
        let store = TaskStore()
        store.addTask(title: "Comprar leche")
        XCTAssertEqual(store.tasks.count, 1)
        XCTAssertEqual(store.tasks.first?.title, "Comprar leche")
        XCTAssertFalse(store.tasks.first!.isCompleted)
    }

    func test_addTask_ignoresEmptyOrWhitespaceTitle() {
        let store = TaskStore()
        store.addTask(title: "   ")
        store.addTask(title: "")
        XCTAssertTrue(store.tasks.isEmpty)
    }

    func test_addTask_trimsWhitespace() {
        let store = TaskStore()
        store.addTask(title: "  Estudiar Swift  ")
        XCTAssertEqual(store.tasks.first?.title, "Estudiar Swift")
    }

    func test_toggleCompletion_flipsStatus() {
        let store = TaskStore()
        store.addTask(title: "Tarea 1")
        store.toggleCompletion(at: 0)
        XCTAssertTrue(store.tasks[0].isCompleted)
        store.toggleCompletion(at: 0)
        XCTAssertFalse(store.tasks[0].isCompleted)
    }

    func test_removeTask_removesFromArray() {
        let store = TaskStore()
        store.addTask(title: "A")
        store.addTask(title: "B")
        store.removeTask(at: 0)
        XCTAssertEqual(store.tasks.count, 1)
        XCTAssertEqual(store.tasks.first?.title, "B")
    }

    func test_persistence_savesAndReloads() {
        let persistence = InMemoryTaskPersistence()
        let store1 = TaskStore(persistence: persistence)
        store1.addTask(title: "Persistente")

        // Simula reabrir la app: nuevo TaskStore leyendo la misma persistencia
        let store2 = TaskStore(persistence: persistence)
        XCTAssertEqual(store2.tasks.count, 1)
        XCTAssertEqual(store2.tasks.first?.title, "Persistente")
    }

    func test_removeTask_outOfBounds_doesNothing() {
        let store = TaskStore()
        store.removeTask(at: 5)
        XCTAssertTrue(store.tasks.isEmpty)
    }

    // MARK: - Pruebas agregadas en el Sprint 2 (REQ-11 a REQ-13, D-04, H-03)

    func test_toggleCompletion_byID() {
        let store = TaskStore()
        let tarea = store.addTask(title: "Por id")!
        store.toggleCompletion(id: tarea.id)
        XCTAssertTrue(store.tasks[0].isCompleted)
    }

    func test_removeTask_byID() {
        let store = TaskStore()
        store.addTask(title: "A")
        let b = store.addTask(title: "B")!
        store.removeTask(id: b.id)
        XCTAssertEqual(store.tasks.map(\.title), ["A"])
    }

    func test_updateTask_changesTitleAndDueDate() {
        let store = TaskStore()
        let tarea = store.addTask(title: "Entregar reporte")!
        let fecha = Date(timeIntervalSince1970: 1_800_000_000)
        XCTAssertTrue(store.updateTask(id: tarea.id, title: "  Entregar reporte final ", dueDate: fecha))
        XCTAssertEqual(store.tasks[0].title, "Entregar reporte final")
        XCTAssertEqual(store.tasks[0].dueDate, fecha)
    }

    func test_updateTask_rejectsEmptyTitle() {
        let store = TaskStore()
        let tarea = store.addTask(title: "No se borra")!
        XCTAssertFalse(store.updateTask(id: tarea.id, title: "   ", dueDate: nil))
        XCTAssertEqual(store.tasks[0].title, "No se borra")
    }

    func test_updateTask_canRemoveDueDate() {
        let store = TaskStore()
        let tarea = store.addTask(title: "Con fecha")!
        store.updateTask(id: tarea.id, title: "Con fecha", dueDate: Date())
        store.updateTask(id: tarea.id, title: "Con fecha", dueDate: nil)
        XCTAssertNil(store.tasks[0].dueDate)
    }

    func test_filterAndPendingCount() {
        let store = TaskStore()
        store.addTask(title: "A")
        store.addTask(title: "B")
        store.addTask(title: "C")
        store.toggleCompletion(at: 1)
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

    /// Las tareas guardadas por la versión 1.0 no tienen `dueDate`:
    /// deben seguir leyéndose (RNF-06).
    func test_decodesTasksSavedByVersion1() throws {
        let json = #"[{"id":"6F9619FF-8B86-D011-B42D-00C04FC964FF","title":"Vieja","isCompleted":true}]"#
        let tareas = try JSONDecoder().decode([TodoTask].self, from: Data(json.utf8))
        XCTAssertEqual(tareas.count, 1)
        XCTAssertEqual(tareas[0].title, "Vieja")
        XCTAssertTrue(tareas[0].isCompleted)
        XCTAssertNil(tareas[0].dueDate)
    }
}
