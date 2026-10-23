import UIKit

final class ViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        let status = UILabel(frame: CGRect(x: 20, y: 120, width: 350, height: 60))
        status.textColor = .black
        status.numberOfLines = 2
        status.text = "Running combine 2"
        status.accessibilityIdentifier = "combine2.status"
        view.addSubview(status)

        for line in combineChecks2() {
            print(line)
        }
        print("CMB2_DONE")
        status.text = "CMB2_DONE"
    }
}
