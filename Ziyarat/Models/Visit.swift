import Foundation

/// طريقة عرض التاريخ في ورقة التقرير.
enum DateStyleOption: String, Codable, CaseIterable, Identifiable {
    case hijri
    case gregorian
    case both

    var id: String { rawValue }

    var title: String {
        switch self {
        case .hijri:     return "هجري"
        case .gregorian: return "ميلادي"
        case .both:      return "هجري وميلادي"
        }
    }
}

/// زيارة إشرافية واحدة = تقرير واحد.
struct Visit: Identifiable, Codable, Hashable {
    var id: UUID
    var title: String
    var entity: String          // الجهة المزارة
    var visitKind: String       // نوع الزيارة
    var date: Date
    var showTime: Bool
    var dateStyle: DateStyleOption
    var visitorName: String
    var visitorTitle: String
    var introText: String       // مقدمة التقرير
    var closingText: String     // التوصيات / الخاتمة
    var signatureNames: [String]
    var items: [VisitItem]
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        title: String = "تقرير زيارة إشرافية",
        entity: String = "",
        visitKind: String = "",
        date: Date = Date(),
        showTime: Bool = false,
        dateStyle: DateStyleOption = .both,
        visitorName: String = "",
        visitorTitle: String = "",
        introText: String = "",
        closingText: String = "",
        signatureNames: [String] = [],
        items: [VisitItem] = [],
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.entity = entity
        self.visitKind = visitKind
        self.date = date
        self.showTime = showTime
        self.dateStyle = dateStyle
        self.visitorName = visitorName
        self.visitorTitle = visitorTitle
        self.introText = introText
        self.closingText = closingText
        self.signatureNames = signatureNames
        self.items = items
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    var answeredCount: Int { items.filter(\.isAnswered).count }
    var photosCount: Int { items.reduce(0) { $0 + $1.answer.photos.count } }

    var subtitleLine: String {
        var parts: [String] = []
        if !entity.isBlank { parts.append(entity) }
        parts.append(ArabicDate.short(date, style: dateStyle))
        return parts.joined(separator: " • ")
    }

    /// اسم ملف PDF المقترح.
    var suggestedFileName: String {
        let base = entity.isBlank ? title : "\(title) - \(entity)"
        let stamp = ArabicDate.fileStamp(date)
        let cleaned = base
            .replacingOccurrences(of: "/", with: "-")
            .replacingOccurrences(of: ":", with: "-")
            .trimmed
        return "\(cleaned) \(stamp)"
    }
}

/// نموذج أسئلة جاهز يُعاد استخدامه في كل زيارة.
struct QuestionTemplate: Identifiable, Codable, Hashable {
    var id: UUID
    var name: String
    var notes: String
    var questions: [Question]
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        name: String = "",
        notes: String = "",
        questions: [Question] = [],
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.notes = notes
        self.questions = questions
        self.updatedAt = updatedAt
    }
}
