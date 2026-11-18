import Foundation

/// نوع السؤال — يحدده المستخدم عند إضافة السؤال.
enum QuestionKind: String, Codable, CaseIterable, Identifiable, Hashable {
    case choice       // اختيار واحد من قائمة
    case multiChoice  // اختيار متعدد
    case text         // نص حر
    case rating       // تقييم بالنجوم

    var id: String { rawValue }

    var title: String {
        switch self {
        case .choice:      return "اختيار واحد"
        case .multiChoice: return "اختيار متعدد"
        case .text:        return "نص حر"
        case .rating:      return "تقييم بالنجوم"
        }
    }

    var icon: String {
        switch self {
        case .choice:      return "largecircle.fill.circle"
        case .multiChoice: return "checklist"
        case .text:        return "text.alignright"
        case .rating:      return "star.leadinghalf.filled"
        }
    }

    var usesOptions: Bool {
        self == .choice || self == .multiChoice
    }
}

/// سؤال واحد داخل نموذج أو زيارة.
struct Question: Identifiable, Codable, Hashable {
    var id: UUID
    var text: String
    var kind: QuestionKind
    var options: [String]
    var ratingMax: Int
    var allowsNote: Bool
    var allowsPhotos: Bool

    init(
        id: UUID = UUID(),
        text: String = "",
        kind: QuestionKind = .choice,
        options: [String] = Question.defaultOptions,
        ratingMax: Int = 5,
        allowsNote: Bool = true,
        allowsPhotos: Bool = true
    ) {
        self.id = id
        self.text = text
        self.kind = kind
        self.options = options
        self.ratingMax = ratingMax
        self.allowsNote = allowsNote
        self.allowsPhotos = allowsPhotos
    }

    static let defaultOptions = ["مطبق", "مطبق جزئياً", "غير مطبق", "لا ينطبق"]
    static let yesNoOptions = ["نعم", "لا"]

    /// نسخة جديدة بمعرّف جديد — تُستخدم عند نسخ أسئلة نموذج إلى زيارة.
    func duplicated() -> Question {
        var copy = self
        copy.id = UUID()
        return copy
    }
}

/// مرجع صورة مرفقة بجواب — الملف نفسه مخزّن على القرص باسم المعرّف.
struct PhotoRef: Identifiable, Codable, Hashable {
    var id: UUID
    var caption: String
    var addedAt: Date

    init(id: UUID = UUID(), caption: String = "", addedAt: Date = Date()) {
        self.id = id
        self.caption = caption
        self.addedAt = addedAt
    }

    var fileName: String { "\(id.uuidString).jpg" }
}

/// جواب سؤال — الصور دائماً آخر خانة في السؤال.
struct Answer: Codable, Hashable {
    var selected: [String]
    var text: String
    var rating: Int
    var note: String
    var photos: [PhotoRef]

    init(
        selected: [String] = [],
        text: String = "",
        rating: Int = 0,
        note: String = "",
        photos: [PhotoRef] = []
    ) {
        self.selected = selected
        self.text = text
        self.rating = rating
        self.note = note
        self.photos = photos
    }

    func isAnswered(for kind: QuestionKind) -> Bool {
        switch kind {
        case .choice, .multiChoice: return !selected.isEmpty
        case .text:                 return !text.trimmed.isEmpty
        case .rating:               return rating > 0
        }
    }

    /// نص الجواب كما يظهر في ورقة A4.
    func displayText(for question: Question) -> String {
        switch question.kind {
        case .choice, .multiChoice:
            return selected.joined(separator: " ، ")
        case .text:
            return text.trimmed
        case .rating:
            guard rating > 0 else { return "" }
            return "\(rating) من \(question.ratingMax)"
        }
    }
}

/// سؤال + جوابه داخل زيارة. الأسئلة تُنسخ داخل الزيارة حتى لا يتغيّر تقرير قديم عند تعديل النموذج.
struct VisitItem: Identifiable, Codable, Hashable {
    var id: UUID
    var question: Question
    var answer: Answer

    init(id: UUID = UUID(), question: Question, answer: Answer = Answer()) {
        self.id = id
        self.question = question
        self.answer = answer
    }

    var isAnswered: Bool { answer.isAnswered(for: question.kind) }
}

extension String {
    var trimmed: String { trimmingCharacters(in: .whitespacesAndNewlines) }
    var isBlank: Bool { trimmed.isEmpty }
}
