import UIKit

final class ViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        let status = UILabel(frame: CGRect(x: 20, y: 150, width: 350, height: 60))
        status.numberOfLines = 0
        status.textColor = .black
        status.text = "Running hashable checks"
        status.accessibilityIdentifier = "hashable.status"
        view.addSubview(status)
        Task { @MainActor in
            for line in hashableChecks() {
                print(line)
            }
            print("HSH_DONE")
            status.text = "HSH_DONE"
        }
    }
}
