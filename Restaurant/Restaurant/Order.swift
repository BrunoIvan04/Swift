import Foundation

/// La orden que va armando el usuario.
struct Order: Codable {
    var menuItems: [MenuItem]

    init(menuItems: [MenuItem] = []) {
        self.menuItems = menuItems
    }

    /// Suma de los precios de todos los platillos.
    var total: Double {
        menuItems.reduce(0.0) { $0 + $1.price }
    }
}
