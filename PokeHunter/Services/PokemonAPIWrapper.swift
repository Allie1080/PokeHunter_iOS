import Foundation

#if canImport(PokemonAPI)
import PokemonAPI
#endif

enum PokemonAPIError: LocalizedError {
    case badURL(String)
    case badResponse(Int)
    case notFound(String)
    case decoding(String)

    var errorDescription: String? {
        switch self {
        case .badURL:                return "Couldn't build that request."
        case .badResponse(let code): return "PokeAPI returned HTTP \(code)."
        case .notFound(let what):    return "Couldn't find \(what)."
        case .decoding(let what):    return "Couldn't read the \(what) data."
        }
    }
}

actor PokemonAPIWrapper {

    static let shared = PokemonAPIWrapper()

    #if canImport(PokemonAPI)
    private let api = PokemonAPI()
    #endif

    private let session: URLSession
    private let decoder: JSONDecoder

    private var typeCache: [String: TypeDTO] = [:]
    private var indexCache: [PokemonSummary] = []
    private var detailCache: [Int: PokemonDetail] = [:]
    private var speciesCache: [Int: PokemonSpeciesInfo] = [:]

    private init() {
        let config = URLSessionConfiguration.default
        // 50 MB on disk keeps repeat launches quick without growing unbounded
        config.urlCache = URLCache(memoryCapacity: 10 * 1024 * 1024,
                                   diskCapacity: 50 * 1024 * 1024,
                                   diskPath: "pokehunter-api")
        config.requestCachePolicy = .returnCacheDataElseLoad
        session = URLSession(configuration: config)

        decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
    }

    func fetchIndex() async throws -> [PokemonSummary] {
        if !indexCache.isEmpty { return indexCache }

        let limit = Constants.Generations.maxPokemonId
        let dto: PokemonIndexDTO = try await get("pokemon", query: ["limit": "\(limit)", "offset": "0"],
                                                 label: "Pokédex")

        let summaries: [PokemonSummary] = (dto.results ?? []).enumerated().compactMap { offset, entry in
            guard let name = entry.name else { return nil }
            let id = entry.resourceId ?? (offset + 1)
            guard Constants.Generations.generation(for: id) != nil else { return nil }
            return PokemonSummary(id: id, name: name)
        }

        indexCache = summaries
        return summaries
    }


    func fetchDetail(id: Int) async throws -> PokemonDetail {
        if let cached = detailCache[id] { return cached }
        let detail = try await loadDetail(idOrName: String(id))
        detailCache[detail.id] = detail
        return detail
    }

    func fetchDetail(nameOrId: String) async throws -> PokemonDetail {
        let key = nameOrId.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if let id = Int(key), let cached = detailCache[id] { return cached }

        let detail = try await loadDetail(idOrName: key)
        detailCache[detail.id] = detail
        return detail
    }

    private func loadDetail(idOrName: String) async throws -> PokemonDetail {
        #if canImport(PokemonAPI)
        let pokemon = try await api.pokemonService.fetchPokemon(idOrName)
        return try Self.map(pokemon)
        #else
        let dto: PokemonDTO = try await get("pokemon/\(idOrName)", label: "Pokémon")
        return try Self.map(dto)
        #endif
    }

    func fetchDamageRelations(for type: String) async throws -> [String: Double] {
        let dto = try await loadType(type)
        var relations: [String: Double] = [:]

        for entry in dto.damageRelations?.doubleDamageFrom ?? [] {
            if let name = entry.name { relations[name] = 2.0 }
        }
        for entry in dto.damageRelations?.halfDamageFrom ?? [] {
            if let name = entry.name { relations[name] = 0.5 }
        }
        for entry in dto.damageRelations?.noDamageFrom ?? [] {
            if let name = entry.name { relations[name] = 0.0 }
        }

        return relations
    }

    func fetchPokemonIds(ofType type: String) async throws -> Set<Int> {
        let dto = try await loadType(type)
        let ids = (dto.pokemon ?? []).compactMap { $0.pokemon?.resourceId }
        return Set(ids.filter { Constants.Generations.generation(for: $0) != nil })
    }

    private func loadType(_ name: String) async throws -> TypeDTO {
        let key = name.lowercased()
        if let cached = typeCache[key] { return cached }

        let dto: TypeDTO = try await get("type/\(key)", label: "type")
        typeCache[key] = dto
        return dto
    }


    func fetchSpecies(id: Int) async throws -> PokemonSpeciesInfo {
        if let cached = speciesCache[id] { return cached }

        let dto: SpeciesDTO = try await get("pokemon-species/\(id)", label: "species")
        let info = PokemonSpeciesInfo(
            id: dto.id ?? id,
            isLegendary: dto.isLegendary ?? Constants.Rarity.isLegendary(id),
            isMythical: dto.isMythical ?? Constants.Rarity.isMythical(id),
            genderRate: dto.genderRate ?? -1,
            evolutionChainId: dto.evolutionChain?.chainId,
            generationName: dto.generation?.name
        )

        speciesCache[id] = info
        return info
    }


    func fetchEvolutionChain(id: Int) async throws -> EvolutionChainDTO {
        try await get("evolution-chain/\(id)", label: "evolution chain")
    }

    // encounters for one Pokémon in one game version
    // per-version filter happens here cause /pokemon/{id}/encounters returns location-area encounters for every version 
    func fetchEncounters(pokemonId: Int, versionSlug: String) async throws -> [EncounterDetail] {
        let areas: [LocationAreaEncounterDTO] = try await get(
            "pokemon/\(pokemonId)/encounters", label: "encounters"
        )

        var results: [EncounterDetail] = []

        for area in areas {
            let locationArea = area.locationArea?.name ?? "unknown"

            for versionDetail in area.versionDetails ?? [] {
                guard versionDetail.version?.name == versionSlug else { continue }

                for encounter in versionDetail.encounterDetails ?? [] {
                    results.append(
                        EncounterDetail(
                            locationArea: locationArea,
                            method: encounter.method?.name ?? "unknown",
                            minLevel: encounter.minLevel ?? 0,
                            maxLevel: encounter.maxLevel ?? encounter.minLevel ?? 0,
                            chance: encounter.chance ?? 0,
                            versionSlug: versionSlug
                        )
                    )
                }
            }
        }

        return results
    }

    func fetchAvailableVersions(pokemonId: Int) async throws -> Set<String> {
        let areas: [LocationAreaEncounterDTO] = try await get(
            "pokemon/\(pokemonId)/encounters", label: "encounters"
        )

        let slugs = areas
            .flatMap { $0.versionDetails ?? [] }
            .compactMap { $0.version?.name }

        return Set(slugs)
    }


    private func get<T: Decodable>(
        _ path: String,
        query: [String: String] = [:],
        label: String
    ) async throws -> T {
        var components = URLComponents(
            url: Constants.API.baseURL.appendingPathComponent(path),
            resolvingAgainstBaseURL: false
        )
        if !query.isEmpty {
            components?.queryItems = query.map { URLQueryItem(name: $0.key, value: $0.value) }
        }

        guard let url = components?.url else { throw PokemonAPIError.badURL(path) }

        let (data, response) = try await session.data(from: url)

        if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
            throw http.statusCode == 404
                ? PokemonAPIError.notFound(label)
                : PokemonAPIError.badResponse(http.statusCode)
        }

        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw PokemonAPIError.decoding(label)
        }
    }
}


private extension PokemonAPIWrapper {

    static func map(_ dto: PokemonDTO) throws -> PokemonDetail {
        guard let id = dto.id, let name = dto.name else {
            throw PokemonAPIError.decoding("Pokémon")
        }

        let types = (dto.types ?? [])
            .sorted { ($0.slot ?? 0) < ($1.slot ?? 0) }
            .compactMap { $0.type?.name }

        let stats = (dto.stats ?? []).compactMap { slot -> StatValue? in
            guard let key = slot.stat?.name else { return nil }
            return StatValue(key: key, value: slot.baseStat ?? 0)
        }

        let abilities = (dto.abilities ?? [])
            .sorted { ($0.slot ?? 0) < ($1.slot ?? 0) }
            .compactMap { slot -> AbilityEntry? in
                guard let name = slot.ability?.name else { return nil }
                return AbilityEntry(name: name, isHidden: slot.isHidden ?? false)
            }

        var moves: [MoveEntry] = []
        for slot in dto.moves ?? [] {
            guard let moveName = slot.move?.name else { continue }
            for detail in slot.versionGroupDetails ?? [] {
                guard let versionGroup = detail.versionGroup?.name else { continue }
                moves.append(
                    MoveEntry(
                        name: moveName,
                        learnMethod: detail.moveLearnMethod?.name ?? "unknown",
                        levelLearnedAt: detail.levelLearnedAt ?? 0,
                        versionGroup: versionGroup
                    )
                )
            }
        }

        let s = dto.sprites
        let sprites = SpriteSet(
            frontDefault: url(s?.frontDefault),
            frontShiny: url(s?.frontShiny),
            frontFemale: url(s?.frontFemale),
            frontShinyFemale: url(s?.frontShinyFemale),
            backDefault: url(s?.backDefault),
            backShiny: url(s?.backShiny),
            backFemale: url(s?.backFemale),
            backShinyFemale: url(s?.backShinyFemale)
        )

        return PokemonDetail(
            id: id,
            name: name,
            types: types,
            height: dto.height ?? 0,
            weight: dto.weight ?? 0,
            stats: stats,
            abilities: abilities,
            moves: moves,
            sprites: sprites
        )
    }

    static func url(_ string: String?) -> URL? {
        guard let string, !string.isEmpty else { return nil }
        return URL(string: string)
    }

    #if canImport(PokemonAPI)
    static func map(_ pokemon: PKMPokemon) throws -> PokemonDetail {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        do {
            let data = try encoder.encode(pokemon)
            return try map(decoder.decode(PokemonDTO.self, from: data))
        } catch {
            throw PokemonAPIError.decoding("Pokémon")
        }
    }
    #endif
}
