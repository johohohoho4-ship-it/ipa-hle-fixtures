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
        buttonProbe()
    }

    // F3: native metrics of the unchanged H9 system button hc.replace. The
    // button configuration (UIButton(type: .system), title "Replace") and its
    // constraints are exactly those of the hosting-controller fixture; only
    // the prints are added. Nothing here asserts an expected value.
    private func buttonProbe() {
        let button = replaceButton
        let intrinsic = button.intrinsicContentSize
        let insets = button.alignmentRectInsets
        let intrinsicFrame = CGRect(origin: .zero, size: intrinsic)
        let intrinsicAlignment = button.alignmentRectForFrame(intrinsicFrame)
        let resolvedAlignment = button.alignmentRectForFrame(button.frame)
        let title = button.title(for: .normal) ?? ""
        let titleIntrinsic = button.titleLabel?.intrinsicContentSize ?? .zero
        let titleFrame = button.titleLabel?.frame ?? .zero
        let font = button.titleLabel?.font
        let fontFamily = font?.familyName ?? ""
        let fontName = font?.fontName ?? ""
        let pointSize = font?.pointSize ?? 0
        let symbolic = Int(font?.fontDescriptor.symbolicTraits.rawValue ?? 0)
        hcLine("HCM_BUTTON name=hc.replace type=\(button.buttonType.rawValue) title=\(title)")
        hcLine(String(format: "HCM_INTRINSIC name=hc.replace w=%.4f h=%.4f",
                      intrinsic.width, intrinsic.height))
        hcLine(String(format: "HCM_INSETS name=hc.replace top=%.4f left=%.4f bottom=%.4f right=%.4f",
                      insets.top, insets.left, insets.bottom, insets.right))
        hcLine(String(format: "HCM_ALIGN name=hc.replace rect=intrinsic x=%.4f y=%.4f w=%.4f h=%.4f cx=%.4f cy=%.4f",
                      intrinsicAlignment.origin.x, intrinsicAlignment.origin.y,
                      intrinsicAlignment.size.width, intrinsicAlignment.size.height,
                      intrinsicAlignment.midX, intrinsicAlignment.midY))
        hcLine(String(format: "HCM_ALIGN name=hc.replace rect=resolved x=%.4f y=%.4f w=%.4f h=%.4f cx=%.4f cy=%.4f",
                      resolvedAlignment.origin.x, resolvedAlignment.origin.y,
                      resolvedAlignment.size.width, resolvedAlignment.size.height,
                      resolvedAlignment.midX, resolvedAlignment.midY))
        hcLine(String(format: "HCM_FRAME name=hc.replace x=%.4f y=%.4f w=%.4f h=%.4f",
                      button.frame.origin.x, button.frame.origin.y,
                      button.frame.size.width, button.frame.size.height))
        hcLine(String(format: "HCM_FONT name=hc.replace family=%@ font=%@ point=%.4f symbolic=%ld",
                      fontFamily, fontName, pointSize, symbolic))
        hcLine(String(format: "HCM_TITLE name=hc.replace text=%@ intrinsic=(%.4f,%.4f) frame=(%.4f,%.4f,%.4f,%.4f)",
                      title, titleIntrinsic.width, titleIntrinsic.height,
                      titleFrame.origin.x, titleFrame.origin.y,
                      titleFrame.size.width, titleFrame.size.height))
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
