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
}
