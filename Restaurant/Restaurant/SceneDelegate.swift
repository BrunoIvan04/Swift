import UIKit

/// Arma la barra de pestañas (Menú y Mi orden) y mantiene el número de
/// platillos de la orden en el globito de la pestaña.
class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?
    var orderTabBarItem: UITabBarItem!

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }

        let menuNavigation = UINavigationController(rootViewController: CategoryTableViewController(style: .insetGrouped))
        menuNavigation.navigationBar.prefersLargeTitles = true
        menuNavigation.tabBarItem = UITabBarItem(title: "Menú", image: UIImage(systemName: "list.bullet"), tag: 0)

        let orderNavigation = UINavigationController(rootViewController: OrderTableViewController(style: .plain))
        orderNavigation.navigationBar.prefersLargeTitles = true
        orderNavigation.tabBarItem = UITabBarItem(title: "Mi orden", image: UIImage(systemName: "bag"), tag: 1)
        orderTabBarItem = orderNavigation.tabBarItem

        let tabBarController = UITabBarController()
        tabBarController.viewControllers = [menuNavigation, orderNavigation]

        NotificationCenter.default.addObserver(self, selector: #selector(updateOrderBadge),
            name: MenuController.orderUpdatedNotification, object: nil)

        let window = UIWindow(windowScene: windowScene)
        window.rootViewController = tabBarController
        self.window = window
        window.makeKeyAndVisible()
    }

    @objc func updateOrderBadge() {
        switch MenuController.shared.order.menuItems.count {
        case 0:
            orderTabBarItem.badgeValue = nil
        case let count:
            orderTabBarItem.badgeValue = String(count)
        }
    }
}
