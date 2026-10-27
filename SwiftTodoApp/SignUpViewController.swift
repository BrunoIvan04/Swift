import UIKit

/// Pantalla «Crear cuenta» (REQ-06).
///
/// Entradas: nombre, correo y contraseña dos veces. Antes de enviar se valida
/// en el teléfono; luego Auth.createUser crea la cuenta y se guarda el
/// documento users/{uid}. Al terminar, el SceneDelegate muestra «Mis tareas».
final class SignUpViewController: UIViewController {

    private let nameField = Form.textField(placeholder: "Nombre", id: "campoNombre")
    private let emailField = Form.textField(placeholder: "Correo electrónico", id: "campoCorreoRegistro", email: true)
    private let passwordField = Form.textField(placeholder: "Contraseña (mínimo 6 caracteres)", id: "campoContrasenaRegistro", secure: true)
    private let confirmField = Form.textField(placeholder: "Confirmar contraseña", id: "campoConfirmar", secure: true)
    private let errorLabel = Form.errorLabel(id: "mensajeErrorRegistro")
    private let spinner = Form.spinner(id: "indicadorRegistro")
    private let createButton = Form.primaryButton(title: "Crear cuenta", id: "botonCrearCuenta")

    private var fields: [UITextField] { [nameField, emailField, passwordField, confirmField] }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Crear cuenta"
        view.backgroundColor = .systemBackground

        let intro = Form.caption("Tus tareas se guardarán en la nube con esta cuenta.")
        let stack = Form.stack([intro] + fields + [errorLabel, createButton, spinner])
        stack.setCustomSpacing(20, after: errorLabel)
        Form.install(stack, in: view)

        for field in fields {
            field.delegate = self
            field.returnKeyType = .next
        }
        confirmField.returnKeyType = .go
        createButton.addTarget(self, action: #selector(didTapCreate), for: .touchUpInside)
    }

    /// Validación local antes de llamar a Firebase. Devuelve el mensaje de error, si hay.
    private func validationError(name: String, email: String, password: String, confirm: String) -> String? {
        if name.isEmpty || email.isEmpty || password.isEmpty { return "Completa todos los campos." }
        if password.count < 6 { return "La contraseña debe tener al menos 6 caracteres." }
        if password != confirm { return "Las contraseñas no coinciden." }
        return nil
    }

    @objc private func didTapCreate() {
        let name = (nameField.text ?? "").trimmingCharacters(in: .whitespaces)
        let email = (emailField.text ?? "").trimmingCharacters(in: .whitespaces)
        let password = passwordField.text ?? ""
        if let error = validationError(name: name, email: email, password: password, confirm: confirmField.text ?? "") {
            show(error: error)
            return
        }
        view.endEditing(true)
        setLoading(true)
        Task {
            do {
                try await AuthService.shared.signUp(name: name, email: email, password: password)
            } catch {
                show(error: AuthService.message(for: error))
            }
            setLoading(false)
        }
    }

    private func show(error: String) {
        errorLabel.text = error
        errorLabel.isHidden = false
        UIAccessibility.post(notification: .announcement, argument: error)
    }

    private func setLoading(_ loading: Bool) {
        createButton.isEnabled = !loading
        loading ? spinner.startAnimating() : spinner.stopAnimating()
        if loading { errorLabel.isHidden = true }
    }
}

extension SignUpViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if let index = fields.firstIndex(where: { $0 === textField }), index + 1 < fields.count {
            fields[index + 1].becomeFirstResponder()
        } else {
            didTapCreate()
        }
        return true
    }
}
