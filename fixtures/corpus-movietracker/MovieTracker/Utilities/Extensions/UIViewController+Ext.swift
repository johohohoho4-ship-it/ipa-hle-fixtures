import UIKit

extension UIViewController {
    func presentErrorAlert(for error: any Error) {
        let title = NSLocalizedString("error_alert_title", comment: "Error alert title")
        let alert = UIAlertController(
            title: title,
            message: error.localizedDescription,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(
            title: NSLocalizedString("error_alert_default_action", comment: "Error alert default action"),
            style: .default
        ))
        present(alert, animated: true)
    }
}
