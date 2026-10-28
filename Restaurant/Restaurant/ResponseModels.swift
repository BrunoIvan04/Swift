import Foundation

/// Respuesta de GET /menu?category=...
struct MenuResponse: Codable {
    let items: [MenuItem]
}

/// Respuesta de GET /categories
struct CategoriesResponse: Codable {
    let categories: [String]
}

/// Respuesta de POST /order: los minutos que tardará la orden.
struct OrderResponse: Codable {
    let prepTime: Int

    enum CodingKeys: String, CodingKey {
        case prepTime = "preparation_time"
    }
}
