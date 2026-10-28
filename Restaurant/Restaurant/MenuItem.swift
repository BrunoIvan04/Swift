import Foundation

/// Un platillo del menú, tal como lo manda el servidor en JSON.
///
/// El servidor usa nombres distintos a los de Swift (description, image_url),
/// así que CodingKeys los traduce a detailText e imageURL.
struct MenuItem: Codable {
    var id: Int
    var name: String
    var detailText: String
    var price: Double
    var category: String
    var imageURL: URL

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case detailText = "description"
        case price
        case category
        case imageURL = "image_url"
    }
}
