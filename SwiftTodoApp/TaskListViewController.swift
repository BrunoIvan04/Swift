import UIKit
import TodoCore

/// Pantalla principal «Mis tareas».
///
/// Solo muestra datos y reenvía eventos: la lógica vive en `TaskStore`
/// (TodoCore) y los datos llegan de Firestore en tiempo real. La tabla trabaja
/// con la lista ya filtrada y localiza cada tarea por su `id`.
final class TaskListViewController: UIViewController {

    // MARK: - Datos

    private let store: TaskStore
    private let localStorage: TaskPersisting
    private var filter: TaskFilter = .all
    private var didCheckLocalTasks = false

    /// Tareas visibles con el filtro actual (REQ-13).
    private var visibleTasks: [TodoTask] { store.tasks(matching: filter) }

    /// Formato de la fecha límite, siempre en español de México (REQ-12).
    private static let dueDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "es_MX")
        formatter.dateFormat = "d MMM yyyy, HH:mm"
        return formatter
    }()

    init(store: TaskStore, localStorage: TaskPersisting = UserDefaultsTaskPersistence()) {
        self.store = store
        self.localStorage = localStorage
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("TaskListViewController se crea por código con init(store:)")
    }

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
        // En pruebas de UI se apaga el autocorrector para escribir texto exacto.
        if ProcessInfo.processInfo.arguments.contains("-uiTesting") {
            field.autocorrectionType = .no
            field.spellCheckingType = .no
        }
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

    /// Aviso temporal (por ejemplo, al migrar tareas del teléfono a la nube).
    private let noticeLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .footnote)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = .systemGreen
        label.numberOfLines = 0
        label.isHidden = true
        label.accessibilityIdentifier = "avisoLista"
        return label
    }()

    private lazy var headerStack: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [inputStack, filterControl, counterLabel, noticeLabel])
        stack.axis = .vertical
        stack.spacing = 10
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    // Estado de la lista (REQ-09): cargando, vacía o error con «Reintentar».
    private let spinner: UIActivityIndicatorView = {
        let spinner = UIActivityIndicatorView(style: .large)
        spinner.hidesWhenStopped = true
        spinner.accessibilityIdentifier = "indicadorCarga"
        spinner.accessibilityLabel = "Cargando tareas"
        return spinner
    }()

    private let messageLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.numberOfLines = 0
        label.font = .preferredFont(forTextStyle: .body)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = .secondaryLabel
        label.accessibilityIdentifier = "mensajeLista"
        return label
    }()

    private let retryButton: UIButton = {
        var config = UIButton.Configuration.tinted()
        config.title = "Reintentar"
        config.image = UIImage(systemName: "arrow.clockwise")
        config.imagePadding = 6
        let button = UIButton(configuration: config)
        button.accessibilityIdentifier = "botonReintentar"
        return button
    }()

    private lazy var stateView: UIView = {
        let stack = UIStackView(arrangedSubviews: [spinner, messageLabel, retryButton])
        stack.axis = .vertical
        stack.spacing = 14
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        let container = UIView()
        container.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.centerYAnchor.constraint(equalTo: container.centerYAnchor, constant: -40),
            stack.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 32),
            stack.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -32)
        ])
        return container
    }()

    // MARK: - Ciclo de vida

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Mis tareas"
        view.backgroundColor = .systemBackground

        let signOut = UIBarButtonItem(title: "Salir", style: .plain, target: self, action: #selector(didTapSignOut))
        signOut.accessibilityIdentifier = "botonSalir"
        navigationItem.leftBarButtonItem = signOut

        setupLayout()
        setupTableView()
        textField.delegate = self
        addButton.addTarget(self, action: #selector(didTapAdd), for: .touchUpInside)
        retryButton.addTarget(self, action: #selector(didTapRetry), for: .touchUpInside)

        store.onChange = { [weak self] in self?.storeDidChange() }
        store.start()
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
        tableView.backgroundView = stateView
    }

    // MARK: - Estado

    private func storeDidChange() {
        tableView.reloadData()
        refreshAccessories()
        if store.state == .loaded && !didCheckLocalTasks {
            didCheckLocalTasks = true
            migrateLocalTasks()
        }
    }

    /// Actualiza el contador y el estado de la lista (cargando, vacía, error).
    private func refreshAccessories() {
        let pending = store.pendingCount
        counterLabel.text = pending == 1 ? "1 pendiente" : "\(pending) pendientes"

        let isLoading = store.state == .loading && store.tasks.isEmpty
        let isEditable = store.state == .loaded
        textField.isEnabled = isEditable
        addButton.isEnabled = isEditable
        filterControl.isEnabled = isEditable

        isLoading ? spinner.startAnimating() : spinner.stopAnimating()
        retryButton.isHidden = true
        stateView.isHidden = false

        switch store.state {
        case .loading:
            messageLabel.text = isLoading ? "Cargando tus tareas…" : nil
        case .failed(let message):
            messageLabel.text = message
            retryButton.isHidden = false
        case .loaded:
            if visibleTasks.isEmpty {
                switch filter {
                case .all: messageLabel.text = "Aún no tienes tareas.\nEscribe una arriba y toca «Agregar»."
                case .pending: messageLabel.text = "No tienes tareas pendientes."
                case .completed: messageLabel.text = "Todavía no completas ninguna tarea."
                }
            } else {
                stateView.isHidden = true
            }
        }
    }

    /// REQ-10: la primera vez que se entra con una cuenta, las tareas que quedaron
    /// guardadas en el teléfono (versiones 1.x) se suben a Firestore.
    private func migrateLocalTasks() {
        let localTasks = localStorage.load()
        guard !localTasks.isEmpty else { return }
        Task {
            do {
                let count = try await store.importTasks(localTasks)
                UserDefaultsTaskPersistence.resetAll()
                if count > 0 {
                    showNotice(count == 1 ? "Se subió 1 tarea de este teléfono a tu cuenta."
                                          : "Se subieron \(count) tareas de este teléfono a tu cuenta.")
                }
            } catch {
                // Se conservan en el teléfono y se reintenta en el próximo inicio.
                showError(error)
            }
        }
    }

    private func showNotice(_ text: String) {
        noticeLabel.text = text
        noticeLabel.isHidden = false
        UIAccessibility.post(notification: .announcement, argument: text)
        DispatchQueue.main.asyncAfter(deadline: .now() + 8) { [weak self] in
            self?.noticeLabel.isHidden = true
        }
    }

    private func showError(_ error: Error) {
        let alert = UIAlertController(title: "No se pudo guardar el cambio",
                                      message: FirestoreTaskRepository.message(for: error),
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Aceptar", style: .default))
        present(alert, animated: true)
    }

    /// Ejecuta una escritura sin bloquear la interfaz y avisa si falla.
    private func perform(_ operation: @escaping () async throws -> Void) {
        Task {
            do { try await operation() } catch { showError(error) }
        }
    }

    private func dueText(for task: TodoTask) -> String? {
        task.dueDate.map { Self.dueDateFormatter.string(from: $0) }
    }

    // MARK: - Acciones

    @objc private func didTapAdd() {
        addTaskFromTextField()
    }

    /// La validación de texto vacío vive solo en TaskStore (H-05). La fila
    /// aparece en cuanto Firestore aplica el cambio en su caché local.
    private func addTaskFromTextField() {
        let title = textField.text ?? ""
        textField.text = nil
        textField.resignFirstResponder()
        perform { [store] in _ = try await store.addTask(title: title) }
    }

    @objc private func didChangeFilter() {
        filter = TaskFilter(rawValue: filterControl.selectedSegmentIndex) ?? .all
        tableView.reloadData()
        refreshAccessories()
    }

    @objc private func didTapRetry() {
        store.start()
    }

    @objc private func didTapSignOut() {
        store.stop()
        do {
            try AuthService.shared.signOut()   // el SceneDelegate vuelve a «Iniciar sesión»
        } catch {
            showError(error)
        }
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
        let id = visibleTasks[indexPath.row].id
        perform { [store] in try await store.toggleCompletion(id: id) }
    }

    /// D-02: botón de eliminar en español al deslizar a la izquierda.
    func tableView(_ tableView: UITableView,
                   trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let id = visibleTasks[indexPath.row].id
        let delete = UIContextualAction(style: .destructive, title: "Eliminar") { [weak self] _, _, completion in
            completion(true)
            guard let self = self else { return }
            self.perform { [store = self.store] in try await store.removeTask(id: id) }
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
        perform { [store] in
            _ = try await store.updateTask(id: task.id, title: task.title, dueDate: task.dueDate)
        }
    }
}
