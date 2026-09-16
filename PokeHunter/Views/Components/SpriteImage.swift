import SwiftUI

// cached sprite
// not an AsyncImage cause it redownloads on every reappearance
// goes through ImageCacheService so a scrolled-past sprite comes back instantly
struct SpriteImage: View {

    let url: URL?
    var size: CGFloat = 72

    @State private var image: UIImage?
    @State private var didFail = false

    var body: some View {
        Group {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .interpolation(.none)          // sprites are pixel art
                    .scaledToFit()
            } else if didFail || url == nil {
                Image(systemName: "questionmark.circle")
                    .resizable()
                    .scaledToFit()
                    .padding(size * 0.25)
                    .foregroundStyle(.tertiary)
            } else {
                ProgressView()
            }
        }
        .frame(width: size, height: size)
        .task(id: url) { await load() }
    }

    private func load() async {
        guard let url else { return }

        image = nil
        didFail = false

        let loaded = await ImageCacheService.shared.image(for: url)
        if loaded == nil { didFail = true }
        image = loaded
    }
}

#Preview {
    HStack {
        SpriteImage(url: Constants.API.spriteURL(for: 1), size: 96)
        SpriteImage(url: Constants.API.spriteURL(for: 4), size: 96)
        SpriteImage(url: nil, size: 96)
    }
}
