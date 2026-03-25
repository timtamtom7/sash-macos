import SwiftUI

struct SnapPositionRow: View {
    let position: SnapPosition

    var body: some View {
        HStack(spacing: Theme.Spacing.sm) {
            // Icon
            Image(systemName: position.icon)
                .font(.system(size: 16))
                .foregroundColor(Theme.Colors.accent)
                .frame(width: 24, height: 24)

            // Label
            Text(position.rawValue)
                .font(Theme.Typography.body)
                .foregroundColor(Theme.Colors.textPrimary)

            Spacer()

            // Shortcut
            Text(position.shortcut)
                .font(Theme.Typography.shortcut)
                .foregroundColor(Theme.Colors.textTertiary)
                .padding(.horizontal, Theme.Spacing.sm)
                .padding(.vertical, 2)
                .background(Theme.Colors.surface)
                .cornerRadius(Theme.CornerRadius.small)
        }
        .padding(.vertical, Theme.Spacing.sm)
        .contentShape(Rectangle())
    }
}
