import UIKit

final class ViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        let status = UILabel(frame: CGRect(x: 20, y: 150, width: 350, height: 60))
        status.numberOfLines = 0
        status.textColor = .black
        status.text = "Running hashable 2 checks"
        status.accessibilityIdentifier = "hashable2.status"
        view.addSubview(status)
        Task { @MainActor in
            for line in hashableChecks2() {
                print(line)
            }
            print("HSH2_DONE")
            status.text = "HSH2_DONE"
        }
    }
}
