import UIKit

final class ViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        let status = UILabel(frame: CGRect(x: 20, y: 150, width: 350, height: 60))
        status.numberOfLines = 0
        status.textColor = .black
        status.text = "Running String comparison checks"
        status.accessibilityIdentifier = "string-compare.status"
        view.addSubview(status)
        Task { @MainActor in
            for line in stringCompareChecks() {
                print(line)
            }
            print("SC_DONE")
            status.text = "SC_DONE"
        }
    }
}
