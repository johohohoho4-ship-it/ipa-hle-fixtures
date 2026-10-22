import UIKit

final class ViewController: UIViewController {
    weak var scene: UIWindowScene?
    weak var attachedWindow: UIWindow?
    private let status = UILabel(frame: CGRect(x: 20, y: 150, width: 350, height: 80))

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        status.numberOfLines = 0
        status.textColor = .black
        status.text = "measuring scene"
        status.accessibilityIdentifier = "scene.status"
        view.addSubview(status)
    }

    private func text(_ rect: CGRect) -> String {
        String(format: "%.1f,%.1f,%.1f,%.1f", rect.origin.x, rect.origin.y, rect.width, rect.height)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        guard let scene, let window = attachedWindow else { return }
        print("SG_SCREEN=\(text(UIScreen.main.bounds))")
        print("SG_COORD=\(text(scene.coordinateSpace.bounds))")
        print("SG_WINDOW=\(text(window.bounds))")
        print("SG_MATCH=\(window.windowScene === scene ? 1 : 0)")
        let other = UIWindow(frame: CGRect(x: 0, y: 0, width: 10, height: 10))
        print("SG_SET_BEFORE=\(other.windowScene == nil ? 1 : 0)")
        other.windowScene = scene
        print("SG_SET_AFTER=\(other.windowScene === scene ? 1 : 0)")
        print("SG_PORTRAIT=\(scene.interfaceOrientation == .portrait ? 1 : 0)")
        status.text = "SG_READY"
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(alongsideTransition: nil) { [weak self] _ in
            guard let self, let scene = self.scene else { return }
            print("SG_ROTATED=\(self.text(scene.coordinateSpace.bounds))")
            print("SG_LANDSCAPE=\(scene.interfaceOrientation.isLandscape ? 1 : 0)")
            print("SG_DONE")
            self.status.text = "SG_DONE"
        }
    }
}
