import UIKit

/// A protocol defining an asynchronous service for loading images.
protocol ImageServiceProtocol {
    /// Loads an image from a given URL string.
    func loadImage(from urlString: String) async -> UIImage?
}

/// An `actor` responsible for downloading and caching images.
actor ImageService: ImageServiceProtocol {
    static let shared = ImageService()

    private let cache = ImageCache<NSString>()
    private var tasks: [String: Task<UIImage?, Never>] = [:]

    /// Loads an image from a given URL string.
    func loadImage(from urlString: String) async -> UIImage? {
        if let cachedImage = cache.image(forKey: urlString as NSString) {
            return cachedImage
        }

        if let task = tasks[urlString] {
            return await task.value
        }

        let task = Task { [weak self] () -> UIImage? in
            defer { Task { await self?.removeTask(for: urlString) } }
            guard let self else { return nil }

            guard let data = try? await NetworkService.shared.loadData(from: urlString),
                  let image = UIImage(data: data)
            else {
                return nil
            }

            guard !Task.isCancelled else { return image }

            cache.setImage(image, forKey: urlString as NSString)
            return image
        }

        tasks[urlString] = task
        return await task.value
    }

    /// Removes a task responsible for downloading an image for specific URL.
    private func removeTask(for urlString: String) {
        tasks[urlString] = nil
    }
}
