import SwiftUI

struct TypeChip: View {

    let type: String
    var size: Size = .regular

    enum Size {
        case small, regular

        var font: Font { self == .small ? .caption2 : .subheadline }
        var horizontalPadding: CGFloat { self == .small ? 8 : 14 }
        var verticalPadding: CGFloat { self == .small ? 3 : 6 }
    }

    var body: some View {
        Text(type.capitalizedWords)
            .font(size.font.weight(.semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, size.horizontalPadding)
            .padding(.vertical, size.verticalPadding)
            .background(Constants.PokemonTypes.color(for: type), in: Capsule())
            .accessibilityLabel("\(type.capitalizedWords) type")
    }
}

#Preview {
    VStack(alignment: .leading, spacing: 12) {
        HStack { TypeChip(type: "grass"); TypeChip(type: "poison") }
        HStack { TypeChip(type: "fire", size: .small); TypeChip(type: "flying", size: .small) }
    }
    .padding()
}
