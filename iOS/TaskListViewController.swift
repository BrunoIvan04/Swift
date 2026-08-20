import UIKit
import TodoCore

final class TaskListViewController: UIViewController {

    // MARK: - Datos (requisito 3: array en memoria, vía TaskStore)

    private let store = TaskStore(persistence: UserDefaultsTaskPersistence())

    // MARK: - Subvistas (requisito 1: UI simple: tabla + textfield + botón)

    private let tableView: UITableView = {
        let table = UITableView()
        table.translatesAutoresizingMaskIntoConstraints = false
        return table
    }()

    private let textField: UITextField = {
        let field = UITextField()
        field.placeholder = "Nueva tarea..."
        field.borderStyle = .roundedRect
        field.translatesAutoresizingMaskIntoConstraints = false
        field.returnKeyType = .done
        return field
    }()

    private let addButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Agregar", for: .normal)
        button.titleLabel?.font = .boldSystemFont(ofSize: 16)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private lazy var inputStack: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [textField, addButton])
        stack.axis = .horizontal
        stack.spacing = 8
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
    }

    private func setupLayout() {
        view.addSubview(inputStack)
        view.addSubview(tableView)

        let safe = view.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            inputStack.topAnchor.constraint(equalTo: safe.topAnchor, constant: 12),
            inputStack.leadingAnchor.constraint(equalTo: safe.leadingAnchor, constant: 16),
            inputStack.trailingAnchor.constraint(equalTo: safe.trailingAnchor, constant: -16),

            addButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 70),

            tableView.topAnchor.constraint(equalTo: inputStack.bottomAnchor, constant: 12),
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
        tableView.estimatedRowHeight = 44
    }

    // MARK: - Acciones (requisito 4: agregar tarea)

    @objc private func didTapAdd() {
        addTaskFromTextField()
    }

    private func addTaskFromTextField() {
        guard let text = textField.text, !text.trimmingCharacters(in: .whitespaces).isEmpty else {
            return
        }
        store.addTask(title: text)
        textField.text = nil
        textField.resignFirstResponder()
        tableView.reloadData()

        // Desplaza la tabla hasta la última fila agregada.
        let lastRow = store.tasks.count - 1
        if lastRow >= 0 {
            tableView.scrollToRow(at: IndexPath(row: lastRow, section: 0), at: .bottom, animated: true)
        }
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
        store.tasks.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: TaskCell.reuseIdentifier,
            for: indexPath
        ) as? TaskCell else {
            return UITableViewCell()
        }
        let task = store.tasks[indexPath.row]
        cell.configure(with: task)
        return cell
    }

    // Requisito 7: eliminar deslizando hacia la izquierda.
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        guard editingStyle == .delete else { return }
        store.removeTask(at: indexPath.row)
        tableView.deleteRows(at: [indexPath], with: .automatic)
    }
}

// MARK: - UITableViewDelegate

extension TaskListViewController: UITableViewDelegate {
    // Requisito 6: marcar como completada al tocar la celda.
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        store.toggleCompletion(at: indexPath.row)
        tableView.reloadRows(at: [indexPath], with: .automatic)
    }
}
