import SwiftUI
import AppKit

// Accessibility Extensions for Sash

extension View {
    func accessibilityLayoutLabel(_ name: String, windowCount: Int) -> some View {
        self.accessibilityLabel("Layout \(name), \(windowCount) windows")
    }
}

struct AccessibleLayoutButton: View {
    let name: String
    let icon: String
    let windowCount: Int
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Text(icon).font(.system(size: 16))
                Text(name)
                    .font(.system(size: 12, weight: .medium))
                Spacer()
                Text("\(windowCount)")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }
            .padding(8)
            .background(Color.accentColor.opacity(0.1))
            .cornerRadius(6)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Apply layout \(name) with \(windowCount) windows")
    }
}
