import UIKit

/// Detalle de un platillo: foto, nombre, precio, descripción y el botón
/// para agregarlo a la orden.
class MenuItemDetailViewController: UIViewController {

    let menuItem: MenuItem

    let imageView = UIImageView()
    let nameLabel = UILabel()
    let priceLabel = UILabel()
    let detailTextLabel = UILabel()
    let addToOrderButton = UIButton(configuration: .filled())

    init(menuItem: MenuItem) {
        self.menuItem = menuItem
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        navigationItem.largeTitleDisplayMode = .never
        setUpViews()
        updateUI()
    }

    func setUpViews() {
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 12
        imageView.backgroundColor = .secondarySystemBackground
        imageView.image = UIImage(systemName: "photo.on.rectangle")
        imageView.tintColor = .tertiaryLabel

        nameLabel.font = .preferredFont(forTextStyle: .title1)
        nameLabel.adjustsFontForContentSizeCategory = true
        nameLabel.numberOfLines = 0
        priceLabel.font = .preferredFont(forTextStyle: .title2)
        priceLabel.adjustsFontForContentSizeCategory = true
        priceLabel.setContentHuggingPriority(.required, for: .horizontal)
        detailTextLabel.font = .preferredFont(forTextStyle: .body)
        detailTextLabel.adjustsFontForContentSizeCategory = true
        detailTextLabel.textColor = .secondaryLabel
        detailTextLabel.numberOfLines = 0

        addToOrderButton.configuration?.title = "Agregar a la orden"
        addToOrderButton.configuration?.cornerStyle = .large
        addToOrderButton.accessibilityIdentifier = "botonAgregar"
        addToOrderButton.addTarget(self, action: #selector(addToOrderButtonTapped), for: .touchUpInside)

        let titleRow = UIStackView(arrangedSubviews: [nameLabel, priceLabel])
        titleRow.axis = .horizontal
        titleRow.alignment = .firstBaseline
        titleRow.spacing = 12

        let stack = UIStackView(arrangedSubviews: [imageView, titleRow, detailTextLabel, UIView(), addToOrderButton])
        stack.axis = .vertical
        stack.spacing = 16
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)

        let safe = view.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: safe.topAnchor, constant: 16),
            stack.leadingAnchor.constraint(equalTo: safe.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: safe.trailingAnchor, constant: -20),
            stack.bottomAnchor.constraint(equalTo: safe.bottomAnchor, constant: -20),
            imageView.heightAnchor.constraint(equalTo: imageView.widthAnchor, multiplier: 0.75),
            addToOrderButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }

    func updateUI() {
        nameLabel.text = menuItem.name
        priceLabel.text = menuItem.price.formattedPrice
        detailTextLabel.text = menuItem.detailText

        Task.init {
            if let image = try? await MenuController.shared.fetchImage(from: menuItem.imageURL) {
                imageView.image = image
            }
        }
    }

    // Animación de "rebote" y el platillo se agrega a la orden compartida.
    @objc func addToOrderButtonTapped() {
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.7,
                       initialSpringVelocity: 0.1, options: [], animations: {
            self.addToOrderButton.transform = CGAffineTransform(scaleX: 2.0, y: 2.0)
            self.addToOrderButton.transform = CGAffineTransform.identity
        }, completion: nil)

        MenuController.shared.order.menuItems.append(menuItem)
    }
}
