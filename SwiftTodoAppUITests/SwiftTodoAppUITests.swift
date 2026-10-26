import XCTest

/// Pruebas de interfaz (XCUITest) que usan la app como lo haría una persona:
/// escriben en el campo de texto, tocan botones, deslizan celdas y vuelven
/// a abrir la app. Cada paso guarda una captura como evidencia.
///
/// Si la variable de entorno SCREENSHOT_DIR existe, las capturas también se
/// escriben como PNG en esa carpeta (en CI se pasa como TEST_RUNNER_SCREENSHOT_DIR).
final class SwiftTodoAppUITests: XCTestCase {

    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    // MARK: - Elementos de la pantalla

    private var campo: XCUIElement { app.textFields["campoNuevaTarea"] }
    private var botonAgregar: XCUIElement { app.buttons["botonAgregar"] }
    private var lista: XCUIElement { app.tables["listaTareas"] }
    private func celda(_ titulo: String) -> XCUIElement { lista.cells[titulo] }

    private func agregar(_ titulo: String, conReturn: Bool = false) {
        campo.tap()
        if conReturn {
            campo.typeText(titulo + "\n")
        } else {
            campo.typeText(titulo)
            botonAgregar.tap()
        }
    }

    private func captura(_ nombre: String) {
        let screenshot = XCUIScreen.main.screenshot()
        let adjunto = XCTAttachment(screenshot: screenshot)
        adjunto.name = nombre
        adjunto.lifetime = .keepAlways
        add(adjunto)
        if let dir = ProcessInfo.processInfo.environment["SCREENSHOT_DIR"] {
            let url = URL(fileURLWithPath: dir).appendingPathComponent("\(nombre).png")
            try? screenshot.pngRepresentation.write(to: url)
        }
    }

    // MARK: - Flujo completo (RF-01 a RF-07)

    func test_flujoCompleto_agregarCompletarEliminarYPersistir() {
        // Pantalla inicial
        XCTAssertTrue(app.navigationBars["Mis tareas"].waitForExistence(timeout: 10))
        XCTAssertEqual(lista.cells.count, 0, "La app debe iniciar sin tareas")
        captura("ui_01_inicio_sin_tareas")

        // RF-01: agregar con el botón y con la tecla Return
        agregar("Estudiar Swift")
        XCTAssertTrue(celda("Estudiar Swift").waitForExistence(timeout: 5))
        XCTAssertEqual(campo.value as? String, "Nueva tarea...", "El campo debe limpiarse")
        agregar("Entregar Fase III", conReturn: true)
        XCTAssertTrue(celda("Entregar Fase III").waitForExistence(timeout: 5))

        // RF-02: un título con solo espacios no se agrega
        agregar("   ")
        XCTAssertEqual(lista.cells.count, 2)

        agregar("Comprar leche")
        XCTAssertEqual(lista.cells.count, 3)
        captura("ui_02_tres_tareas_agregadas")

        // RF-05 / RF-04: tocar la celda la marca como completada
        celda("Estudiar Swift").tap()
        XCTAssertEqual(celda("Estudiar Swift").value as? String, "Completada")
        XCTAssertEqual(celda("Entregar Fase III").value as? String, "Pendiente")
        captura("ui_03_tarea_completada")

        // Tocar de nuevo la desmarca, y otra vez la vuelve a marcar
        celda("Estudiar Swift").tap()
        XCTAssertEqual(celda("Estudiar Swift").value as? String, "Pendiente")
        celda("Estudiar Swift").tap()

        // RF-06: deslizar a la izquierda y eliminar
        celda("Comprar leche").swipeLeft()
        let eliminar = app.buttons.matching(
            NSPredicate(format: "label IN %@", ["Delete", "Eliminar", "Borrar"])
        ).firstMatch
        XCTAssertTrue(eliminar.waitForExistence(timeout: 5))
        captura("ui_04_boton_eliminar_al_deslizar")
        eliminar.tap()
        XCTAssertFalse(celda("Comprar leche").waitForExistence(timeout: 2))
        XCTAssertEqual(lista.cells.count, 2)
        captura("ui_05_tarea_eliminada")

        // RF-07: cerrar y volver a abrir la app conserva tareas y estados
        app.terminate()
        app.launch()
        XCTAssertTrue(celda("Estudiar Swift").waitForExistence(timeout: 10))
        XCTAssertEqual(lista.cells.count, 2)
        XCTAssertEqual(celda("Estudiar Swift").value as? String, "Completada")
        XCTAssertEqual(celda("Entregar Fase III").value as? String, "Pendiente")
        captura("ui_06_persistencia_al_reabrir")
    }
}
