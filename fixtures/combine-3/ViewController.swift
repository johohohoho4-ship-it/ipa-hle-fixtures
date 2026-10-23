import UIKit

final class ViewController: UIViewController {
    private var didRun = false
    private let status = UILabel(frame: CGRect(x: 20, y: 120, width: 350, height: 60))

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        status.textColor = .black
        status.numberOfLines = 2
        status.text = "Running combine 3"
        status.accessibilityIdentifier = "combine3.status"
        view.addSubview(status)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        guard !didRun else { return }
        didRun = true
        // The checks pump the main run loop; run them once the window is up.
        for line in combineChecks3() {
            print(line)
        }
        print("CMB3_DONE")
        status.text = "CMB3_DONE"
    }
}
