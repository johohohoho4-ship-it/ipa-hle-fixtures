import UIKit
final class ViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        let status = UILabel(frame: CGRect(x: 25, y: 150, width: 340, height: 50))
        status.textColor = .black
        status.text = "Running concurrency 2"
        status.accessibilityIdentifier = "concurrency.status"
        view.addSubview(status)
        Task { @MainActor in
            let result = await concurrencyChecks()
            status.text = result ? "CONC2_OK" : "CONC2_BAD"
            print(result ? "CONC2_OK" : "CONC2_BAD")
        }
    }
}
