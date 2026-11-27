import UIKit

final class ViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        let status = UILabel(frame: CGRect(x: 20, y: 150, width: 350, height: 60))
        status.numberOfLines = 0
        status.textColor = .black
        status.text = "Running deterministic hashing checks"
        status.accessibilityIdentifier = "deterministic-hashing.status"
        view.addSubview(status)
        Task { @MainActor in
            for line in deterministicHashingChecks() {
                print(line)
            }
            print("DH_DONE")
            status.text = "DH_DONE"
        }
    }
}
