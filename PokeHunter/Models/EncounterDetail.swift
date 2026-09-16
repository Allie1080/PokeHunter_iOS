import Foundation

struct EncounterDetail: Identifiable, Equatable {
    let locationArea: String    
    let method: String          
    let minLevel: Int
    let maxLevel: Int
    let chance: Int             
    let versionSlug: String     

    var id: String { "\(locationArea)-\(method)-\(minLevel)-\(maxLevel)-\(chance)" }

    var locationDisplayName: String {
        var slug = locationArea
        if slug.hasSuffix("-area") { slug = String(slug.dropLast(5)) }

        for region in Constants.Generations.regions.values {
            let prefix = region.lowercased() + "-"
            if slug.hasPrefix(prefix) {
                slug = String(slug.dropFirst(prefix.count))
                break
            }
        }

        return slug.isEmpty ? locationArea.capitalizedWords : slug.capitalizedWords
    }

    var levelLabel: String {
        minLevel == maxLevel ? "Level \(minLevel)" : "Level \(minLevel)–\(maxLevel)"
    }

    var chanceLabel: String { "\(chance)%" }
}

struct EncounterGroup: Identifiable, Equatable {
    let method: String
    let encounters: [EncounterDetail]

    var id: String { method }

    var displayName: String { Constants.EncounterMethods.displayName(for: method) }
}
