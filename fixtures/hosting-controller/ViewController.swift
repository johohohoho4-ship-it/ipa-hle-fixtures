import SwiftUI
import UIKit

final class ViewController: UIViewController {
    private let leftHost = UIHostingController(rootView: LeftView())
    private let rightHost = UIHostingController(rootView: RightView())
    private let status = UILabel()
    private let replaceButton = UIButton(type: .system)
    private var didRun = false

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white

        addChild(leftHost)
        addChild(rightHost)
        for host in [leftHost as UIViewController, rightHost as UIViewController] {
            host.view.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(host.view)
        }
        leftHost.didMove(toParent: self)
        rightHost.didMove(toParent: self)

        status.accessibilityIdentifier = "hc.status"
        status.text = "running"
        status.textColor = .black
        status.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(status)

        replaceButton.setTitle("Replace", for: .normal)
        replaceButton.accessibilityIdentifier = "hc.replace"
        replaceButton.addTarget(self, action: #selector(replaceRoot), for: .touchUpInside)
        replaceButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(replaceButton)

        let safe = view.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            leftHost.view.leadingAnchor.constraint(equalTo: safe.leadingAnchor),
            leftHost.view.topAnchor.constraint(equalTo: safe.topAnchor, constant: 40),
            leftHost.view.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.5),
            leftHost.view.heightAnchor.constraint(equalToConstant: 160),
            rightHost.view.leadingAnchor.constraint(equalTo: leftHost.view.trailingAnchor),
            rightHost.view.topAnchor.constraint(equalTo: leftHost.view.topAnchor),
            rightHost.view.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.5),
            rightHost.view.heightAnchor.constraint(equalToConstant: 160),
            replaceButton.centerXAnchor.constraint(equalTo: safe.centerXAnchor),
            replaceButton.topAnchor.constraint(equalTo: leftHost.view.bottomAnchor, constant: 20),
            status.centerXAnchor.constraint(equalTo: safe.centerXAnchor),
            status.topAnchor.constraint(equalTo: replaceButton.bottomAnchor, constant: 12),
        ])
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        hcLine("HC_CALLBACK parent willAppear")
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        hcLine("HC_CALLBACK parent didAppear")
        guard !didRun else { return }
        didRun = true
        layoutProbe()
    }

    private func layoutProbe() {
        view.layoutIfNeeded()
        hcLine("HC_LAYOUT left=\(MemoryLayout<LeftView>.size)/\(MemoryLayout<LeftView>.stride)/\(MemoryLayout<LeftView>.alignment) right=\(MemoryLayout<RightView>.size)/\(MemoryLayout<RightView>.stride)/\(MemoryLayout<RightView>.alignment) replaced=\(MemoryLayout<ReplacedView>.size)/\(MemoryLayout<ReplacedView>.stride)/\(MemoryLayout<ReplacedView>.alignment)")
        hcLine("HC_ROOT left=LeftView right=RightView wrapper=none")
        hcLine("HC_CHILDREN count=\(children.count) leftParent=\(leftHost.parent === self ? 1 : 0) rightParent=\(rightHost.parent === self ? 1 : 0)")
        hcLine("HC_FRAME left=\(frameText(leftHost.view)) right=\(frameText(rightHost.view))")
    }

    private func frameText(_ view: UIView) -> String {
        let frame = view.frame
        return String(format: "%.1f,%.1f,%.1f,%.1f",
                      Double(frame.origin.x), Double(frame.origin.y),
                      Double(frame.size.width), Double(frame.size.height))
    }

    @objc private func replaceRoot() {
        leftHost.rootView = LeftView(replaced: true)
        view.layoutIfNeeded()
        hcLine("HC_ROOTREPLACE to=LeftView(replaced:true) content=ReplacedView leftFrame=\(frameText(leftHost.view))")
        status.text = "HC_DONE"
        hcLine("HC_DONE")
    }
}
