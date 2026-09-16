import Foundation
import Combine

@MainActor
final class SearchGuideController: ObservableObject {

    typealias Section = SearchGuideContent.Section
    typealias Entry = SearchGuideContent.Entry

    @Published private(set) var sections: [Section] = SearchGuideContent.sections

    let footnote = SearchGuideContent.footnote
}
