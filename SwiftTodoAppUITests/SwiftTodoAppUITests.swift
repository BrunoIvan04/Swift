import XCTest

/// Pruebas de interfaz (XCUITest) que usan la app como lo haría una persona:
/// escriben en el campo de texto, tocan botones, deslizan celdas, editan en la
/// pantalla de detalle y vuelven a abrir la app. Cada paso guarda una captura.
///
/// Si la variable de entorno SCREENSHOT_DIR existe, las capturas también se
/// escriben como PNG en esa carpeta (en CI se pasa como TEST_RUNNER_SCREENSHOT_DIR).
final class SwiftTodoAppUITests: XCTestCase {

    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["-resetData", "-uiTesting"]   // cada prueba inicia sin tareas
        app.launchEnvironment = ["TZ": "America/Mexico_City"]
        app.launch()
    }

    // MARK: - Elementos de la pantalla

    private var campo: XCUIElement { app.textFields["campoNuevaTarea"] }
    private var botonAgregar: XCUIElement { app.buttons["botonAgregar"] }
    private var lista: XCUIElement { app.tables["listaTareas"] }
    private var contador: XCUIElement { app.staticTexts["contadorPendientes"] }
    private func celda(_ titulo: String) -> XCUIElement { lista.cells[titulo] }

    /// Estado de la celda («Completada» o «Pendiente»), sin la fecha.
    private func estado(_ titulo: String) -> String {
        let valor = (celda(titulo).value as? String) ?? ""
        return valor.components(separatedBy: ",").first ?? valor
    }

    private func agregar(_ titulo: String, conReturn: Bool = false) {
        campo.tap()
        if conReturn {
            campo.typeText(titulo + "\n")
        } else {
            campo.typeText(titulo)
            botonAgregar.tap()
        }
    }

    private func filtrar(_ opcion: String) {
        app.segmentedControls["filtroEstado"].buttons[opcion].tap()
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

    // MARK: - Flujo principal (REQ-01 a REQ-05 y persistencia)

    func test_1_flujoCompleto_agregarCompletarEliminarYPersistir() {
        XCTAssertTrue(app.navigationBars["Mis tareas"].waitForExistence(timeout: 10))
        XCTAssertEqual(lista.cells.count, 0, "La app debe iniciar sin tareas")
        XCTAssertEqual(contador.label, "0 pendientes")
        captura("ui_01_inicio_sin_tareas")

        // REQ-01: agregar con el botón y con la tecla Return
        agregar("Estudiar Swift")
        XCTAssertTrue(celda("Estudiar Swift").waitForExistence(timeout: 5))
        XCTAssertEqual(campo.value as? String, "Nueva tarea...", "El campo debe limpiarse")
        agregar("Entregar Fase III", conReturn: true)
        XCTAssertTrue(celda("Entregar Fase III").waitForExistence(timeout: 5))

        // REQ-02: un título con solo espacios no se agrega
        agregar("   ")
        XCTAssertEqual(lista.cells.count, 2)

        agregar("Comprar leche")
        XCTAssertEqual(lista.cells.count, 3)
        XCTAssertEqual(contador.label, "3 pendientes")
        captura("ui_02_tres_tareas_agregadas")

        // REQ-04: tocar la celda la marca como completada
        celda("Estudiar Swift").tap()
        XCTAssertEqual(estado("Estudiar Swift"), "Completada")
        XCTAssertEqual(estado("Entregar Fase III"), "Pendiente")
        XCTAssertEqual(contador.label, "2 pendientes")
        captura("ui_03_tarea_completada")

        // Tocar de nuevo la desmarca, y otra vez la vuelve a marcar
        celda("Estudiar Swift").tap()
        XCTAssertEqual(estado("Estudiar Swift"), "Pendiente")
        celda("Estudiar Swift").tap()

        // REQ-05 y D-02: deslizar a la izquierda muestra «Eliminar» en español
        celda("Comprar leche").swipeLeft()
        let eliminar = app.buttons["Eliminar"]
        XCTAssertTrue(eliminar.waitForExistence(timeout: 5), "El botón debe decir «Eliminar»")
        captura("ui_04_boton_eliminar_al_deslizar")
        eliminar.tap()
        XCTAssertFalse(celda("Comprar leche").waitForExistence(timeout: 2))
        XCTAssertEqual(lista.cells.count, 2)
        captura("ui_05_tarea_eliminada")

        // Persistencia: cerrar y volver a abrir la app SIN borrar datos
        app.terminate()
        app.launchArguments = ["-uiTesting"]
        app.launch()
        XCTAssertTrue(celda("Estudiar Swift").waitForExistence(timeout: 10))
        XCTAssertEqual(lista.cells.count, 2)
        XCTAssertEqual(estado("Estudiar Swift"), "Completada")
        XCTAssertEqual(estado("Entregar Fase III"), "Pendiente")
        captura("ui_06_persistencia_al_reabrir")
    }

    // MARK: - Filtro, detalle y fecha límite (REQ-11 a REQ-13)

    func test_2_filtroDetalleYFechaLimite() {
        XCTAssertTrue(app.navigationBars["Mis tareas"].waitForExistence(timeout: 10))
        agregar("Leer capítulo 3")
        agregar("Hacer ejercicios")
        agregar("Entregar reporte")
        celda("Hacer ejercicios").tap()
        XCTAssertEqual(contador.label, "2 pendientes")

        // REQ-13: filtro por estado
        filtrar("Pendientes")
        XCTAssertEqual(lista.cells.count, 2)
        XCTAssertFalse(celda("Hacer ejercicios").exists)
        captura("ui_07_filtro_pendientes")

        filtrar("Completadas")
        XCTAssertEqual(lista.cells.count, 1)
        XCTAssertTrue(celda("Hacer ejercicios").exists)
        captura("ui_08_filtro_completadas")

        filtrar("Todas")
        XCTAssertEqual(lista.cells.count, 3)

        // REQ-11: abrir el detalle deslizando a la derecha
        celda("Entregar reporte").swipeRight()
        let editar = app.buttons["Editar"]
        XCTAssertTrue(editar.waitForExistence(timeout: 5))
        editar.tap()
        XCTAssertTrue(app.navigationBars["Detalle"].waitForExistence(timeout: 5))

        // Editar el título
        let campoTitulo = app.textFields["campoTitulo"]
        XCTAssertEqual(campoTitulo.value as? String, "Entregar reporte")
        campoTitulo.tap()
        // Borra el título con el botón (x) del campo y escribe el nuevo completo.
        let limpiar = campoTitulo.buttons.firstMatch
        XCTAssertTrue(limpiar.waitForExistence(timeout: 3))
        limpiar.tap()
        campoTitulo.typeText("Entregar reporte final")
        XCTAssertEqual(campoTitulo.value as? String, "Entregar reporte final")

        // REQ-12: activar la fecha límite
        app.switches["switchFecha"].tap()
        XCTAssertTrue(app.datePickers["selectorFecha"].waitForExistence(timeout: 5))
        captura("ui_09_detalle_con_fecha")

        app.buttons["botonGuardar"].tap()

        // De regreso en la lista: título nuevo y fecha límite visible
        XCTAssertTrue(celda("Entregar reporte final").waitForExistence(timeout: 5))
        XCTAssertFalse(celda("Entregar reporte").exists)
        let valor = (celda("Entregar reporte final").value as? String) ?? ""
        XCTAssertTrue(valor.contains("vence"), "La celda debe mostrar la fecha límite: \(valor)")
        captura("ui_10_tarea_editada_con_fecha")
    }
}
