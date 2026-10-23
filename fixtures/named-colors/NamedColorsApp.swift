import UIKit
import Foundation
import Darwin

/// One `NC_` line per observation; the simulator console file keeps stdout.
func fixtureLog(_ line: String) {
    let text = line + "\n"
    _ = text.withCString { write(1, $0, strlen($0)) }
}

func components(_ color: UIColor) -> String {
    var red: CGFloat = 0
    var green: CGFloat = 0
    var blue: CGFloat = 0
    var alpha: CGFloat = 0
    guard color.getRed(&red, green: &green, blue: &blue, alpha: &alpha) else {
        return "unresolved"
    }
    return String(format: "r=%.3f g=%.3f b=%.3f a=%.3f", red, green, blue, alpha)
}

/// Named colors from `Assets.car`: light and dark variants plus an unknown name.
/// Only observations; no value is asserted here.
enum NamedColorMeasurement {
    static func run() {
        fixtureLog("NC_START")
        let dark = UITraitCollection(userInterfaceStyle: .dark)
        let light = UITraitCollection(userInterfaceStyle: .light)
        for name in ["Brand", "Accent"] {
            guard let color = UIColor(named: name) else {
                fixtureLog("NC_NAME name=\(name) nil=true")
                continue
            }
            fixtureLog("NC_NAME name=\(name) light=\(components(color.resolvedColor(with: light)))")
            fixtureLog("NC_DARK name=\(name) dark=\(components(color.resolvedColor(with: dark)))")
        }
        fixtureLog("NC_UNKNOWN name=Missing nil=\(UIColor(named: "Missing") == nil)")
        fixtureLog("NC_DONE")
    }
}

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
#if targetEnvironment(simulator)
        let log = NSTemporaryDirectory() + "ipa-hle-console.log"
        log.withCString { _ = freopen($0, "w", stdout) }
        setvbuf(stdout, nil, _IONBF, 0)
#endif
        NamedColorMeasurement.run()

        let window = UIWindow(frame: UIScreen.main.bounds)
        let controller = UIViewController()
        controller.view.backgroundColor = .white
        let label = UILabel(frame: CGRect(x: 20, y: 100, width: 320, height: 44))
        label.text = "ready"
        label.accessibilityIdentifier = "nc.status"
        controller.view.addSubview(label)
        window.rootViewController = controller
        window.makeKeyAndVisible()
        self.window = window
        return true
    }
}
