import Foundation
import UIKit

enum AppError: LocalizedError, Identifiable {
    case save(String)
    case load(String)
    case photo(String)
    case pdf(String)

    var id: String { errorDescription ?? "error" }

    var errorDescription: String? {
        switch self {
        case .save(let detail):  return "تعذّر الحفظ: \(detail)"
        case .load(let detail):  return "تعذّر قراءة البيانات: \(detail)"
        case .photo(let detail): return "مشكلة في الصورة: \(detail)"
        case .pdf(let detail):   return "تعذّر إنشاء ملف PDF: \(detail)"
        }
    }
}

/// قراءة وكتابة ملفات التطبيق (JSON + الشعار + الصور) داخل مجلد المستندات.
struct FileStorage {

    static let shared = FileStorage()

    private let fm = FileManager.default

    var documents: URL {
        fm.urls(for: .documentDirectory, in: .userDomainMask).first
            ?? fm.temporaryDirectory
    }

    var photosDirectory: URL {
        documents.appendingPathComponent("Photos", isDirectory: true)
    }

    var logoURL: URL {
        documents.appendingPathComponent("letterhead-logo.png")
    }

    private init() {
        try? fm.createDirectory(at: photosDirectory, withIntermediateDirectories: true)
    }

    // MARK: - JSON

    private var encoder: JSONEncoder {
        let e = JSONEncoder()
        e.outputFormatting = [.prettyPrinted, .sortedKeys]
        e.dateEncodingStrategy = .iso8601
        return e
    }

    private var decoder: JSONDecoder {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }

    func save<T: Encodable>(_ value: T, as fileName: String) throws {
        do {
            let data = try encoder.encode(value)
            let url = documents.appendingPathComponent(fileName)
            try data.write(to: url, options: .atomic)
        } catch {
            throw AppError.save(error.localizedDescription)
        }
    }

    func load<T: Decodable>(_ type: T.Type, from fileName: String) throws -> T? {
        let url = documents.appendingPathComponent(fileName)
        guard fm.fileExists(atPath: url.path) else { return nil }
        do {
            let data = try Data(contentsOf: url)
            return try decoder.decode(type, from: data)
        } catch {
            throw AppError.load(error.localizedDescription)
        }
    }

    // MARK: - الشعار

    func saveLogo(_ image: UIImage) throws {
        guard let data = image.pngData() else {
            throw AppError.photo("تنسيق الشعار غير مدعوم")
        }
        do {
            try data.write(to: logoURL, options: .atomic)
        } catch {
            throw AppError.save(error.localizedDescription)
        }
    }

    func loadLogo() -> UIImage? {
        guard fm.fileExists(atPath: logoURL.path),
              let data = try? Data(contentsOf: logoURL) else { return nil }
        return UIImage(data: data)
    }

    func deleteLogo() {
        try? fm.removeItem(at: logoURL)
    }

    // MARK: - صور الأسئلة

    func photoURL(for ref: PhotoRef) -> URL {
        photosDirectory.appendingPathComponent(ref.fileName)
    }

    func savePhoto(_ image: UIImage, for ref: PhotoRef) throws {
        let resized = image.downscaled(maxDimension: 2000)
        guard let data = resized.jpegData(compressionQuality: 0.85) else {
            throw AppError.photo("تعذّر ضغط الصورة")
        }
        do {
            try fm.createDirectory(at: photosDirectory, withIntermediateDirectories: true)
            try data.write(to: photoURL(for: ref), options: .atomic)
        } catch {
            throw AppError.save(error.localizedDescription)
        }
    }

    func loadPhoto(_ ref: PhotoRef) -> UIImage? {
        let url = photoURL(for: ref)
        guard fm.fileExists(atPath: url.path),
              let data = try? Data(contentsOf: url) else { return nil }
        return UIImage(data: data)
    }

    func deletePhoto(_ ref: PhotoRef) {
        try? fm.removeItem(at: photoURL(for: ref))
    }
}

extension UIImage {
    /// تصغير الصور الكبيرة قبل التخزين — يحافظ على الأداء وحجم ملف PDF.
    func downscaled(maxDimension: CGFloat) -> UIImage {
        let longest = max(size.width, size.height)
        guard longest > maxDimension, longest > 0 else { return self }
        let scale = maxDimension / longest
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        format.opaque = false
        return UIGraphicsImageRenderer(size: newSize, format: format).image { _ in
            draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}
