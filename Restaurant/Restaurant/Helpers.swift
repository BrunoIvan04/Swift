import UIKit

extension Double {
    /// Precio en pesos mexicanos, por ejemplo "$95.00".
    var formattedPrice: String {
        formatted(.currency(code: "MXN").locale(Locale(identifier: "es_MX")))
    }
}

extension UIViewController {
    /// Muestra un error de red al usuario con un mensaje en español.
    func displayError(_ error: Error, title: String) {
        guard viewIfLoaded?.window != nil else { return }
        let alert = UIAlertController(title: title, message: error.localizedDescription, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Aceptar", style: .default))
        present(alert, animated: true)
    }
}
