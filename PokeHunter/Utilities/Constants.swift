import Foundation
import SwiftUI

enum Constants {
    enum API {
        static let baseURL = URL(string: "https://pokeapi.co/api/v2")!

        static let spriteBaseURL = URL(
            string: "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon"
        )!

        static func spriteURL(for pokemonId: Int, shiny: Bool = false) -> URL {
            let folder = shiny ? spriteBaseURL.appendingPathComponent("shiny") : spriteBaseURL
            return folder.appendingPathComponent("\(pokemonId).png")
        }
    }

    /// just gen1–7
    enum Generations {
        static let supported = 1...7

        static let ranges: [Int: ClosedRange<Int>] = [
            1: 1...151,
            2: 152...251,
            3: 252...386,
            4: 387...493,
            5: 494...649,
            6: 650...721,
            7: 722...809,
        ]

        static let regions: [Int: String] = [
            1: "Kanto", 2: "Johto", 3: "Hoenn", 4: "Sinnoh",
            5: "Unova", 6: "Kalos", 7: "Alola",
        ]

        static let maxPokemonId = 809

        static func generation(for pokemonId: Int) -> Int? {
            ranges.first { $0.value.contains(pokemonId) }?.key
        }

        static func region(for pokemonId: Int) -> String? {
            generation(for: pokemonId).flatMap { regions[$0] }
        }
    }

    enum Rarity {
        static let legendaryIds: Set<Int> = [
            // gen1
            144, 145, 146, 150,
            // gen2
            243, 244, 245, 249, 250,
            // gen3
            377, 378, 379, 380, 381, 382, 383, 384,
            // gen4
            480, 481, 482, 483, 484, 485, 486, 487, 488,
            // gen5
            638, 639, 640, 641, 642, 643, 644, 645, 646,
            // gen6
            716, 717, 718,
            // gen7 (including Ultra Beasts)
            772, 773, 785, 786, 787, 788, 789, 790, 791, 792,
            793, 794, 795, 796, 797, 798, 799, 800, 803, 804, 805, 806,
        ]

        static let mythicalIds: Set<Int> = [
            // gen1
            151,                      
            // gen2
            251,                      
            // gen3
            385, 386,                 
            // gen4
            489, 490, 491, 492, 493,  
            // gen5
            494, 647, 648, 649,       
            // gen6
            719, 720, 721,            
            // gen7
            801, 802, 807, 808, 809,  
        ]

        static func isLegendary(_ id: Int) -> Bool { legendaryIds.contains(id) }
        static func isMythical(_ id: Int) -> Bool { mythicalIds.contains(id) }
    }


    enum PokemonTypes {
        static let all = TypeCatalog.all

        private static let hexes: [String: String] = [
            "normal": "A8A77A", "fire": "EE8130", "water": "6390F0",
            "electric": "F7D02C", "grass": "7AC74C", "ice": "96D9D6",
            "fighting": "C22E28", "poison": "A33EA1", "ground": "E2BF65",
            "flying": "A98FF3", "psychic": "F95587", "bug": "A6B91A",
            "rock": "B6A136", "ghost": "735797", "dragon": "6F35FC",
            "dark": "705746", "steel": "B7B7CE", "fairy": "D685AD",
        ]

        static func color(for type: String) -> Color {
            Color(hex: hexes[type.lowercased()] ?? "9E9E9E")
        }
    }


    enum EncounterMethods {
        static func color(for method: String) -> Color {
            let m = method.lowercased()
            if m.contains("walk") { return Color(hex: "4CAF50") }        // green
            if m.contains("surf") { return Color(hex: "26A69A") }        // teal
            if m.contains("rod") || m.contains("fish") { return Color(hex: "2196F3") }   // blue
            if m.contains("gift") || m.contains("only-one") { return Color(hex: "FFB300") } // gold
            if m.contains("rock-smash") { return Color(hex: "8D6E63") }  // brown
            if m.contains("headbutt") { return Color(hex: "689F38") }
            if m.contains("dark-grass") || m.contains("grass") { return Color(hex: "558B2F") }
            if m.contains("cave") { return Color(hex: "6D4C41") }
            if m.contains("super-rod") { return Color(hex: "1565C0") }
            return Color(hex: "78909C")                                   // slate fallback
        }

        static func displayName(for method: String) -> String {
            method.replacingOccurrences(of: "-", with: " ").capitalizedWords
        }
    }


    enum Sprites {
        // 1-in-512 shiny sprite odds in the app instead of real, rarer odds
        static let randomShinyOdds = 512

        static var rollsShiny: Bool {
            Int.random(in: 0..<max(1, randomShinyOdds)) == 0
        }
    }


    enum Stats {
        static let maxBaseStat = 255

        static let displayNames: [String: String] = [
            "hp": "HP",
            "attack": "Atk",
            "defense": "Def",
            "special-attack": "Sp. Atk",
            "special-defense": "Sp. Def",
            "speed": "Speed",
        ]

        static let order = ["hp", "attack", "defense", "special-attack", "special-defense", "speed"]
    }


    enum Copy {
        static let statsDisclaimer = "Stats shown are current values, not generation-specific."
        static let searchPlaceholder = #"e.g. "milotic" or "fire gen3+""#
    }
}
