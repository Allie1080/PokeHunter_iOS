import Foundation
import UIKit

actor ImageCacheService {
    static let shared = ImageCacheService()

    private let cache: NSCache<NSURL, UIImage> = {
        let cache = NSCache<NSURL, UIImage>()
        cache.countLimit = 600
        return cache
    }()

    private let session: URLSession

    // in-flight requests, so a grid scrolling past the same sprite twice only downloads it once.
    private var inFlight: [URL: Task<UIImage?, Never>] = [:]

    private init() {
        let config = URLSessionConfiguration.default
        config.urlCache = URLCache(memoryCapacity: 20 * 1024 * 1024,
                                   diskCapacity: 100 * 1024 * 1024,
                                   diskPath: "pokehunter-sprites")
        config.requestCachePolicy = .returnCacheDataElseLoad
        session = URLSession(configuration: config)
    }

    func image(for url: URL) async -> UIImage? {
        if let cached = cache.object(forKey: url as NSURL) { return cached }

        if let existing = inFlight[url] { return await existing.value }

        let task = Task<UIImage?, Never> { [session] in
            guard let (data, _) = try? await session.data(from: url),
                  let image = UIImage(data: data)
            else { return nil }
            return image
        }

        inFlight[url] = task
        let image = await task.value
        inFlight[url] = nil

        if let image { cache.setObject(image, forKey: url as NSURL) }
        return image
    }

    func clear() {
        cache.removeAllObjects()
    }
}
