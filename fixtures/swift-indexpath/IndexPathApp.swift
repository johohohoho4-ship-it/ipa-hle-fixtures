import UIKit
import Foundation
import Darwin

/// One `IP_` line per observation; the simulator console file keeps stdout.
func fixtureLog(_ line: String) {
    let text = line + "\n"
    _ = text.withCString { write(1, $0, strlen($0)) }
}

func indexList(_ path: IndexPath) -> String {
    "[" + path.map { String($0) }.joined(separator: ", ") + "]"
}

/// Measurements for Sol's C6/F1 prerequisite: IndexPath layout, indices, copy
/// semantics and the Swift <-> NSIndexPath round trip. Every line is an
/// observation; no value is asserted here.
enum IndexPathMeasurement {
    static func run() {
        fixtureLog("IP_START")
        fixtureLog("IP_LAYOUT IndexPath size=\(MemoryLayout<IndexPath>.size)"
                   + " stride=\(MemoryLayout<IndexPath>.stride)"
                   + " align=\(MemoryLayout<IndexPath>.alignment)"
                   + " NSIndexPath size=\(MemoryLayout<NSIndexPath>.size)"
                   + " stride=\(MemoryLayout<NSIndexPath>.stride)"
                   + " align=\(MemoryLayout<NSIndexPath>.alignment)")

        let empty = IndexPath()
        fixtureLog("IP_EMPTY count=\(empty.count) isEmpty=\(empty.isEmpty)"
                   + " indices=\(indexList(empty))"
                   + " type=\(String(describing: type(of: empty)))"
                   + " description=\(empty.description)")

        let rowSection = IndexPath(row: 2, section: 3)
        fixtureLog("IP_ROW_SECTION indices=\(indexList(rowSection)) count=\(rowSection.count)"
                   + " section=\(rowSection.section) row=\(rowSection.row) item=\(rowSection.item)")

        let single = IndexPath(index: 7)
        fixtureLog("IP_SINGLE indices=\(indexList(single)) count=\(single.count)"
                   + " first=\(single[0])")

        let many = IndexPath(indexes: [1, 2, 3])
        fixtureLog("IP_INDEXES indices=\(indexList(many)) count=\(many.count)"
                   + " sub0=\(many[0]) sub1=\(many[1]) sub2=\(many[2])"
                   + " start=\(many.startIndex) end=\(many.endIndex)")

        let base = IndexPath(row: 0, section: 0)
        var appended = base
        appended.append(4)
        fixtureLog("IP_APPEND base=\(indexList(base)) appended=\(indexList(appended))"
                   + " addingInt=\(indexList(base.appending(5)))"
                   + " addingPath=\(indexList(base.appending(IndexPath(indexes: [6, 7]))))")

        let original = IndexPath(indexes: [1, 2])
        let copy = original
        var mutated = copy
        mutated.append(3)
        let originalObject = original as NSIndexPath
        let copyObject = copy as NSIndexPath
        let mutatedObject = mutated as NSIndexPath
        fixtureLog("IP_COPY original=\(indexList(original)) copy=\(indexList(copy))"
                   + " mutated=\(indexList(mutated))"
                   + " sameObjectAfterCopy=\(originalObject === copyObject)"
                   + " sameObjectAfterMutation=\(originalObject === mutatedObject)")

        let swiftPath = IndexPath(indexes: [1, 2])
        let bridged = swiftPath as NSIndexPath
        let roundTrip = bridged as IndexPath
        fixtureLog("IP_BRIDGE swift=\(indexList(swiftPath))"
                   + " nsType=\(String(describing: type(of: bridged)))"
                   + " objcClass=\(NSStringFromClass(type(of: bridged)))"
                   + " nsLength=\(bridged.length)"
                   + " nsDescription=\(bridged.description)"
                   + " roundTrip=\(indexList(roundTrip))"
                   + " roundTripCount=\(roundTrip.count)"
                   + " roundTripEqual=\(roundTrip == swiftPath)"
                   + " roundTripSameObject=\((roundTrip as NSIndexPath) === bridged)")

        fixtureLog("IP_EQ rowEqualsIndexes=\(IndexPath(row: 0, section: 0) == IndexPath(indexes: [0, 0]))"
                   + " oneVsTwo=\(IndexPath(indexes: [1]) == IndexPath(indexes: [1, 1]))"
                   + " emptyEqualsEmpty=\(IndexPath() == IndexPath())"
                   + " emptyVsZero=\(IndexPath() == IndexPath(indexes: [0]))")

        var visited: [Int] = []
        for index in many { visited.append(index) }
        fixtureLog("IP_ITERATION indices=[\(visited.map { String($0) }.joined(separator: ", "))]"
                   + " count=\(visited.count)")

        fixtureLog("IP_DONE")
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
        IndexPathMeasurement.run()

        let window = UIWindow(frame: UIScreen.main.bounds)
        let controller = UIViewController()
        controller.view.backgroundColor = .white
        let label = UILabel(frame: CGRect(x: 20, y: 100, width: 320, height: 44))
        label.text = "ready"
        label.accessibilityIdentifier = "ip.status"
        controller.view.addSubview(label)
        window.rootViewController = controller
        window.makeKeyAndVisible()
        self.window = window
        return true
    }
}
