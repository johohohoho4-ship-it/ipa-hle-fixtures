import UIKit

final class ViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        let status = UILabel(frame: CGRect(x: 25, y: 150, width: 340, height: 50))
        status.textColor = .black
        status.text = "Running combine"
        status.accessibilityIdentifier = "combine.status"
        view.addSubview(status)

        for line in combineChecks() {
            print(line)
        }
        print("CMB_DONE")
        status.text = "CMB_DONE"
    }
}
