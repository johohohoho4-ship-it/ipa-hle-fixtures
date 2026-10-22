import UIKit

final class ViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        let status = UILabel(frame: CGRect(x: 25, y: 150, width: 340, height: 50))
        status.textColor = .black
        status.text = "Running concurrency 3"
        status.accessibilityIdentifier = "concurrency3.status"
        view.addSubview(status)
        Task { @MainActor in
            for line in await concurrencyChecks3() {
                print(line)
            }
            print("CC3_DONE")
            status.text = "CC3_DONE"
        }
    }
}
