import UIKit

/// Reemplaza el SceneDelegate.swift que Xcode genera por defecto con este.
/// Arranca la app directamente en TaskListViewController, envuelto en un
/// UINavigationController (para tener el título arriba), sin usar Main.storyboard.
class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }

        let window = UIWindow(windowScene: windowScene)
        let rootVC = TaskListViewController()
        window.rootViewController = UINavigationController(rootViewController: rootVC)
        self.window = window
        window.makeKeyAndVisible()
    }
}
