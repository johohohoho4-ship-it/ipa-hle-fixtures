//
//  GuideProbe.swift
//  guide-archive
//
//  Measures the legacy viewControllerLayoutGuide archive profile that the
//  drawing app's storyboard still carries (viewControllerLayoutGuide type
//  top/bottom). The values are printed as GA_ lines; the fixture itself makes
//  no assumption about them.
//

import UIKit
import ObjectiveC

final class GuideProbe {
	static let shared = GuideProbe()

	private var started = false
	private var statusLabel: UILabel?

	func begin(from controller: UIViewController) {
		guard !started else { return }
		started = true
		guard let window = controller.view.window else {
			log("GA_WINDOW missing")
			finish(nil)
			return
		}
		attachStatus(to: controller)
		measure(controller, phase: "plain")
		let navigation = UINavigationController(rootViewController: PhaseViewController(phase: "nav"))
		window.rootViewController = navigation
	}

	func measure(_ controller: UIViewController, phase: String) {
		attachStatus(to: controller)
		let top = controller.topLayoutGuide
		let bottom = controller.bottomLayoutGuide
		let view = controller.view!
		let topObject = top as AnyObject
		let bottomObject = bottom as AnyObject
		let topGuide = top as? UILayoutGuide
		let bottomGuide = bottom as? UILayoutGuide
		let topOwner = topGuide?.owningView
		let bottomOwner = bottomGuide?.owningView
		let topFrame = topGuide?.layoutFrame ?? .zero
		let bottomFrame = bottomGuide?.layoutFrame ?? .zero

		log(String(format: "GA_GUIDE phase=%@ top=%.1f bottom=%.1f topClass=%@ bottomClass=%@ distinct=%d topOwner=%@ bottomOwner=%@ topFrame=%.1f,%.1f,%.1f,%.1f bottomFrame=%.1f,%.1f,%.1f,%.1f",
			phase,
			Double(top.length), Double(bottom.length),
			className(topObject), className(bottomObject),
			topObject !== bottomObject ? 1 : 0,
			ownerName(topOwner), ownerName(bottomOwner),
			Double(topFrame.origin.x), Double(topFrame.origin.y), Double(topFrame.size.width), Double(topFrame.size.height),
			Double(bottomFrame.origin.x), Double(bottomFrame.origin.y), Double(bottomFrame.size.width), Double(bottomFrame.size.height)))

		let safeArea = view.safeAreaLayoutGuide as AnyObject
		log(String(format: "GA_IDENTITY phase=%@ topProperty=1 bottomProperty=1 topIsSafe=%d bottomIsSafe=%d topOwnerIsView=%d bottomOwnerIsView=%d",
			phase,
			topObject === safeArea ? 1 : 0,
			bottomObject === safeArea ? 1 : 0,
			topOwner === view ? 1 : 0,
			bottomOwner === view ? 1 : 0))

		for constraint in view.constraints {
			let first = constraint.firstItem as AnyObject?
			let second = constraint.secondItem as AnyObject?
			let firstIsTop = first.map { $0 === topObject } ?? false
			let secondIsTop = second.map { $0 === topObject } ?? false
			let firstIsBottom = first.map { $0 === bottomObject } ?? false
			let secondIsBottom = second.map { $0 === bottomObject } ?? false
			if !firstIsTop && !secondIsTop && !firstIsBottom && !secondIsBottom {
				continue
			}
			log(String(format: "GA_CONSTRAINT phase=%@ first=%@.%ld second=%@.%ld relation=%ld constant=%.1f priority=%.1f active=%d",
				phase,
				className(first), constraint.firstAttribute.rawValue,
				className(second), constraint.secondAttribute.rawValue,
				constraint.relation.rawValue,
				Double(constraint.constant), Double(constraint.priority.rawValue),
				constraint.isActive ? 1 : 0))
		}
	}

	func finish(_ controller: UIViewController?) {
		if let controller = controller {
			attachStatus(to: controller)
		}
		statusLabel?.text = "GA_DONE"
		log("GA_DONE")
	}

	private func attachStatus(to controller: UIViewController) {
		let label: UILabel
		if let existing = statusLabel {
			label = existing
		} else {
			label = UILabel(frame: CGRect(x: 0, y: 60, width: 200, height: 20))
			label.accessibilityIdentifier = "ga.status"
			label.text = "measuring"
			label.textColor = UIColor.clear
			label.backgroundColor = UIColor.clear
			statusLabel = label
		}
		if label.superview !== controller.view {
			label.removeFromSuperview()
			controller.view.addSubview(label)
		}
	}

	private func log(_ line: String) {
		FileHandle.standardOutput.write(Data((line + "\n").utf8))
		let url = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("ipa-hle-console.log")
		let data = Data((line + "\n").utf8)
		if let handle = try? FileHandle(forWritingTo: url) {
			handle.seekToEndOfFile()
			handle.write(data)
			handle.closeFile()
		} else {
			FileManager.default.createFile(atPath: url.path, contents: data)
		}
	}

	private func className(_ object: AnyObject?) -> String {
		guard let object = object else { return "none" }
		return String(cString: object_getClassName(object))
	}

	private func ownerName(_ view: UIView?) -> String {
		guard let view = view else { return "none" }
		return String(cString: object_getClassName(view))
	}
}

final class PhaseViewController: UIViewController {
	private let phase: String

	init(phase: String) {
		self.phase = phase
		super.init(nibName: nil, bundle: nil)
	}

	required init?(coder: NSCoder) {
		fatalError("init(coder:) is not used")
	}

	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		GuideProbe.shared.measure(self, phase: phase)
		guard phase == "nav" else { return }
		navigationController?.setNavigationBarHidden(true, animated: false)
		DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
			self.view.setNeedsLayout()
			self.view.layoutIfNeeded()
			GuideProbe.shared.measure(self, phase: "bar-hidden")
			GuideProbe.shared.finish(self)
		}
	}
}
