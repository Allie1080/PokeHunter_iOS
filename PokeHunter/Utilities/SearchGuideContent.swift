import Foundation

enum SearchGuideContent {
    struct Entry: Identifiable, Equatable {
        let syntax: String
        let explanation: String

        var id: String { syntax }
    }

    struct Section: Identifiable, Equatable {
        let title: String
        let entries: [Entry]

        var id: String { title }
    }

    static let sections: [Section] = [
        Section(title: "Basic Syntax", entries: [
            Entry(syntax: "fire",
                  explanation: "Only Fire-types"),
            Entry(syntax: "fire water",
                  explanation: "Fire OR Water-types"),
            Entry(syntax: "fire+water",
                  explanation: "Dual types, Fire & Water"),
            Entry(syntax: "-fire",
                  explanation: "Excluding Fire-types"),
        ]),

        Section(title: "Generation Filters", entries: [
            Entry(syntax: "gen5",
                  explanation: "Only from Generation 5"),
            Entry(syntax: "gen5+",
                  explanation: "Generation 5 and above"),
            Entry(syntax: "gen5-",
                  explanation: "Generation 5 and below"),
            Entry(syntax: "-gen2",
                  explanation: "Excluding Generation 2"),
        ]),

        Section(title: "Special Filters", entries: [
            Entry(syntax: "name:pika",
                  explanation: "Name contains \u{201C}pika\u{201D}"),
            Entry(syntax: "legendary",
                  explanation: "Only legendaries"),
            Entry(syntax: "mythical",
                  explanation: "Only mythicals"),
            Entry(syntax: "-legendary",
                  explanation: "Excluding legendaries — mythicals still show"),
            Entry(syntax: "-mythical",
                  explanation: "Excluding mythicals — legendaries still show"),
        ]),

        Section(title: "Samples", entries: [
            Entry(syntax: "gen5- -gen2 -water",
                  explanation: "Generation 5 and below, excluding Generation 2 and Water-types"),
            Entry(syntax: "fire gen5+ -legendary",
                  explanation: "Fire-types from Generation 5 onwards, excluding legendaries"),
            Entry(syntax: "name:mew mythical",
                  explanation: "Mythicals whose name contains \u{201C}mew\u{201D}"),
            Entry(syntax: "water+flying gen3-",
                  explanation: "Water & Flying dual-types up to Generation 3"),
        ]),
    ]

    static let footnote = "Legendary and Mythical are separate categories. "
        + "To hide both, type -legendary -mythical."

    static var allExamples: [String] {
        sections.flatMap { $0.entries.map(\.syntax) }
    }
}
