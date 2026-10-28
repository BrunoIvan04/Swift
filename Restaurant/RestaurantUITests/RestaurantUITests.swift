import XCTest

/// Recorre la app como un cliente: ve las categorías, abre un menú, agrega
/// platillos a la orden, la envía y cierra la confirmación. Guarda una
/// captura en cada paso (variable SCREENSHOT_DIR en CI).
///
/// Necesita el servidor de prueba corriendo en http://localhost:8080
/// (Restaurant/servidor/servidor.py).
final class RestaurantUITests: XCTestCase {

    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
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

    /// Da tiempo a que bajen las fotos de los platillos.
    private func esperarImagenes() {
        _ = XCTWaiter().wait(for: [XCTestExpectation(description: "imágenes")], timeout: 2.5)
    }

    private func regresar() {
        app.navigationBars.buttons.element(boundBy: 0).tap()
    }

    func test_ordenCompleta_categoriasMenuDetalleOrdenYConfirmacion() {
        // 1. Categorías desde GET /categories
        let categorias = app.tables["tablaCategorias"]
        XCTAssertTrue(categorias.staticTexts["Entradas"].waitForExistence(timeout: 15))
        XCTAssertTrue(categorias.staticTexts["Platos Fuertes"].exists)
        XCTAssertTrue(categorias.staticTexts["Postres"].exists)
        captura("r_01_categorias")

        // 2. Menú de una categoría desde GET /menu?category=entradas
        categorias.staticTexts["Entradas"].tap()
        let menu = app.tables["tablaMenu"]
        XCTAssertTrue(menu.staticTexts["Guacamole con totopos"].waitForExistence(timeout: 10))
        XCTAssertEqual(menu.cells.count, 3)
        esperarImagenes()
        captura("r_02_menu_entradas")

        // 3. Detalle del platillo y agregar a la orden
        menu.staticTexts["Guacamole con totopos"].tap()
        let agregar = app.buttons["botonAgregar"]
        XCTAssertTrue(agregar.waitForExistence(timeout: 5))
        esperarImagenes()
        captura("r_03_detalle_platillo")
        agregar.tap()

        // 4. Otra categoría y otro platillo
        regresar()
        regresar()
        categorias.staticTexts["Platos Fuertes"].tap()
        XCTAssertTrue(menu.staticTexts["Tacos al pastor"].waitForExistence(timeout: 10))
        XCTAssertEqual(menu.cells.count, 4)
        esperarImagenes()
        captura("r_04_menu_platos_fuertes")
        menu.staticTexts["Tacos al pastor"].tap()
        XCTAssertTrue(agregar.waitForExistence(timeout: 5))
        agregar.tap()
        esperarImagenes()
        captura("r_05_detalle_con_globito_de_orden")

        // 5. Pestaña de la orden con los dos platillos
        app.tabBars.buttons["Mi orden"].tap()
        let orden = app.tables["tablaOrden"]
        XCTAssertTrue(orden.staticTexts["Guacamole con totopos"].waitForExistence(timeout: 5))
        XCTAssertTrue(orden.staticTexts["Tacos al pastor"].exists)
        XCTAssertEqual(orden.cells.count, 2)
        esperarImagenes()
        captura("r_06_mi_orden")

        // 6. Enviar la orden (POST /order)
        app.navigationBars.buttons["botonEnviar"].tap()
        let hoja = app.sheets.firstMatch
        XCTAssertTrue(hoja.waitForExistence(timeout: 5))
        XCTAssertTrue(hoja.staticTexts.element(matching: NSPredicate(format: "label CONTAINS '230.00'")).exists,
                      "El total debe ser $230.00 (95 + 135)")
        captura("r_07_confirmar_envio")
        hoja.buttons["Enviar"].tap()

        // 7. Confirmación con los minutos que regresó el servidor (5 + 12)
        let confirmacion = app.staticTexts["etiquetaConfirmacion"]
        XCTAssertTrue(confirmacion.waitForExistence(timeout: 10))
        XCTAssertTrue(confirmacion.label.contains("17 minutos"), confirmacion.label)
        captura("r_08_confirmacion")

        // 8. Al cerrar, la orden queda vacía
        app.buttons["botonListo"].tap()
        let vacia = XCTNSPredicateExpectation(predicate: NSPredicate(format: "count == 0"), object: orden.cells)
        XCTAssertEqual(XCTWaiter().wait(for: [vacia], timeout: 5), .completed)
        captura("r_09_orden_vacia")
    }
}
