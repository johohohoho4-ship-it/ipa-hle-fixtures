import UIKit

final class ViewController: UIViewController {
    private let titleLabel = UILabel()
    private let statusLabel = UILabel()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white

        titleLabel.text = "Swift Foundation"
        titleLabel.accessibilityIdentifier = "foundation.title"
        titleLabel.font = .boldSystemFont(ofSize: 24)
        titleLabel.frame = CGRect(x: 20, y: 80, width: 350, height: 36)
        view.addSubview(titleLabel)

        statusLabel.accessibilityIdentifier = "foundation.status"
        statusLabel.numberOfLines = 0
        statusLabel.frame = CGRect(x: 20, y: 130, width: 350, height: 400)
        view.addSubview(statusLabel)

        let results = runFoundationChecks()
        for (name, ok, detail) in results {
            writeLine("\(name)=\(ok ? "ok" : "FAIL") \(detail)")
        }
        let failed = results.filter { !$0.1 }.map { $0.0 }
        let status = failed.isEmpty ? "FOUNDATION_OK" : "FAIL:" + failed.joined(separator: ",")
        writeLine(status)
        statusLabel.text = status
        statusLabel.accessibilityLabel = status
    }

    private func writeLine(_ line: String) {
        let bytes = Array((line + "\n").utf8)
        bytes.withUnsafeBufferPointer { buffer in
            _ = write(STDOUT_FILENO, buffer.baseAddress, buffer.count)
        }
    }
}
