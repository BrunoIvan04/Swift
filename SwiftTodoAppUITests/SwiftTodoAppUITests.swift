import XCTest

/// Pruebas de interfaz (XCUITest) que usan la app como lo haría una persona:
/// crean una cuenta, escriben tareas, tocan botones, deslizan celdas, editan
/// en el detalle, cierran sesión y vuelven a abrir la app. Cada paso guarda
/// una captura.
///
/// La app se conecta al emulador de Firebase (Auth + Firestore) que CI levanta
/// en la Mac; cada prueba usa una cuenta nueva, así que empieza sin tareas.
///
/// Si la variable de entorno SCREENSHOT_DIR existe, las capturas también se
/// escriben como PNG en esa carpeta (en CI se pasa como TEST_RUNNER_SCREENSHOT_DIR).
final class SwiftTodoAppUITests: XCTestCase {

    private var app: XCUIApplication!
    private let clave = "secreta123"

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["-resetData", "-uiTesting"]   // sin sesión ni datos locales
        app.launchEnvironment = ["TZ": "America/Mexico_City"]
        app.launch()
    }

    // MARK: - Elementos de la pantalla

    private var campo: XCUIElement { app.textFields["campoNuevaTarea"] }
    private var botonAgregar: XCUIElement { app.buttons["botonAgregar"] }
    private var lista: XCUIElement { app.tables["listaTareas"] }
    private var contador: XCUIElement { app.staticTexts["contadorPendientes"] }
    private func celda(_ titulo: String) -> XCUIElement { lista.cells[titulo] }

    // MARK: - Ayudantes

    /// Espera hasta que se cumpla la condición sobre el objeto (máx. `timeout` s).
    private func esperar(_ formato: String, _ objeto: Any, timeout: TimeInterval = 10,
                         file: StaticString = #filePath, line: UInt = #line) {
        let condicion = XCTNSPredicateExpectation(predicate: NSPredicate(format: formato), object: objeto)
        let resultado = XCTWaiter().wait(for: [condicion], timeout: timeout)
        XCTAssertEqual(resultado, .completed, "No se cumplió: \(formato)", file: file, line: line)
    }

    private func esperarCeldas(_ n: Int, file: StaticString = #filePath, line: UInt = #line) {
        esperar("count == \(n)", lista.cells, file: file, line: line)
    }

    private func esperarContador(_ texto: String, file: StaticString = #filePath, line: UInt = #line) {
        esperar("label == '\(texto)'", contador, file: file, line: line)
    }

    private func esperarEstado(_ titulo: String, _ estado: String, file: StaticString = #filePath, line: UInt = #line) {
        esperar("value BEGINSWITH '\(estado)'", celda(titulo), file: file, line: line)
    }

    private func escribir(_ elemento: XCUIElement, _ texto: String) {
        XCTAssertTrue(elemento.waitForExistence(timeout: 5))
        elemento.tap()
        elemento.typeText(texto)
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

    private func correoNuevo() -> String {
        "prueba-\(UUID().uuidString.prefix(8).lowercased())@mistareas.test"
    }

    private func abrirCrearCuenta() {
        XCTAssertTrue(app.navigationBars["Iniciar sesión"].waitForExistence(timeout: 15))
        app.buttons["botonIrACrearCuenta"].tap()
        XCTAssertTrue(app.navigationBars["Crear cuenta"].waitForExistence(timeout: 5))
    }

    /// Crea una cuenta nueva y espera a entrar a «Mis tareas». Devuelve el correo.
    @discardableResult
    private func crearCuentaNueva(nombre: String = "Prueba") -> String {
        let correo = correoNuevo()
        abrirCrearCuenta()
        escribir(app.textFields["campoNombre"], nombre)
        escribir(app.textFields["campoCorreoRegistro"], correo)
        escribir(app.secureTextFields["campoContrasenaRegistro"], clave)
        escribir(app.secureTextFields["campoConfirmar"], clave + "\n")
        XCTAssertTrue(app.navigationBars["Mis tareas"].waitForExistence(timeout: 20), "Debe entrar a «Mis tareas»")
        return correo
    }

    private func iniciarSesion(_ correo: String, _ contrasena: String) {
        XCTAssertTrue(app.navigationBars["Iniciar sesión"].waitForExistence(timeout: 10))
        let campoCorreo = app.textFields["campoCorreo"]
        let campoClave = app.secureTextFields["campoContrasena"]
        campoCorreo.tap()
        if let actual = campoCorreo.value as? String, !actual.isEmpty, actual != "Correo electrónico" {
            campoCorreo.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: actual.count))
        }
        campoCorreo.typeText(correo)
        campoClave.tap()
        campoClave.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: 20))
        campoClave.typeText(contrasena + "\n")
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

    // MARK: - 1. Flujo principal con datos en la nube (REQ-01 a REQ-05, REQ-07, REQ-08)

    func test_1_flujoCompleto_agregarCompletarEliminarYPersistir() {
        crearCuentaNueva()
        esperar("label BEGINSWITH 'Aún no tienes tareas'", app.staticTexts["mensajeLista"])
        XCTAssertEqual(lista.cells.count, 0, "Una cuenta nueva empieza sin tareas")
        esperarContador("0 pendientes")
        captura("ui_01_inicio_sin_tareas")

        // REQ-01: agregar con el botón y con la tecla Return
        agregar("Estudiar Swift")
        XCTAssertTrue(celda("Estudiar Swift").waitForExistence(timeout: 5))
        XCTAssertEqual(campo.value as? String, "Nueva tarea...", "El campo debe limpiarse")
        agregar("Entregar Fase III", conReturn: true)
        XCTAssertTrue(celda("Entregar Fase III").waitForExistence(timeout: 5))

        // REQ-02: un título con solo espacios no se agrega
        agregar("   ")
        esperarCeldas(2)

        agregar("Comprar leche")
        esperarCeldas(3)
        esperarContador("3 pendientes")
        captura("ui_02_tres_tareas_agregadas")

        // REQ-04: tocar la celda la marca como completada
        celda("Estudiar Swift").tap()
        esperarEstado("Estudiar Swift", "Completada")
        esperarEstado("Entregar Fase III", "Pendiente")
        esperarContador("2 pendientes")
        captura("ui_03_tarea_completada")

        // Tocar de nuevo la desmarca, y otra vez la vuelve a marcar
        celda("Estudiar Swift").tap()
        esperarEstado("Estudiar Swift", "Pendiente")
        celda("Estudiar Swift").tap()
        esperarEstado("Estudiar Swift", "Completada")

        // REQ-05 y D-02: deslizar a la izquierda muestra «Eliminar» en español
        celda("Comprar leche").swipeLeft()
        let eliminar = app.buttons["Eliminar"]
        XCTAssertTrue(eliminar.waitForExistence(timeout: 5), "El botón debe decir «Eliminar»")
        captura("ui_04_boton_eliminar_al_deslizar")
        eliminar.tap()
        esperarCeldas(2)
        XCTAssertFalse(celda("Comprar leche").exists)
        captura("ui_05_tarea_eliminada")

        // REQ-07 y REQ-08: cerrar y volver a abrir la app SIN borrar datos.
        // La sesión se recuerda y las tareas vuelven a llegar desde Firestore.
        app.terminate()
        app.launchArguments = ["-uiTesting"]
        app.launch()
        XCTAssertTrue(app.navigationBars["Mis tareas"].waitForExistence(timeout: 15), "La sesión debe recordarse")
        XCTAssertTrue(celda("Estudiar Swift").waitForExistence(timeout: 15))
        esperarCeldas(2)
        esperarEstado("Estudiar Swift", "Completada")
        esperarEstado("Entregar Fase III", "Pendiente")
        captura("ui_06_persistencia_al_reabrir")
    }

    // MARK: - 2. Filtro, detalle y fecha límite (REQ-11 a REQ-13)

    func test_2_filtroDetalleYFechaLimite() {
        crearCuentaNueva()
        agregar("Leer capítulo 3")
        agregar("Hacer ejercicios")
        agregar("Entregar reporte")
        esperarCeldas(3)
        celda("Hacer ejercicios").tap()
        esperarContador("2 pendientes")

        // REQ-13: filtro por estado
        filtrar("Pendientes")
        esperarCeldas(2)
        XCTAssertFalse(celda("Hacer ejercicios").exists)
        captura("ui_07_filtro_pendientes")

        filtrar("Completadas")
        esperarCeldas(1)
        XCTAssertTrue(celda("Hacer ejercicios").exists)
        captura("ui_08_filtro_completadas")

        filtrar("Todas")
        esperarCeldas(3)

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
        XCTAssertTrue(celda("Entregar reporte final").waitForExistence(timeout: 10))
        XCTAssertFalse(celda("Entregar reporte").exists)
        esperar("value CONTAINS 'vence'", celda("Entregar reporte final"))
        captura("ui_10_tarea_editada_con_fecha")
    }

    // MARK: - 3. Cuenta: crear, cerrar sesión, errores y volver a entrar (REQ-06, REQ-07)

    func test_3_cuentaInicioYCierreDeSesion() {
        // Validación en el teléfono antes de llamar a Firebase
        XCTAssertTrue(app.navigationBars["Iniciar sesión"].waitForExistence(timeout: 15))
        app.buttons["botonEntrar"].tap()
        esperar("label == 'Escribe tu correo y tu contraseña.'", app.staticTexts["mensajeError"])
        captura("ui_11_inicio_de_sesion")

        // REQ-06: crear cuenta; primero con contraseñas que no coinciden
        let correo = correoNuevo()
        abrirCrearCuenta()
        escribir(app.textFields["campoNombre"], "Bruno")
        escribir(app.textFields["campoCorreoRegistro"], correo)
        escribir(app.secureTextFields["campoContrasenaRegistro"], clave)
        escribir(app.secureTextFields["campoConfirmar"], "otra-clave\n")
        esperar("label == 'Las contraseñas no coinciden.'", app.staticTexts["mensajeErrorRegistro"])
        captura("ui_12_crear_cuenta_validacion")

        let confirmar = app.secureTextFields["campoConfirmar"]
        confirmar.tap()
        confirmar.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: 15))
        confirmar.typeText(clave + "\n")
        XCTAssertTrue(app.navigationBars["Mis tareas"].waitForExistence(timeout: 20))

        agregar("Tarea guardada en la nube")
        XCTAssertTrue(celda("Tarea guardada en la nube").waitForExistence(timeout: 5))

        // REQ-07: cerrar sesión vuelve a «Iniciar sesión»
        app.buttons["botonSalir"].tap()
        XCTAssertTrue(app.navigationBars["Iniciar sesión"].waitForExistence(timeout: 10))

        // Contraseña incorrecta: mensaje en español
        iniciarSesion(correo, "incorrecta")
        esperar("label == 'Correo o contraseña incorrectos.'", app.staticTexts["mensajeError"], timeout: 15)
        captura("ui_13_error_credenciales")

        // Contraseña correcta: entra y sus tareas siguen en Firestore
        iniciarSesion(correo, clave)
        XCTAssertTrue(app.navigationBars["Mis tareas"].waitForExistence(timeout: 20))
        XCTAssertTrue(celda("Tarea guardada en la nube").waitForExistence(timeout: 15),
                      "La tarea debe seguir en la cuenta después de salir y volver a entrar")
        captura("ui_14_tareas_desde_la_nube")
    }

    // MARK: - 4. Error de conexión y «Reintentar» (REQ-09)

    func test_4_errorDeConexionYReintentar() {
        app.terminate()
        app.launchArguments = ["-resetData", "-uiTesting", "-simularFalloDeRed"]
        app.launch()
        crearCuentaNueva()

        let reintentar = app.buttons["botonReintentar"]
        XCTAssertTrue(reintentar.waitForExistence(timeout: 10), "Debe aparecer «Reintentar»")
        esperar("label == 'No se pudo conectar con el servidor.'", app.staticTexts["mensajeLista"])
        XCTAssertFalse(campo.isEnabled, "No se puede agregar mientras no cargan las tareas")
        captura("ui_15_error_con_reintentar")

        reintentar.tap()
        esperar("label BEGINSWITH 'Aún no tienes tareas'", app.staticTexts["mensajeLista"], timeout: 15)
        XCTAssertTrue(campo.isEnabled)
        agregar("Después de reintentar")
        XCTAssertTrue(celda("Después de reintentar").waitForExistence(timeout: 5))
        captura("ui_16_lista_tras_reintentar")
    }
}
