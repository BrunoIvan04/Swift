import UIKit
import TodoCore

/// Celda personalizada de la tabla. Muestra el título de la tarea y,
/// si está completada, la tacha (strikethrough) y la pone en gris,
/// además de mostrar un checkmark. Todo por código, sin storyboard/XIB.
final class TaskCell: UITableViewCell {

    static let reuseIdentifier = "TaskCell"

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.font = .preferredFont(forTextStyle: .body)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
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
        contentView.addSubview(titleLabel)
        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            titleLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12)
        ])
    }

    /// Configura la celda a partir de una `Task`. Aquí es donde se
    /// aplica el estilo diferente para tareas completadas (requisito 5).
    func configure(with task: Task) {
        if task.isCompleted {
            let attributed = NSAttributedString(
                string: task.title,
                attributes: [
                    .strikethroughStyle: NSUnderlineStyle.single.rawValue,
                    .foregroundColor: UIColor.secondaryLabel
                ]
            )
            titleLabel.attributedText = attributed
            accessoryType = .checkmark
        } else {
            titleLabel.attributedText = NSAttributedString(
                string: task.title,
                attributes: [.foregroundColor: UIColor.label]
            )
            accessoryType = .none
        }
    }
}
