import Foundation
import UIKit

/// مقاس ورقة A4 بالنقاط (72 نقطة للإنش) — نفس المقاس المستخدم في ملف PDF.
enum A4 {
    static let width: CGFloat = 595.276
    static let height: CGFloat = 841.89
    static var size: CGSize { CGSize(width: width, height: height) }
}

struct MetaRow: Hashable {
    let label: String
    let value: String
}

/// وحدة محتوى واحدة لا تُقسّم بين صفحتين.
enum ReportBlock: Identifiable, Hashable {
    case title(String)
    case meta([MetaRow])
    case paragraph(label: String, text: String)
    case sectionTitle(String)
    case question(number: Int, item: VisitItem)
    case photo(questionNumber: Int, ref: PhotoRef, caption: String)
    case signatures([String])

    var id: String {
        switch self {
        case .title(let text):                return "title-\(text.hashValue)"
        case .meta(let rows):                 return "meta-\(rows.hashValue)"
        case .paragraph(let label, let text): return "para-\(label)-\(text.hashValue)"
        case .sectionTitle(let text):         return "section-\(text.hashValue)"
        case .question(let number, let item): return "q-\(number)-\(item.id.uuidString)"
        case .photo(_, let ref, _):           return "photo-\(ref.id.uuidString)"
        case .signatures(let names):          return "sign-\(names.hashValue)"
        }
    }

    /// الصور تحاول البقاء مع سؤالها، وتنتقل للصفحة التالية عند عدم وجود مساحة.
    var isPhoto: Bool {
        if case .photo = self { return true }
        return false
    }
}

/// تحويل الزيارة إلى كتل محتوى مرتّبة — الصور دائماً آخر خانة في السؤال.
struct ReportContentBuilder {

    let visit: Visit
    let letterhead: LetterheadSettings

    func build() -> [ReportBlock] {
        var blocks: [ReportBlock] = []

        if !visit.title.isBlank {
            blocks.append(.title(visit.title))
        }

        if letterhead.showMetaTable {
            let rows = metaRows()
            if !rows.isEmpty { blocks.append(.meta(rows)) }
        }

        if !visit.introText.isBlank {
            blocks.append(.paragraph(label: "", text: visit.introText))
        }

        let visibleItems = visit.items.filter { item in
            letterhead.showEmptyAnswers || item.isAnswered || !item.answer.note.isBlank
                || !item.answer.photos.isEmpty
        }

        if !visibleItems.isEmpty {
            blocks.append(.sectionTitle("أسئلة الزيارة"))
        }

        var appendixPhotos: [(Int, PhotoRef)] = []

        for (index, item) in visibleItems.enumerated() {
            let number = index + 1
            blocks.append(.question(number: number, item: item))

            guard !item.answer.photos.isEmpty else { continue }

            switch letterhead.photoPlacement {
            case .afterQuestion:
                for ref in item.answer.photos {
                    blocks.append(
                        .photo(
                            questionNumber: number,
                            ref: ref,
                            caption: caption(for: ref, questionNumber: number)
                        )
                    )
                }
            case .appendix:
                appendixPhotos.append(contentsOf: item.answer.photos.map { (number, $0) })
            }
        }

        if !appendixPhotos.isEmpty {
            blocks.append(.sectionTitle("الملاحق — صور الزيارة"))
            for (number, ref) in appendixPhotos {
                blocks.append(
                    .photo(
                        questionNumber: number,
                        ref: ref,
                        caption: caption(for: ref, questionNumber: number)
                    )
                )
            }
        }

        if !visit.closingText.isBlank {
            blocks.append(.sectionTitle("التوصيات"))
            blocks.append(.paragraph(label: "", text: visit.closingText))
        }

        let names = visit.signatureNames.filter { !$0.isBlank }
        if !names.isEmpty {
            blocks.append(.signatures(names))
        }

        return blocks
    }

    private func caption(for ref: PhotoRef, questionNumber: Int) -> String {
        if !ref.caption.isBlank { return ref.caption }
        return "صورة متعلقة بالسؤال رقم \(questionNumber)"
    }

    private func metaRows() -> [MetaRow] {
        var rows: [MetaRow] = []
        if !visit.entity.isBlank {
            rows.append(MetaRow(label: "الجهة", value: visit.entity))
        }
        if !visit.visitKind.isBlank {
            rows.append(MetaRow(label: "نوع الزيارة", value: visit.visitKind))
        }
        rows.append(MetaRow(label: "اليوم", value: ArabicDate.dayName(visit.date)))
        rows.append(MetaRow(label: "التاريخ", value: ArabicDate.formatted(visit.date, style: visit.dateStyle)))
        if visit.showTime {
            rows.append(MetaRow(label: "الوقت", value: ArabicDate.time(visit.date)))
        }
        if !visit.visitorName.isBlank {
            let value = visit.visitorTitle.isBlank
                ? visit.visitorName
                : "\(visit.visitorName) — \(visit.visitorTitle)"
            rows.append(MetaRow(label: "القائم بالزيارة", value: value))
        }
        return rows
    }
}
