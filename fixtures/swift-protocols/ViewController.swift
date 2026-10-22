import UIKit

final class ViewController: UIViewController {
    private let titleLabel = UILabel()
    private let statusLabel = UILabel()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white

        titleLabel.text = "Swift Protocols"
        titleLabel.accessibilityIdentifier = "protocols.title"
        titleLabel.font = .boldSystemFont(ofSize: 24)
        titleLabel.frame = CGRect(x: 20, y: 80, width: 350, height: 36)
        view.addSubview(titleLabel)

        statusLabel.accessibilityIdentifier = "protocols.status"
        statusLabel.numberOfLines = 0
        statusLabel.frame = CGRect(x: 20, y: 130, width: 350, height: 400)
        view.addSubview(statusLabel)

        for line in protocolChecks() {
            print(line)
        }
        print("PRT_DONE")
        statusLabel.text = "PRT_DONE"
        statusLabel.accessibilityLabel = "PRT_DONE"
    }
}
