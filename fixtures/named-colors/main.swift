import UIKit
import Foundation
import Darwin

/// One `NC_` line per observation; the simulator console file keeps stdout.
func fixtureLog(_ line: String) {
    let text = line + "\n"
    _ = text.withCString { write(1, $0, strlen($0)) }
}

func colorComponents(_ color: UIColor) -> String {
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
/// Only observations; no value is asserted here. The measurement runs as
/// top-level code before `UIApplicationMain`, so the HLE reaches the same calls
/// even when it does not deliver the app-delegate launch callback.
func measureNamedColors() {
    fixtureLog("NC_START")
    let dark = UITraitCollection(userInterfaceStyle: .dark)
    let light = UITraitCollection(userInterfaceStyle: .light)
    for name in ["Brand", "Accent"] {
        guard let color = UIColor(named: name) else {
            fixtureLog("NC_NAME name=\(name) nil=true")
            continue
        }
        fixtureLog("NC_NAME name=\(name) light=\(colorComponents(color.resolvedColor(with: light)))")
        fixtureLog("NC_DARK name=\(name) dark=\(colorComponents(color.resolvedColor(with: dark)))")
    }
    fixtureLog("NC_UNKNOWN name=Missing nil=\(UIColor(named: "Missing") == nil)")
    fixtureLog("NC_DONE")
}

class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
}

#if targetEnvironment(simulator)
let consoleLog = NSTemporaryDirectory() + "ipa-hle-console.log"
consoleLog.withCString { _ = freopen($0, "w", stdout) }
setvbuf(stdout, nil, _IONBF, 0)
#endif

measureNamedColors()

// A retained window keeps the app in the foreground for the XCUITest; the
// measurement itself does not depend on it.
let fixtureWindow = UIWindow(frame: UIScreen.main.bounds)
let fixtureController = UIViewController()
fixtureController.view.backgroundColor = .white
let fixtureLabel = UILabel(frame: CGRect(x: 20, y: 100, width: 320, height: 44))
fixtureLabel.text = "ready"
fixtureLabel.accessibilityIdentifier = "nc.status"
fixtureController.view.addSubview(fixtureLabel)
fixtureWindow.rootViewController = fixtureController
fixtureWindow.makeKeyAndVisible()

_ = UIApplicationMain(CommandLine.argc, CommandLine.unsafeArgv, nil,
                      NSStringFromClass(AppDelegate.self))
