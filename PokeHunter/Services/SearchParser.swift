import Foundation

enum SearchParserError: Error, Equatable {
    case emptyNameQuery
    case invalidGeneration(String)
    case emptyTypeInAND
}

enum SearchParser {

    static func parse(_ raw: String) throws -> SearchQuery {
        var query = SearchQuery(rawText: raw)
        let tokens = raw.lowercased().split(separator: " ").map(String.init)
        for token in tokens {
            try parseToken(token, into: &query)
        }
        applyBareNameFallback(to: &query)
        return query
    }

    // TODO: fix bug with "gen-" related parser
    private static func applyBareNameFallback(to query: inout SearchQuery) {
        guard query.nameQuery.isEmpty,
              query.anyOfTypes.count == 1,
              let word = query.anyOfTypes.first,
              !TypeCatalog.isType(word)
        else { return }

        query.nameQuery = word
        query.anyOfTypes.removeAll()
    }

    private static func parseToken(_ token: String, into query: inout SearchQuery) throws {
        guard !token.isEmpty else { return }

        if token.hasPrefix("name:") {
            let name = String(token.dropFirst(5))
            guard !name.isEmpty else { throw SearchParserError.emptyNameQuery }
            query.nameQuery = name
            return
        }

        if token == "-legendary" { query.excludeLegendary = true; return }
        if token == "-mythical" { query.excludeMythical  = true; return }
        if token == "legendary" { query.onlyLegendary    = true; return }
        if token == "mythical" { query.onlyMythical     = true; return }

        if token.hasPrefix("-gen") {
            let rest = String(token.dropFirst(4))
            try parseGeneration(rest, exclude: true, into: &query)
            return
        }

        if token.hasPrefix("gen") {
            let rest = String(token.dropFirst(3))
            try parseGeneration(rest, exclude: false, into: &query)
            return
        }

        if token.contains("+") {
            let parts = token.split(separator: "+").map(String.init).filter { !$0.isEmpty }
            guard !parts.isEmpty else { throw SearchParserError.emptyTypeInAND }
            for part in parts where !query.allOfTypes.contains(part) {
                query.allOfTypes.append(part)
            }
            return
        }

        if token.hasPrefix("-") {
            let type = String(token.dropFirst())
            if !type.isEmpty && !query.excludeTypes.contains(type) {
                query.excludeTypes.append(type)
            }
            return
        }

        if !query.anyOfTypes.contains(token) {
            query.anyOfTypes.append(token)
        }
    }

    private static func parseGeneration(_ s: String, exclude: Bool, into query: inout SearchQuery) throws {
        var numberString = s
        var rangeKind: Character? = nil

        if s.hasSuffix("+") {
            rangeKind = "+"
            numberString = String(s.dropLast())
        } else if s.hasSuffix("-") {
            rangeKind = "-"
            numberString = String(s.dropLast())
        }

        guard let n = Int(numberString), (1...9).contains(n) else {
            throw SearchParserError.invalidGeneration(s)
        }

        if exclude {
            query.excludeGenerations.append(n)
            return
        }

        switch rangeKind {
        case "+": query.generationRangeMin = n
        case "-": query.generationRangeMax = n
        default:  query.includeGenerations.append(n)
        }
    }
}
