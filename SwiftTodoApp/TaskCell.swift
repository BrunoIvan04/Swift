import UIKit
import TodoCore

/// Celda personalizada y reutilizable de la tabla (plantilla para cualquier tarea).
///
/// Muestra un ícono de estado, el título (tachado y en gris si la tarea está
/// completada), la fecha límite si existe (en rojo si está vencida) y un botón
/// de detalle. Todo por código, sin storyboard/XIB.
final class TaskCell: UITableViewCell {

    static let reuseIdentifier = "TaskCell"

    /// Se ejecuta al tocar el botón de detalle (REQ-11).
    var onDetailTapped: (() -> Void)?

    private let statusImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        imageView.preferredSymbolConfiguration = UIImage.SymbolConfiguration(textStyle: .title3)
        return imageView
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.font = .preferredFont(forTextStyle: .body)
        label.adjustsFontForContentSizeCategory = true
        return label
    }()

    private let dueLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.font = .preferredFont(forTextStyle: .footnote)
        label.adjustsFontForContentSizeCategory = true
        return label
    }()

    private lazy var textStack: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [titleLabel, dueLabel])
        stack.axis = .vertical
        stack.spacing = 2
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    private lazy var detailButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "info.circle"), for: .normal)
        button.accessibilityIdentifier = "botonDetalle"
        button.accessibilityLabel = "Detalle"
        button.frame = CGRect(x: 0, y: 0, width: 44, height: 44)
        button.addTarget(self, action: #selector(didTapDetail), for: .touchUpInside)
        return button
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupViews()
    }

    private func setupViews() {
        contentView.addSubview(statusImageView)
        contentView.addSubview(textStack)
        accessoryView = detailButton
        NSLayoutConstraint.activate([
            statusImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            statusImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            statusImageView.widthAnchor.constraint(equalToConstant: 26),

            textStack.leadingAnchor.constraint(equalTo: statusImageView.trailingAnchor, constant: 12),
            textStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),
            textStack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            textStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12)
        ])
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        onDetailTapped = nil
    }

    @objc private func didTapDetail() {
        onDetailTapped?()
    }

    /// Configura la celda a partir de una `TodoTask`.
    /// - Parameter dueText: fecha límite ya formateada, o `nil` si no tiene.
    func configure(with task: TodoTask, dueText: String?) {
        if task.isCompleted {
            titleLabel.attributedText = NSAttributedString(
                string: task.title,
                attributes: [
                    .strikethroughStyle: NSUnderlineStyle.single.rawValue,
                    .foregroundColor: UIColor.secondaryLabel
                ]
            )
            statusImageView.image = UIImage(systemName: "checkmark.circle.fill")
            statusImageView.tintColor = .systemGreen
        } else {
            titleLabel.attributedText = NSAttributedString(
                string: task.title,
                attributes: [.foregroundColor: UIColor.label]
            )
            statusImageView.image = UIImage(systemName: "circle")
            statusImageView.tintColor = .tertiaryLabel
        }

        if let dueText = dueText {
            let overdue = task.isOverdue()
            dueLabel.text = overdue ? "Vencida: \(dueText)" : "Vence: \(dueText)"
            dueLabel.textColor = overdue ? .systemRed : .secondaryLabel
            dueLabel.isHidden = false
        } else {
            dueLabel.text = nil
            dueLabel.isHidden = true
        }

        // Accesibilidad: VoiceOver (y las pruebas de UI) leen título y estado.
        accessibilityLabel = task.title
        var value = task.isCompleted ? "Completada" : "Pendiente"
        if let dueText = dueText { value += ", vence \(dueText)" }
        accessibilityValue = value
    }
}
