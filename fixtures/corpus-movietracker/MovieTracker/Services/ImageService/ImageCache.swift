import UIKit

/// A protocol defining a cache for storing and retrieving `UIImage` objects.
protocol ImageCacheProtocol: Sendable {
    associatedtype Key: AnyObject

    /// Stores an image in the cache for the specified key.
    func setImage(_ image: UIImage, forKey key: Key)

    /// Retrieves an image from the cache.
    func image(forKey key: Key) -> UIImage?
}

/// A thread-safe in-memory image cache based on `NSCache`.
///
/// The class is marked `@unchecked Sendable` because `NSCache` is not
/// statically `Sendable`, but is safe for concurrent use.
final class ImageCache<Key: AnyObject>: ImageCacheProtocol, @unchecked Sendable {
    private let cache = NSCache<Key, UIImage>()

    /// Stores an image in the cache for the specified key.
    func setImage(_ image: UIImage, forKey key: Key) {
        cache.setObject(image, forKey: key)
    }

    /// Retrieves an image from the cache..
    func image(forKey key: Key) -> UIImage? {
        cache.object(forKey: key)
    }
}
