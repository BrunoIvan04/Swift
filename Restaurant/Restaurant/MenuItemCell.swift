import UIKit

/// Celda reutilizable para un platillo: nombre, precio y foto.
///
/// Solo guarda los datos; cada vez que cambian, pide que se actualice la
/// configuración y UIKit vuelve a dibujar la celda.
class MenuItemCell: UITableViewCell {

    static let reuseIdentifier = "MenuItem"

    var itemName: String? = nil {
        didSet {
            if oldValue != itemName { setNeedsUpdateConfiguration() }
        }
    }

    var price: Double? = nil {
        didSet {
            if oldValue != price { setNeedsUpdateConfiguration() }
        }
    }

    var image: UIImage? = nil {
        didSet {
            if oldValue != image { setNeedsUpdateConfiguration() }
        }
    }

    override func updateConfiguration(using state: UICellConfigurationState) {
        var content = defaultContentConfiguration().updated(for: state)
        content.text = itemName
        content.secondaryText = price?.formattedPrice
        content.prefersSideBySideTextAndSecondaryText = true

        if let image = image {
            content.image = image
        } else {
            content.image = UIImage(systemName: "photo.on.rectangle")
        }
        content.imageProperties.maximumSize = CGSize(width: 56, height: 56)
        content.imageProperties.reservedLayoutSize = CGSize(width: 56, height: 56)
        content.imageProperties.cornerRadius = 8

        self.contentConfiguration = content
    }
}
