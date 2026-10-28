import UIKit

/// Confirmación que aparece después de enviar la orden, con los minutos
/// que regresó el servidor.
class OrderConfirmationViewController: UIViewController {

    let minutesToPrepare: Int
    /// Se llama al tocar "Listo" (la orden se vacía).
    var onDismiss: (() -> Void)?

    let confirmationLabel = UILabel()
    let dismissButton = UIButton(configuration: .filled())

    init(minutesToPrepare: Int) {
        self.minutesToPrepare = minutesToPrepare
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        let icon = UIImageView(image: UIImage(systemName: "checkmark.circle.fill"))
        icon.tintColor = .systemGreen
        icon.contentMode = .scaleAspectFit
        icon.heightAnchor.constraint(equalToConstant: 90).isActive = true

        confirmationLabel.text = "¡Gracias por tu orden!\nEstará lista en aproximadamente \(minutesToPrepare) minutos."
        confirmationLabel.font = .preferredFont(forTextStyle: .title2)
        confirmationLabel.adjustsFontForContentSizeCategory = true
        confirmationLabel.numberOfLines = 0
        confirmationLabel.textAlignment = .center
        confirmationLabel.accessibilityIdentifier = "etiquetaConfirmacion"

        dismissButton.configuration?.title = "Listo"
        dismissButton.configuration?.cornerStyle = .large
        dismissButton.accessibilityIdentifier = "botonListo"
        dismissButton.addTarget(self, action: #selector(dismissTapped), for: .touchUpInside)
        dismissButton.heightAnchor.constraint(equalToConstant: 50).isActive = true

        let stack = UIStackView(arrangedSubviews: [icon, confirmationLabel, dismissButton])
        stack.axis = .vertical
        stack.spacing = 28
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            stack.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor, constant: 12),
            stack.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor, constant: -12)
        ])
    }

    @objc func dismissTapped() {
        dismiss(animated: true) { [onDismiss] in
            onDismiss?()
        }
    }
}
