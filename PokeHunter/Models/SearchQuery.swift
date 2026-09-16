import Foundation

struct SearchQuery: Equatable {
    var anyOfTypes: [String] = []           
    var allOfTypes: [String] = []           
    var excludeTypes: [String] = []         
    var includeGenerations: [Int] = []      
    var excludeGenerations: [Int] = []      
    var generationRangeMin: Int? = nil      
    var generationRangeMax: Int? = nil      
    var nameQuery: String = ""              

    var excludeLegendary: Bool = false
    var excludeMythical: Bool = false

    var onlyLegendary: Bool = false
    var onlyMythical: Bool = false

    var rawText: String = ""

    var isEmpty: Bool {
        self == SearchQuery(rawText: rawText)
    }

    init(rawText: String = "") {
        self.rawText = rawText
    }
}
