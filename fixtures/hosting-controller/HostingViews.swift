import SwiftUI
import UIKit

func hcLine(_ text: String) {
    print(text)
}

struct LeftView: View {
    @State private var taps = 0

    var body: some View {
        VStack(spacing: 8) {
            Text("Left").accessibilityIdentifier("hc.left.title")
            Button("Left \(taps)") {
                taps += 1
                hcLine("HC_TAP left=\(taps)")
            }
            .accessibilityIdentifier("hc.left.button")
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(white: 0.95))
    }
}

struct RightView: View {
    var body: some View {
        VStack(spacing: 8) {
            Text("Right").accessibilityIdentifier("hc.right.title")
            Text("static").accessibilityIdentifier("hc.right.value")
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(white: 0.9))
    }
}

struct ReplacedView: View {
    var body: some View {
        VStack(spacing: 8) {
            Text("Replaced").accessibilityIdentifier("hc.replaced.title")
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(white: 0.85))
    }
}

final class ProbeHost<Content: View>: UIHostingController<Content> {
    let name: String
    var appearCount = 0

    init(name: String, rootView: Content) {
        self.name = name
        super.init(rootView: rootView)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not used")
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        hcLine("HC_CALLBACK \(name) willAppear")
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        appearCount += 1
        hcLine("HC_CALLBACK \(name) didAppear \(appearCount)")
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        hcLine("HC_CALLBACK \(name) didDisappear")
    }
}
