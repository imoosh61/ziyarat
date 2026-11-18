import UIKit

/// ذاكرة مؤقتة للصور حتى لا تُقرأ من القرص في كل إعادة رسم.
final class PhotoCache {

    static let shared = PhotoCache()

    private let cache = NSCache<NSString, UIImage>()

    private init() {
        cache.countLimit = 120
    }

    func image(for ref: PhotoRef) -> UIImage? {
        let key = ref.id.uuidString as NSString
        if let cached = cache.object(forKey: key) { return cached }
        guard let image = FileStorage.shared.loadPhoto(ref) else { return nil }
        cache.setObject(image, forKey: key)
        return image
    }

    func store(_ image: UIImage, for ref: PhotoRef) {
        cache.setObject(image, forKey: ref.id.uuidString as NSString)
    }

    func remove(_ ref: PhotoRef) {
        cache.removeObject(forKey: ref.id.uuidString as NSString)
    }

    func clear() {
        cache.removeAllObjects()
    }
}
