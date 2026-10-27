import UIKit
import TodoCore

/// Decide qué pantalla mostrar según la sesión (REQ-07):
/// sin sesión → «Iniciar sesión»; con sesión → «Mis tareas» del usuario.
/// Firebase recuerda la sesión, así que al reabrir la app se entra directo.
class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?
    private var shownUserID: String?
    private var hasRoot = false

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }

        let window = UIWindow(windowScene: windowScene)
        self.window = window
        show(user: AuthService.shared.currentUser)
        window.makeKeyAndVisible()

        AuthService.shared.observeChanges { [weak self] user in
            self?.show(user: user)
        }

        if FirebaseSetup.isDemoAccountRequested && AuthService.shared.currentUser == nil {
            Task { try? await AuthService.shared.signInDemoAccount() }
        }
    }

    private func show(user: AuthService.User?) {
        guard let window = window else { return }
        if hasRoot && user?.uid == shownUserID { return }
        hasRoot = true
        shownUserID = user?.uid

        let root: UIViewController
        if let user = user {
            let store = TaskStore(repository: FirebaseSetup.makeRepository(uid: user.uid),
                                  errorMessage: FirestoreTaskRepository.message(for:))
            root = TaskListViewController(store: store)
        } else {
            root = LoginViewController()
        }
        window.rootViewController = UINavigationController(rootViewController: root)
        UIView.transition(with: window, duration: 0.25, options: .transitionCrossDissolve, animations: nil)
    }
}
