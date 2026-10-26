import UIKit
import TodoCore

/// Avisa a la lista que el usuario guardó cambios en el detalle.
protocol TaskDetailViewControllerDelegate: AnyObject {
    func taskDetail(_ controller: TaskDetailViewController, didSave task: TodoTask)
}

/// Pantalla de detalle de una tarea (REQ-11 y REQ-12).
///
/// Recibe la tarea por inyección en el inicializador y devuelve los cambios
/// mediante un delegate, sin usar variables globales.
final class TaskDetailViewController: UIViewController {

    weak var delegate: TaskDetailViewControllerDelegate?
    private var task: TodoTask

    // MARK: - Subvistas

    private let titleField: UITextField = {
        let field = UITextField()
        field.borderStyle = .roundedRect
        field.font = .preferredFont(forTextStyle: .body)
        field.adjustsFontForContentSizeCategory = true
        field.clearButtonMode = .whileEditing
        field.returnKeyType = .done
        // En pruebas de UI se apaga el autocorrector para escribir texto exacto.
        if ProcessInfo.processInfo.arguments.contains("-uiTesting") {
            field.autocorrectionType = .no
            field.spellCheckingType = .no
        }
        field.accessibilityIdentifier = "campoTitulo"
        return field
    }()

    private let dueSwitch: UISwitch = {
        let toggle = UISwitch()
        toggle.accessibilityIdentifier = "switchFecha"
        toggle.accessibilityLabel = "Fecha límite"
        return toggle
    }()

    private let datePicker: UIDatePicker = {
        let picker = UIDatePicker()
        picker.datePickerMode = .dateAndTime
        picker.preferredDatePickerStyle = .compact
        picker.locale = Locale(identifier: "es_MX")
        picker.accessibilityIdentifier = "selectorFecha"
        return picker
    }()

    private let statusLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .subheadline)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = .secondaryLabel
        return label
    }()

    // MARK: - Inicialización

    init(task: TodoTask) {
        self.task = task
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("TaskDetailViewController se crea por código con init(task:)")
    }

    // MARK: - Ciclo de vida

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Detalle"
        view.backgroundColor = .systemGroupedBackground

        let saveButton = UIBarButtonItem(title: "Guardar", style: .done, target: self, action: #selector(didTapSave))
        saveButton.accessibilityIdentifier = "botonGuardar"
        navigationItem.rightBarButtonItem = saveButton

        titleField.text = task.title
        titleField.delegate = self
        dueSwitch.isOn = task.dueDate != nil
        datePicker.date = task.dueDate ?? Self.defaultDueDate()
        datePicker.isHidden = !dueSwitch.isOn
        statusLabel.text = "Estado: " + (task.isCompleted ? "Completada" : "Pendiente")
        dueSwitch.addTarget(self, action: #selector(didToggleDueDate), for: .valueChanged)

        setupLayout()
    }

    private func setupLayout() {
        let titleCaption = makeCaption("Título")
        let dueCaption = makeCaption("Fecha límite")
        let dueRow = UIStackView(arrangedSubviews: [dueCaption, dueSwitch])
        dueRow.axis = .horizontal
        dueRow.alignment = .center

        let stack = UIStackView(arrangedSubviews: [titleCaption, titleField, dueRow, datePicker, statusLabel])
        stack.axis = .vertical
        stack.spacing = 12
        stack.alignment = .fill
        stack.setCustomSpacing(24, after: titleField)
        stack.setCustomSpacing(24, after: datePicker)
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)

        let safe = view.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: safe.topAnchor, constant: 20),
            stack.leadingAnchor.constraint(equalTo: safe.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: safe.trailingAnchor, constant: -20)
        ])
    }

    private func makeCaption(_ text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = .preferredFont(forTextStyle: .headline)
        label.adjustsFontForContentSizeCategory = true
        return label
    }

    /// Fecha sugerida al activar la fecha límite: mañana a las 23:59.
    private static func defaultDueDate() -> Date {
        let calendar = Calendar.current
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: Date()) ?? Date()
        return calendar.date(bySettingHour: 23, minute: 59, second: 0, of: tomorrow) ?? tomorrow
    }

    // MARK: - Acciones

    @objc private func didToggleDueDate() {
        UIView.animate(withDuration: 0.25) {
            self.datePicker.isHidden = !self.dueSwitch.isOn
        }
    }

    @objc private func didTapSave() {
        let text = (titleField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else {
            let alert = UIAlertController(title: "Falta el título",
                                          message: "La tarea necesita un título para guardarse.",
                                          preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Aceptar", style: .default))
            present(alert, animated: true)
            return
        }
        task.title = text
        task.dueDate = dueSwitch.isOn ? datePicker.date : nil
        delegate?.taskDetail(self, didSave: task)
        navigationController?.popViewController(animated: true)
    }
}

// MARK: - UITextFieldDelegate

extension TaskDetailViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}
