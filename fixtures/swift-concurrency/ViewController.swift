import UIKit
final class ViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        let status = UILabel(frame: CGRect(x: 25, y: 150, width: 340, height: 50))
        status.textColor = .black
        status.text = "Running concurrency"
        status.accessibilityIdentifier = "concurrency.status"
        view.addSubview(status)
        Task { @MainActor in
            let result = await concurrencyChecks()
            status.text = result ? "CONCURRENCY_OK" : "CONCURRENCY_BAD"
            print(result ? "CONCURRENCY_OK" : "CONCURRENCY_BAD")
        }
    }
}
