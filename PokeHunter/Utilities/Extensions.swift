import Foundation
import SwiftUI

extension Color {
    init(hex: String) {
        let cleaned = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var value: UInt64 = 0
        Scanner(string: cleaned).scanHexInt64(&value)

        let a, r, g, b: UInt64
        switch cleaned.count {
        case 6:
            (a, r, g, b) = (255, value >> 16, value >> 8 & 0xFF, value & 0xFF)
        case 8:
            (a, r, g, b) = (value >> 24, value >> 16 & 0xFF, value >> 8 & 0xFF, value & 0xFF)
        default:
            (a, r, g, b) = (255, 158, 158, 158)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

extension String {
    var capitalizedWords: String {
        split(whereSeparator: { $0 == "-" || $0 == " " })
            .map { $0.prefix(1).uppercased() + $0.dropFirst() }
            .joined(separator: " ")
    }

    var pokemonDisplayName: String {
        switch lowercased() {
        case "nidoran-f": return "Nidoran♀"
        case "nidoran-m": return "Nidoran♂"
        case "mr-mime": return "Mr. Mime"
        case "mime-jr": return "Mime Jr."
        case "farfetchd": return "Farfetch'd"
        case "ho-oh": return "Ho-Oh"
        case "porygon-z": return "Porygon-Z"
        case "type-null": return "Type: Null"
        case "jangmo-o": return "Jangmo-o"
        case "hakamo-o": return "Hakamo-o"
        case "kommo-o": return "Kommo-o"
        case "tapu-koko": return "Tapu Koko"
        case "tapu-lele": return "Tapu Lele"
        case "tapu-bulu": return "Tapu Bulu"
        case "tapu-fini": return "Tapu Fini"
        default: return capitalizedWords
        }
    }
}

extension Int {
    var pokedexNumber: String { String(format: "#%03d", self) }
}

extension Double {
    var multiplierLabel: String {
        switch self {
        case 0: return "×0"
        case 0.25: return "×¼"
        case 0.5: return "×½"
        case 1: return "×1"
        case 2: return "×2"
        case 4: return "×4"
        default:
            let trimmed = self == rounded() ? String(Int(self)) : String(format: "%.2g", self)
            return "×\(trimmed)"
        }
    }
}

extension Int {
    // decimeters
    var heightLabel: String { String(format: "%.1fm", Double(self) / 10) }

    // hectograms.
    var weightLabel: String { String(format: "%.1fkg", Double(self) / 10) }
}
