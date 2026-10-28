import UIKit

/// Pestaña "Mi orden": los platillos agregados, el botón para borrar y el
/// botón para enviar la orden al servidor (POST /order).
class OrderTableViewController: UITableViewController {

    var minutesToPrepareOrder = 0
    var imageLoadTasks: [IndexPath: Task<Void, Never>] = [:]

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Mi orden"
        tableView.register(MenuItemCell.self, forCellReuseIdentifier: MenuItemCell.reuseIdentifier)
        tableView.accessibilityIdentifier = "tablaOrden"

        navigationItem.leftBarButtonItem = editButtonItem
        let submitButton = UIBarButtonItem(title: "Enviar", style: .done, target: self, action: #selector(submitTapped))
        submitButton.accessibilityIdentifier = "botonEnviar"
        navigationItem.rightBarButtonItem = submitButton

        // Cada vez que cambia la orden, se vuelve a dibujar la tabla.
        NotificationCenter.default.addObserver(tableView!,
            selector: #selector(UITableView.reloadData),
            name: MenuController.orderUpdatedNotification, object: nil)
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        imageLoadTasks.forEach { key, value in value.cancel() }
    }

    // MARK: - Enviar la orden

    @objc func submitTapped() {
        let order = MenuController.shared.order
        guard !order.menuItems.isEmpty else { return }

        let alertController = UIAlertController(
            title: "Confirmar orden",
            message: "Vas a enviar tu orden con un total de \(order.total.formattedPrice).",
            preferredStyle: .actionSheet)

        alertController.addAction(UIAlertAction(title: "Enviar", style: .default) { _ in
            self.uploadOrder()
        })
        alertController.addAction(UIAlertAction(title: "Cancelar", style: .cancel, handler: nil))
        alertController.popoverPresentationController?.barButtonItem = navigationItem.rightBarButtonItem

        present(alertController, animated: true, completion: nil)
    }

    func uploadOrder() {
        let menuIds = MenuController.shared.order.menuItems.map { $0.id }
        Task.init {
            do {
                let minutesToPrepare = try await MenuController.shared.submitOrder(forMenuIDs: menuIds)
                minutesToPrepareOrder = minutesToPrepare
                showConfirmation()
            } catch {
                displayError(error, title: "No se pudo enviar la orden")
            }
        }
    }

    func showConfirmation() {
        let confirmation = OrderConfirmationViewController(minutesToPrepare: minutesToPrepareOrder)
        // Al cerrar la confirmación se vacía la orden.
        confirmation.onDismiss = {
            MenuController.shared.order.menuItems.removeAll()
        }
        confirmation.modalPresentationStyle = .formSheet
        present(confirmation, animated: true)
    }

    // MARK: - Tabla

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return MenuController.shared.order.menuItems.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: MenuItemCell.reuseIdentifier, for: indexPath)
        configure(cell, forItemAt: indexPath)
        return cell
    }

    func configure(_ cell: UITableViewCell, forItemAt indexPath: IndexPath) {
        guard let cell = cell as? MenuItemCell else { return }

        let menuItem = MenuController.shared.order.menuItems[indexPath.row]
        cell.itemName = menuItem.name
        cell.price = menuItem.price
        cell.image = nil

        imageLoadTasks[indexPath] = Task.init {
            if let image = try? await MenuController.shared.fetchImage(from: menuItem.imageURL) {
                if let currentIndexPath = self.tableView.indexPath(for: cell),
                   currentIndexPath == indexPath {
                    cell.image = image
                }
            }
            imageLoadTasks[indexPath] = nil
        }
    }

    override func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        imageLoadTasks[indexPath]?.cancel()
    }

    // Deslizar o usar "Editar" para quitar platillos de la orden.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }

    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            MenuController.shared.order.menuItems.remove(at: indexPath.row)
        }
    }

    override func tableView(_ tableView: UITableView, titleForDeleteConfirmationButtonForRowAt indexPath: IndexPath) -> String? {
        return "Quitar"
    }
}
