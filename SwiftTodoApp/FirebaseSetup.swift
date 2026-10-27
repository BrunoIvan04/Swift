import Foundation
import FirebaseCore
import FirebaseAuth
import FirebaseFirestore
import TodoCore

/// Arranque de Firebase.
///
/// Si la configuración es de un proyecto `demo-*` (la que genera CI) o la app
/// se abre con `-useEmulator`, se conecta al emulador local de Firebase en
/// lugar del proyecto real. Así las pruebas nunca tocan datos reales.
@MainActor
enum FirebaseSetup {

    static let arguments = ProcessInfo.processInfo.arguments
    private(set) static var usesEmulator = false

    static func configure() {
        FirebaseApp.configure()

        let projectID = FirebaseApp.app()?.options.projectID ?? ""
        usesEmulator = arguments.contains("-useEmulator") || projectID.hasPrefix("demo-")
        if usesEmulator {
            Auth.auth().useEmulator(withHost: "127.0.0.1", port: 9099)
            let settings = Firestore.firestore().settings
            settings.host = "127.0.0.1:8080"
            settings.isSSLEnabled = false
            settings.cacheSettings = MemoryCacheSettings()
            Firestore.firestore().settings = settings
        }
        // En la app real se usa la caché persistente por defecto de Firestore:
        // las tareas se pueden ver y editar sin internet (REQ-15).

        // Las pruebas de UI arrancan sin sesión y sin datos locales.
        if arguments.contains("-resetData") {
            try? Auth.auth().signOut()
            UserDefaultsTaskPersistence.resetAll()
        }
    }

    /// Cuenta de demostración que usa CI para tomar capturas (solo con emulador).
    static var isDemoAccountRequested: Bool {
        usesEmulator && arguments.contains("-demoAccount")
    }

    /// Repositorio de tareas del usuario que inició sesión.
    static func makeRepository(uid: String) -> TaskRepository {
        let firestore = FirestoreTaskRepository(uid: uid)
        #if DEBUG
        if arguments.contains("-simularFalloDeRed") {
            return FailFirstLoadRepository(base: firestore)
        }
        #endif
        return firestore
    }
}
