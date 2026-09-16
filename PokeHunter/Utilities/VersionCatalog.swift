import Foundation

struct GameVersion: Identifiable, Codable, Equatable, Hashable {
    let slug: String        
    let display: String     
    let generation: Int
    let region: String

    var hasWildEncounters: Bool = true

    var id: String { slug }
}

enum VersionCatalog {
    static let all: [GameVersion] = [
        .init(slug: "red",     display: "Red",          generation: 1, region: "Kanto"),
        .init(slug: "blue",    display: "Blue",         generation: 1, region: "Kanto"),
        .init(slug: "yellow",  display: "Yellow",       generation: 1, region: "Kanto"),
        .init(slug: "green",   display: "Green (JP)",   generation: 1, region: "Kanto"),

        .init(slug: "gold",    display: "Gold",         generation: 2, region: "Johto"),
        .init(slug: "silver",  display: "Silver",       generation: 2, region: "Johto"),
        .init(slug: "crystal", display: "Crystal",      generation: 2, region: "Johto"),

        .init(slug: "ruby",      display: "Ruby",       generation: 3, region: "Hoenn"),
        .init(slug: "sapphire",  display: "Sapphire",   generation: 3, region: "Hoenn"),
        .init(slug: "emerald",   display: "Emerald",    generation: 3, region: "Hoenn"),
        .init(slug: "firered",   display: "FireRed",    generation: 3, region: "Kanto"),
        .init(slug: "leafgreen", display: "LeafGreen",  generation: 3, region: "Kanto"),
        .init(slug: "colosseum", display: "Colosseum",  generation: 3, region: "Orre", hasWildEncounters: false),
        .init(slug: "xd",        display: "XD: Gale of Darkness", generation: 3, region: "Orre", hasWildEncounters: false),

        .init(slug: "diamond",   display: "Diamond",    generation: 4, region: "Sinnoh"),
        .init(slug: "pearl",     display: "Pearl",      generation: 4, region: "Sinnoh"),
        .init(slug: "platinum",  display: "Platinum",   generation: 4, region: "Sinnoh"),
        .init(slug: "heartgold", display: "HeartGold",  generation: 4, region: "Johto"),
        .init(slug: "soulsilver", display: "SoulSilver", generation: 4, region: "Johto"),

        .init(slug: "black",   display: "Black",        generation: 5, region: "Unova"),
        .init(slug: "white",   display: "White",        generation: 5, region: "Unova"),
        .init(slug: "black-2", display: "Black 2",      generation: 5, region: "Unova"),
        .init(slug: "white-2", display: "White 2",      generation: 5, region: "Unova"),

        .init(slug: "x",              display: "X",              generation: 6, region: "Kalos"),
        .init(slug: "y",              display: "Y",              generation: 6, region: "Kalos"),
        .init(slug: "omega-ruby",     display: "Omega Ruby",     generation: 6, region: "Hoenn"),
        .init(slug: "alpha-sapphire", display: "Alpha Sapphire", generation: 6, region: "Hoenn"),

        .init(slug: "sun",             display: "Sun",             generation: 7, region: "Alola"),
        .init(slug: "moon",            display: "Moon",            generation: 7, region: "Alola"),
        .init(slug: "ultra-sun",       display: "Ultra Sun",       generation: 7, region: "Alola"),
        .init(slug: "ultra-moon",      display: "Ultra Moon",      generation: 7, region: "Alola"),
        .init(slug: "lets-go-pikachu", display: "Let's Go, Pikachu!", generation: 7, region: "Kanto"),
        .init(slug: "lets-go-eevee",   display: "Let's Go, Eevee!",   generation: 7, region: "Kanto"),
    ]

    static func byGeneration(_ gen: Int) -> [GameVersion] {
        all.filter { $0.generation == gen }
    }

    static var huntable: [GameVersion] {
        all.filter(\.hasWildEncounters)
    }

    static func huntableByGeneration(_ gen: Int) -> [GameVersion] {
        huntable.filter { $0.generation == gen }
    }

    static func find(slug: String) -> GameVersion? {
        all.first { $0.slug == slug }
    }

    // returns an empty array for a group outside gen 1–7
    static func versions(inGroup group: String) -> [GameVersion] {
        let candidates = all.sorted { $0.slug.count > $1.slug.count }
        var remaining = Substring(group)
        var found: [GameVersion] = []

        while !remaining.isEmpty {
            let match = candidates.first { candidate in
                guard remaining.hasPrefix(candidate.slug) else { return false }
                let rest = remaining.dropFirst(candidate.slug.count)
                // must land on a separator or the end, so "sun" can't match halfway through some longer slug
                return rest.isEmpty || rest.hasPrefix("-")
            }

            guard let match else { return [] }

            found.append(match)
            remaining = remaining.dropFirst(match.slug.count)
            if remaining.hasPrefix("-") { remaining = remaining.dropFirst() }
        }

        return found
    }

    /// prevent "xd" >>> "Xd" goof
    static func displayName(forVersionGroup group: String) -> String {
        let versions = versions(inGroup: group)
        guard !versions.isEmpty else {
            return group
                .split(separator: "-")
                .map { $0.prefix(1).uppercased() + $0.dropFirst() }
                .joined(separator: " ")
        }
        return versions.map(\.display).joined(separator: "/")
    }
}