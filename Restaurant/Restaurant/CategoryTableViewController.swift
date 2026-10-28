import UIKit

/// Primera pantalla: las categorías del menú que regresa GET /categories.
class CategoryTableViewController: UITableViewController {

    var categories = [String]()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Menú"
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Category")
        tableView.accessibilityIdentifier = "tablaCategorias"

        // La descarga corre en segundo plano y la tabla se actualiza al terminar.
        Task.init {
            do {
                let categories = try await MenuController.shared.fetchCategories()
                updateUI(with: categories)
            } catch {
                displayError(error, title: "No se pudieron cargar las categorías")
            }
        }
    }

    func updateUI(with categories: [String]) {
        self.categories = categories
        self.tableView.reloadData()
    }

    // MARK: - Tabla

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return categories.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Category", for: indexPath)
        configureCell(cell, forCategoryAt: indexPath)
        return cell
    }

    func configureCell(_ cell: UITableViewCell, forCategoryAt indexPath: IndexPath) {
        let category = categories[indexPath.row]
        var content = cell.defaultContentConfiguration()
        content.text = category.capitalized
        cell.contentConfiguration = content
        cell.accessoryType = .disclosureIndicator
    }

    // Al tocar una categoría se abre su menú.
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let category = categories[indexPath.row]
        let menuViewController = MenuTableViewController(category: category)
        navigationController?.pushViewController(menuViewController, animated: true)
    }
}
