import SwiftUI
import UIKit

func hcLine(_ text: String) {
    print(text)
}

struct LeftView: View {
    var replaced: Bool = false
    @State private var taps = 0

    var body: some View {
        if replaced {
            ReplacedView()
        } else {
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
