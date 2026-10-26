import UIKit
import TodoCore

/// Pantalla principal «Mis tareas».
///
/// Solo muestra datos y reenvía eventos: toda la lógica vive en `TaskStore`
/// (paquete TodoCore). La tabla trabaja con la lista ya filtrada y localiza
/// cada tarea por su `id`, no por su posición en el arreglo completo.
final class TaskListViewController: UIViewController {

    // MARK: - Datos

    private let store = TaskStore(persistence: UserDefaultsTaskPersistence())
    private var filter: TaskFilter = .all

    /// Tareas visibles con el filtro actual (REQ-13).
    private var visibleTasks: [TodoTask] { store.tasks(matching: filter) }

    /// Formato de la fecha límite, siempre en español de México (REQ-12).
    private static let dueDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "es_MX")
        formatter.dateFormat = "d MMM yyyy, HH:mm"
        return formatter
    }()

    // MARK: - Subvistas

    private let tableView: UITableView = {
        let table = UITableView()
        table.translatesAutoresizingMaskIntoConstraints = false
        table.accessibilityIdentifier = "listaTareas"
        return table
    }()

    private let textField: UITextField = {
        let field = UITextField()
        field.placeholder = "Nueva tarea..."
        field.borderStyle = .roundedRect
        field.font = .preferredFont(forTextStyle: .body)          // D-03
        field.adjustsFontForContentSizeCategory = true
        field.returnKeyType = .done
        field.accessibilityIdentifier = "campoNuevaTarea"
        // D-01: el campo ocupa todo el espacio libre y el botón solo su ancho.
        field.setContentHuggingPriority(.defaultLow, for: .horizontal)
        field.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        return field
    }()

    private let addButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Agregar", for: .normal)
        button.titleLabel?.font = .preferredFont(forTextStyle: .headline)   // D-03
        button.titleLabel?.adjustsFontForContentSizeCategory = true
        button.accessibilityIdentifier = "botonAgregar"
        button.setContentHuggingPriority(.required, for: .horizontal)       // D-01
        button.setContentCompressionResistancePriority(.required, for: .horizontal)
        return button
    }()

    private lazy var inputStack: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [textField, addButton])
        stack.axis = .horizontal
        stack.spacing = 12
        stack.alignment = .center
        return stack
    }()

    private lazy var filterControl: UISegmentedControl = {
        let control = UISegmentedControl(items: TaskFilter.allCases.map { $0.title })
        control.selectedSegmentIndex = TaskFilter.all.rawValue
        control.accessibilityIdentifier = "filtroEstado"
        control.addTarget(self, action: #selector(didChangeFilter), for: .valueChanged)
        return control
    }()

    private let counterLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .footnote)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = .secondaryLabel
        label.accessibilityIdentifier = "contadorPendientes"
        return label
    }()

    private let emptyLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.numberOfLines = 0
        label.font = .preferredFont(forTextStyle: .body)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = .secondaryLabel
        return label
    }()

    private lazy var headerStack: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [inputStack, filterControl, counterLabel])
        stack.axis = .vertical
        stack.spacing = 10
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    // MARK: - Ciclo de vida

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Mis tareas"
        view.backgroundColor = .systemBackground

        setupLayout()
        setupTableView()
        textField.delegate = self
        addButton.addTarget(self, action: #selector(didTapAdd), for: .touchUpInside)
        refreshAccessories()
    }

    private func setupLayout() {
        view.addSubview(headerStack)
        view.addSubview(tableView)

        let safe = view.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            headerStack.topAnchor.constraint(equalTo: safe.topAnchor, constant: 12),
            headerStack.leadingAnchor.constraint(equalTo: safe.leadingAnchor, constant: 16),
            headerStack.trailingAnchor.constraint(equalTo: safe.trailingAnchor, constant: -16),

            tableView.topAnchor.constraint(equalTo: headerStack.bottomAnchor, constant: 8),
            tableView.leadingAnchor.constraint(equalTo: safe.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: safe.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: safe.bottomAnchor)
        ])
    }

    private func setupTableView() {
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(TaskCell.self, forCellReuseIdentifier: TaskCell.reuseIdentifier)
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 52
        tableView.backgroundView = emptyLabel
    }

    /// Actualiza el contador de pendientes y el mensaje de lista vacía.
    private func refreshAccessories() {
        let pending = store.pendingCount
        counterLabel.text = pending == 1 ? "1 pendiente" : "\(pending) pendientes"
        if visibleTasks.isEmpty {
            switch filter {
            case .all: emptyLabel.text = "Aún no tienes tareas.\nEscribe una arriba y toca «Agregar»."
            case .pending: emptyLabel.text = "No tienes tareas pendientes."
            case .completed: emptyLabel.text = "Todavía no completas ninguna tarea."
            }
            emptyLabel.isHidden = false
        } else {
            emptyLabel.isHidden = true
        }
    }

    private func dueText(for task: TodoTask) -> String? {
        task.dueDate.map { Self.dueDateFormatter.string(from: $0) }
    }

    // MARK: - Acciones

    @objc private func didTapAdd() {
        addTaskFromTextField()
    }

    /// Agrega la tarea escrita. La validación de texto vacío vive solo en
    /// TaskStore (H-05) y se inserta únicamente la fila nueva (H-06).
    private func addTaskFromTextField() {
        guard store.addTask(title: textField.text ?? "") != nil else { return }
        textField.text = nil
        textField.resignFirstResponder()

        if filter.includes(store.tasks[store.tasks.count - 1]) {
            let row = visibleTasks.count - 1
            let indexPath = IndexPath(row: row, section: 0)
            tableView.insertRows(at: [indexPath], with: .automatic)
            tableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
        }
        refreshAccessories()
    }

    @objc private func didChangeFilter() {
        filter = TaskFilter(rawValue: filterControl.selectedSegmentIndex) ?? .all
        tableView.reloadData()
        refreshAccessories()
    }

    private func showDetail(for task: TodoTask) {
        let detail = TaskDetailViewController(task: task)
        detail.delegate = self
        navigationController?.pushViewController(detail, animated: true)
    }
}

// MARK: - UITextFieldDelegate

extension TaskListViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        addTaskFromTextField()
        return true
    }
}

// MARK: - UITableViewDataSource

extension TaskListViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        visibleTasks.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: TaskCell.reuseIdentifier,
            for: indexPath
        ) as? TaskCell else {
            return UITableViewCell()
        }
        let task = visibleTasks[indexPath.row]
        cell.configure(with: task, dueText: dueText(for: task))
        cell.onDetailTapped = { [weak self] in
            self?.showDetail(for: task)
        }
        return cell
    }
}

// MARK: - UITableViewDelegate

extension TaskListViewController: UITableViewDelegate {
    /// Tocar la celda marca o desmarca la tarea como completada.
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let task = visibleTasks[indexPath.row]
        store.toggleCompletion(id: task.id)
        if filter == .all {
            tableView.reloadRows(at: [indexPath], with: .automatic)
        } else {
            // Con filtro, la tarea sale de la lista visible.
            tableView.deleteRows(at: [indexPath], with: .automatic)
        }
        refreshAccessories()
    }

    /// D-02: botón de eliminar en español al deslizar a la izquierda.
    func tableView(_ tableView: UITableView,
                   trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let task = visibleTasks[indexPath.row]
        let delete = UIContextualAction(style: .destructive, title: "Eliminar") { [weak self] _, _, completion in
            guard let self = self else { return completion(false) }
            self.store.removeTask(id: task.id)
            tableView.deleteRows(at: [indexPath], with: .automatic)
            self.refreshAccessories()
            completion(true)
        }
        return UISwipeActionsConfiguration(actions: [delete])
    }

    /// Deslizar a la derecha abre el detalle (REQ-11).
    func tableView(_ tableView: UITableView,
                   leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let task = visibleTasks[indexPath.row]
        let edit = UIContextualAction(style: .normal, title: "Editar") { [weak self] _, _, completion in
            self?.showDetail(for: task)
            completion(true)
        }
        edit.backgroundColor = .systemBlue
        return UISwipeActionsConfiguration(actions: [edit])
    }
}

// MARK: - TaskDetailViewControllerDelegate

extension TaskListViewController: TaskDetailViewControllerDelegate {
    func taskDetail(_ controller: TaskDetailViewController, didSave task: TodoTask) {
        store.updateTask(id: task.id, title: task.title, dueDate: task.dueDate)
        tableView.reloadData()
        refreshAccessories()
    }
}
