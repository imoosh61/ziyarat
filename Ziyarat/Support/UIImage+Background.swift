import UIKit

extension UIImage {

    /// تفريغ الخلفية البيضاء من الشعار: البكسلات الفاتحة جداً تصبح شفافة،
    /// والحواف القريبة منها تأخذ شفافية جزئية حتى لا تظهر حوافّ مسنّنة في الطباعة.
    /// - Parameter threshold: من 0.5 إلى 1.0 — كلما قلّت القيمة زاد ما يُعتبر "خلفية".
    func removingLightBackground(threshold: Double = 0.90) -> UIImage? {
        guard let source = cgImage else { return nil }

        let width = source.width
        let height = source.height
        guard width > 0, height > 0 else { return nil }

        let bytesPerPixel = 4
        let bytesPerRow = width * bytesPerPixel
        var pixels = [UInt8](repeating: 0, count: width * height * bytesPerPixel)

        guard let context = CGContext(
            data: &pixels,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: bytesPerRow,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return nil }

        context.draw(source, in: CGRect(x: 0, y: 0, width: width, height: height))

        let hi = UInt8(clamping: Int(max(0.5, min(1.0, threshold)) * 255))
        let lo = UInt8(clamping: Int(max(0.0, Double(hi) - 38)))

        for index in stride(from: 0, to: pixels.count, by: bytesPerPixel) {
            let r = pixels[index]
            let g = pixels[index + 1]
            let b = pixels[index + 2]
            let alpha = pixels[index + 3]
            guard alpha > 0 else { continue }

            let minChannel = min(r, min(g, b))

            if minChannel >= hi {
                // خلفية بيضاء خالصة
                pixels[index] = 0
                pixels[index + 1] = 0
                pixels[index + 2] = 0
                pixels[index + 3] = 0
            } else if minChannel > lo {
                // منطقة انتقالية — شفافية متدرجة لحافة ناعمة
                let span = Double(hi - lo)
                let ratio = span > 0 ? Double(minChannel - lo) / span : 0
                let newAlpha = Double(alpha) * (1 - ratio)
                let scale = newAlpha / Double(alpha)
                pixels[index] = UInt8(clamping: Int(Double(r) * scale))
                pixels[index + 1] = UInt8(clamping: Int(Double(g) * scale))
                pixels[index + 2] = UInt8(clamping: Int(Double(b) * scale))
                pixels[index + 3] = UInt8(clamping: Int(newAlpha))
            }
        }

        guard let output = context.makeImage() else { return nil }
        return UIImage(cgImage: output, scale: scale, orientation: imageOrientation)
    }
}
