import Foundation
import FirebaseAuth
import FirebaseFirestore

/// Sesión del usuario (REQ-06, REQ-07).
///
/// Es un singleton porque la sesión sí es global a toda la app. Envuelve a
/// Firebase Authentication, que guarda la sesión en el llavero del teléfono:
/// al reabrir la app el usuario sigue dentro.
final class AuthService {

    static let shared = AuthService()
    private init() {}

    struct User: Equatable {
        let uid: String
        let email: String?
        let name: String?
    }

    private var listenerHandle: AuthStateDidChangeListenerHandle?

    var currentUser: User? {
        Auth.auth().currentUser.map(Self.makeUser)
    }

    /// Avisa cada vez que alguien inicia o cierra sesión.
    func observeChanges(_ handler: @escaping (User?) -> Void) {
        if let handle = listenerHandle { Auth.auth().removeStateDidChangeListener(handle) }
        listenerHandle = Auth.auth().addStateDidChangeListener { _, user in
            handler(user.map(Self.makeUser))
        }
    }

    func signIn(email: String, password: String) async throws {
        _ = try await Auth.auth().signIn(withEmail: email, password: password)
    }

    /// Crea la cuenta, guarda el nombre en el perfil y crea el documento users/{uid}.
    func signUp(name: String, email: String, password: String) async throws {
        let result = try await Auth.auth().createUser(withEmail: email, password: password)
        let change = result.user.createProfileChangeRequest()
        change.displayName = name
        try await change.commitChanges()
        try await Firestore.firestore().collection("users").document(result.user.uid).setData([
            "name": name,
            "email": email,
            "createdAt": FieldValue.serverTimestamp()
        ])
    }

    func signOut() throws {
        try Auth.auth().signOut()
    }

    /// Solo en CI con emulador: entra con una cuenta de demostración (la crea si no existe).
    func signInDemoAccount() async throws {
        let email = "demo@mistareas.test"
        let password = "demo1234"
        do {
            try await signIn(email: email, password: password)
        } catch {
            try await signUp(name: "Bruno", email: email, password: password)
        }
    }

    private static func makeUser(_ user: FirebaseAuth.User) -> User {
        User(uid: user.uid, email: user.email, name: user.displayName)
    }

    /// Mensaje en español para los errores de Firebase Authentication.
    static func message(for error: Error) -> String {
        let nsError = error as NSError
        guard nsError.domain == "FIRAuthErrorDomain" else {
            return "Ocurrió un error. Intenta de nuevo."
        }
        switch nsError.code {
        case 17008: return "El correo no tiene un formato válido."
        case 17009, 17004, 17011: return "Correo o contraseña incorrectos."
        case 17007: return "Ya existe una cuenta con ese correo."
        case 17026: return "La contraseña debe tener al menos 6 caracteres."
        case 17020: return "Sin conexión. Revisa tu internet e intenta de nuevo."
        case 17010: return "Demasiados intentos. Espera un momento e intenta de nuevo."
        default: return "No se pudo completar la operación (código \(nsError.code))."
        }
    }
}
