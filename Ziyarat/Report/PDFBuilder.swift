import SwiftUI
import UIKit
import CoreGraphics

/// يبني ملف PDF بمقاس A4 من صفحات SwiftUI — النص يبقى نصاً داخل الملف (ليس صورة).
@MainActor
enum PDFBuilder {

    struct Output {
        let url: URL
        let pageCount: Int
    }

    /// تجهيز صفحات التقرير (تُستخدم للمعاينة داخل التطبيق وللتصدير).
    static func pages(
        visit: Visit,
        letterhead: LetterheadSettings,
        logo: UIImage?,
        images: [UUID: UIImage]
    ) -> [[ReportBlock]] {
        let blocks = ReportContentBuilder(visit: visit, letterhead: letterhead).build()
        let engine = ReportLayoutEngine(letterhead: letterhead, logo: logo, images: images)
        return engine.paginate(blocks)
    }

    static func build(
        visit: Visit,
        letterhead: LetterheadSettings,
        logo: UIImage?,
        images: [UUID: UIImage]
    ) throws -> Output {

        let pageBlocks = pages(
            visit: visit,
            letterhead: letterhead,
            logo: logo,
            images: images
        )

        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("Reports", isDirectory: true)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

        let fileName = visit.suggestedFileName.isBlank ? "تقرير زيارة" : visit.suggestedFileName
        let url = directory.appendingPathComponent("\(fileName).pdf")
        try? FileManager.default.removeItem(at: url)

        var mediaBox = CGRect(origin: .zero, size: A4.size)
        guard let context = CGContext(url as CFURL, mediaBox: &mediaBox, nil) else {
            throw AppError.pdf("تعذّر تهيئة ملف PDF")
        }

        let total = pageBlocks.count

        for (index, blocks) in pageBlocks.enumerated() {
            let page = ReportPageView(
                blocks: blocks,
                letterhead: letterhead,
                logo: logo,
                images: images,
                pageIndex: index,
                pageCount: total
            )

            let renderer = ImageRenderer(content: page)
            renderer.proposedSize = ProposedViewSize(A4.size)

            var rendered = false
            renderer.render { _, drawInContext in
                context.beginPDFPage(nil)
                drawInContext(context)
                context.endPDFPage()
                rendered = true
            }

            guard rendered else {
                context.closePDF()
                throw AppError.pdf("تعذّر رسم الصفحة رقم \(index + 1)")
            }
        }

        context.closePDF()

        guard FileManager.default.fileExists(atPath: url.path) else {
            throw AppError.pdf("لم يُنشأ الملف")
        }

        return Output(url: url, pageCount: total)
    }
}
