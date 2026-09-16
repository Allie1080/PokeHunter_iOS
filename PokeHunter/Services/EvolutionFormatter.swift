import Foundation

enum EvolutionFormatter {
    static func steps(from chain: EvolutionChainDTO) -> [EvolutionStep] {
        guard let root = chain.chain else { return [] }
        var steps: [EvolutionStep] = []
        walk(root, into: &steps)
        return steps
    }

    static func primarySteps(from steps: [EvolutionStep]) -> [EvolutionStep] {
        let byPair = Dictionary(grouping: steps) { "\($0.fromId)-\($0.toId)" }
        return byPair.values
            .compactMap { $0.min { $0.trigger < $1.trigger } }
            .sorted { ($0.fromId, $0.toId) < ($1.fromId, $1.toId) }
    }

    static func alternateSteps(from steps: [EvolutionStep]) -> [EvolutionStep] {
        let primaryIds = Set(primarySteps(from: steps).map(\.id))
        return steps
            .filter { !primaryIds.contains($0.id) }
            .sorted { ($0.fromId, $0.trigger.rawValue) < ($1.fromId, $1.trigger.rawValue) }
    }


    private static func walk(_ link: EvolutionChainDTO.ChainLinkDTO, into steps: inout [EvolutionStep]) {
        guard let fromName = link.species?.name,
              let fromId = link.species?.resourceId
        else { return }

        for next in link.evolvesTo ?? [] {
            guard let toName = next.species?.name,
                  let toId = next.species?.resourceId
            else { continue }

            let details = next.evolutionDetails ?? []

            if details.isEmpty {
                steps.append(
                    EvolutionStep(fromId: fromId, fromName: fromName,
                                  toId: toId, toName: toName,
                                  trigger: .other, condition: "Unknown")
                )
            } else {
                for detail in details {
                    steps.append(
                        EvolutionStep(
                            fromId: fromId, fromName: fromName,
                            toId: toId, toName: toName,
                            trigger: trigger(for: detail),
                            condition: condition(for: detail)
                        )
                    )
                }
            }

            walk(next, into: &steps)
        }
    }


    private static func trigger(
        for detail: EvolutionChainDTO.EvolutionDetailDTO
    ) -> EvolutionStep.Trigger {
        let name = detail.trigger?.name ?? ""

        switch name {
        case "level-up":
            if detail.minHappiness != nil { return .happiness }
            return .levelUp
        case "use-item":
            return .stone
        case "trade":
            return .trade
        default:
            return .other
        }
    }


    private static func condition(for detail: EvolutionChainDTO.EvolutionDetailDTO) -> String {
        var parts: [String] = []

        switch detail.trigger?.name ?? "" {
        case "level-up":
            if let level = detail.minLevel {
                parts.append("Level \(level)")
            } else if detail.minHappiness == nil, detail.minAffection == nil, detail.minBeauty == nil {
                parts.append("Level up")
            }
        case "use-item":
            if let item = detail.item?.name {
                parts.append("Use \(item.capitalizedWords)")
            } else {
                parts.append("Use item")
            }
        case "trade":
            if let species = detail.tradeSpecies?.name {
                parts.append("Trade for \(species.pokemonDisplayName)")
            } else {
                parts.append("Trade")
            }
        case "shed":
            parts.append("Level 20 with a spare Poké Ball")
        case "spin":
            parts.append("Spin while holding")
        case "tower-of-darkness", "tower-of-waters":
            parts.append("Tower challenge")
        case let other where !other.isEmpty:
            parts.append(other.capitalizedWords)
        default:
            break
        }

        if let happiness = detail.minHappiness { parts.append("happiness \(happiness)+") }
        if let affection = detail.minAffection { parts.append("affection \(affection)+") }
        if let beauty = detail.minBeauty { parts.append("beauty \(beauty)+") }
        if let held = detail.heldItem?.name { parts.append("holding \(held.capitalizedWords)") }
        if let move = detail.knownMove?.name { parts.append("knowing \(move.capitalizedWords)") }
        if let moveType = detail.knownMoveType?.name { parts.append("knowing a \(moveType.capitalizedWords) move") }
        if let location = detail.location?.name { parts.append("at \(location.capitalizedWords)") }
        if let time = detail.timeOfDay, !time.isEmpty { parts.append("during the \(time)") }
        if let party = detail.partySpecies?.name { parts.append("with \(party.pokemonDisplayName) in party") }
        if let partyType = detail.partyType?.name { parts.append("with a \(partyType.capitalizedWords)-type in party") }
        if detail.needsOverworldRain == true { parts.append("while raining") }
        if detail.turnUpsideDown == true { parts.append("holding the device upside down") }

        switch detail.gender {
        case 1: parts.append("female only")
        case 2: parts.append("male only")
        default: break
        }

        if let stats = detail.relativePhysicalStats {
            switch stats {
            case 1:  parts.append("Attack > Defense")
            case 0:  parts.append("Attack = Defense")
            case -1: parts.append("Attack < Defense")
            default: break
            }
        }

        guard let first = parts.first else { return "Unknown" }
        let rest = parts.dropFirst()
        return rest.isEmpty ? first : "\(first), \(rest.joined(separator: ", "))"
    }
}
