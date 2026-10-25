import UIKit

final class ViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        let status = UILabel(frame: CGRect(x: 20, y: 150, width: 350, height: 60))
        status.numberOfLines = 0
        status.textColor = .black
        status.text = "Running concurrency 5"
        status.accessibilityIdentifier = "concurrency5.status"
        view.addSubview(status)
        Task { @MainActor in
            for line in await concurrencyChecks5() {
                print(line)
            }
            print("CC5_DONE")
            status.text = "CC5_DONE"
        }
    }
}
