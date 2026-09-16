import SwiftUI

// shown when a screen has nothing to display
struct EmptyStateView: View {

    let systemImage: String
    let title: String
    var message: String?
    var actionTitle: String?
    var action: (() -> Void)?

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.system(size: 44))
                .foregroundStyle(.tertiary)

            Text(title)
                .font(.headline)
                .multilineTextAlignment(.center)

            if let message {
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .buttonStyle(.bordered)
                    .padding(.top, 4)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 32)
        .padding(.vertical, 48)
    }
}

#Preview {
    VStack {
        EmptyStateView(
            systemImage: "magnifyingglass",
            title: "No Pokémon match those filters",
            message: "Try removing a type or widening the generation range.",
            actionTitle: "Reset filters",
            action: {}
        )
        Divider()
        EmptyStateView(systemImage: "tray", title: "This list is empty")
    }
}
