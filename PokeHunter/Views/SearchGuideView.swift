import SwiftUI

struct SearchGuideView: View {

    @StateObject private var controller = SearchGuideController()

    var body: some View {
        List {
            ForEach(controller.sections) { section in
                Section(section.title) {
                    ForEach(section.entries) { entry in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(entry.syntax)
                                .font(.system(.subheadline, design: .monospaced).weight(.semibold))
                                .foregroundStyle(Color.accentColor)

                            Text(entry.explanation)
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 2)
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("\(entry.syntax). \(entry.explanation)")
                    }
                }
            }

            Section {
                Text(controller.footnote)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Search Syntax Guide")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        SearchGuideView()
    }
}
