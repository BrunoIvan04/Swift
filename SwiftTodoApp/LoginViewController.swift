import UIKit

/// Pantalla «Iniciar sesión» (REQ-07).
///
/// Entradas: correo y contraseña. Salida: Auth.signIn; al entrar, el
/// SceneDelegate cambia a «Mis tareas». Mientras responde Firebase el botón se
/// deshabilita y aparece un indicador de carga (REQ-09).
final class LoginViewController: UIViewController {

    private let emailField = Form.textField(placeholder: "Correo electrónico", id: "campoCorreo", email: true)
    private let passwordField = Form.textField(placeholder: "Contraseña", id: "campoContrasena", secure: true)
    private let errorLabel = Form.errorLabel(id: "mensajeError")
    private let spinner = Form.spinner(id: "indicadorEntrar")
    private let signInButton = Form.primaryButton(title: "Entrar", id: "botonEntrar")
    private let signUpButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("¿No tienes cuenta? Crear cuenta", for: .normal)
        button.titleLabel?.font = .preferredFont(forTextStyle: .body)
        button.titleLabel?.adjustsFontForContentSizeCategory = true
        button.accessibilityIdentifier = "botonIrACrearCuenta"
        return button
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Iniciar sesión"
        view.backgroundColor = .systemBackground
        navigationItem.backButtonTitle = "Volver"

        let intro = Form.caption("Entra para ver tus tareas en cualquier dispositivo.")
        let stack = Form.stack([intro, emailField, passwordField, errorLabel, signInButton, spinner, signUpButton])
        stack.setCustomSpacing(20, after: errorLabel)
        Form.install(stack, in: view)

        emailField.delegate = self
        passwordField.delegate = self
        emailField.clearButtonMode = .whileEditing
        passwordField.clearButtonMode = .whileEditing
        emailField.returnKeyType = .next
        passwordField.returnKeyType = .go
        signInButton.addTarget(self, action: #selector(didTapSignIn), for: .touchUpInside)
        signUpButton.addTarget(self, action: #selector(didTapSignUp), for: .touchUpInside)
    }

    @objc private func didTapSignUp() {
        navigationController?.pushViewController(SignUpViewController(), animated: true)
    }

    @objc private func didTapSignIn() {
        let email = (emailField.text ?? "").trimmingCharacters(in: .whitespaces)
        let password = passwordField.text ?? ""
        guard !email.isEmpty, !password.isEmpty else {
            show(error: "Escribe tu correo y tu contraseña.")
            return
        }
        view.endEditing(true)
        setLoading(true)
        Task {
            do {
                try await AuthService.shared.signIn(email: email, password: password)
                // El SceneDelegate detecta la sesión y muestra «Mis tareas».
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
        signInButton.isEnabled = !loading
        signUpButton.isEnabled = !loading
        loading ? spinner.startAnimating() : spinner.stopAnimating()
        if loading { errorLabel.isHidden = true }
    }
}

extension LoginViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField === emailField {
            passwordField.becomeFirstResponder()
        } else {
            didTapSignIn()
        }
        return true
    }
}

// MARK: - Componentes de formulario compartidos

/// Fábrica de controles con el mismo estilo para «Iniciar sesión» y «Crear cuenta».
enum Form {

    static func textField(placeholder: String, id: String, email: Bool = false, secure: Bool = false) -> UITextField {
        let field = UITextField()
        field.placeholder = placeholder
        field.borderStyle = .roundedRect
        field.font = .preferredFont(forTextStyle: .body)
        field.adjustsFontForContentSizeCategory = true
        field.autocapitalizationType = (email || secure) ? .none : .words
        field.autocorrectionType = .no
        field.spellCheckingType = .no
        field.isSecureTextEntry = secure
        // En pruebas de UI se desactiva la sugerencia «Usar contraseña segura» de
        // iOS, que cubre los campos y no deja escribir. En uso normal se conserva.
        if secure && ProcessInfo.processInfo.arguments.contains("-uiTesting") {
            field.textContentType = .oneTimeCode
        }
        if email {
            field.keyboardType = .emailAddress
            field.textContentType = .emailAddress
        }
        field.accessibilityIdentifier = id
        field.heightAnchor.constraint(greaterThanOrEqualToConstant: 44).isActive = true
        return field
    }

    static func primaryButton(title: String, id: String) -> UIButton {
        var config = UIButton.Configuration.filled()
        config.title = title
        config.cornerStyle = .medium
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { attributes in
            var attributes = attributes
            attributes.font = .preferredFont(forTextStyle: .headline)
            return attributes
        }
        let button = UIButton(configuration: config)
        button.accessibilityIdentifier = id
        button.heightAnchor.constraint(greaterThanOrEqualToConstant: 48).isActive = true
        return button
    }

    static func errorLabel(id: String) -> UILabel {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .footnote)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = .systemRed
        label.numberOfLines = 0
        label.isHidden = true
        label.accessibilityIdentifier = id
        return label
    }

    static func caption(_ text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = .preferredFont(forTextStyle: .subheadline)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = .secondaryLabel
        label.numberOfLines = 0
        return label
    }

    static func spinner(id: String) -> UIActivityIndicatorView {
        let spinner = UIActivityIndicatorView(style: .medium)
        spinner.hidesWhenStopped = true
        spinner.accessibilityIdentifier = id
        return spinner
    }

    static func stack(_ views: [UIView]) -> UIStackView {
        let stack = UIStackView(arrangedSubviews: views)
        stack.axis = .vertical
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }

    /// Coloca el formulario en un scroll que se recorre cuando aparece el teclado.
    static func install(_ stack: UIStackView, in view: UIView) {
        let scroll = UIScrollView()
        scroll.translatesAutoresizingMaskIntoConstraints = false
        scroll.keyboardDismissMode = .interactive
        scroll.alwaysBounceVertical = true
        view.addSubview(scroll)
        scroll.addSubview(stack)
        NSLayoutConstraint.activate([
            scroll.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scroll.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scroll.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scroll.bottomAnchor.constraint(equalTo: view.keyboardLayoutGuide.topAnchor),

            stack.topAnchor.constraint(equalTo: scroll.contentLayoutGuide.topAnchor, constant: 20),
            stack.bottomAnchor.constraint(equalTo: scroll.contentLayoutGuide.bottomAnchor, constant: -20),
            stack.leadingAnchor.constraint(equalTo: scroll.frameLayoutGuide.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: scroll.frameLayoutGuide.trailingAnchor, constant: -20)
        ])
    }
}
