import Foundation

/// فك ترميز متسامح: أي مفتاح غير موجود في ملف محفوظ بإصدار أقدم يأخذ قيمته الافتراضية
/// بدل أن تفشل القراءة وتضيع بيانات المستخدم عند تحديث التطبيق.
private extension KeyedDecodingContainer {
    func value<T: Decodable>(_ key: Key, _ fallback: T) -> T {
        guard let decoded = try? decodeIfPresent(T.self, forKey: key) else { return fallback }
        return decoded ?? fallback
    }
}

// MARK: - PhotoRef

extension PhotoRef {
    enum CodingKeys: String, CodingKey {
        case id, caption, addedAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            id: container.value(.id, UUID()),
            caption: container.value(.caption, ""),
            addedAt: container.value(.addedAt, Date())
        )
    }
}

// MARK: - Question

extension Question {
    enum CodingKeys: String, CodingKey {
        case id, text, kind, options, ratingMax, allowsNote, allowsPhotos
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            id: container.value(.id, UUID()),
            text: container.value(.text, ""),
            kind: container.value(.kind, QuestionKind.choice),
            options: container.value(.options, Question.defaultOptions),
            ratingMax: container.value(.ratingMax, 5),
            allowsNote: container.value(.allowsNote, true),
            allowsPhotos: container.value(.allowsPhotos, true)
        )
    }
}

// MARK: - Answer

extension Answer {
    enum CodingKeys: String, CodingKey {
        case selected, text, rating, note, photos
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            selected: container.value(.selected, [String]()),
            text: container.value(.text, ""),
            rating: container.value(.rating, 0),
            note: container.value(.note, ""),
            photos: container.value(.photos, [PhotoRef]())
        )
    }
}

// MARK: - VisitItem

extension VisitItem {
    enum CodingKeys: String, CodingKey {
        case id, question, answer
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            id: container.value(.id, UUID()),
            question: container.value(.question, Question()),
            answer: container.value(.answer, Answer())
        )
    }
}

// MARK: - Visit

extension Visit {
    enum CodingKeys: String, CodingKey {
        case id, title, entity, visitKind, date, showTime, dateStyle
        case visitorName, visitorTitle, introText, closingText
        case signatureNames, items, createdAt, updatedAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            id: container.value(.id, UUID()),
            title: container.value(.title, "تقرير زيارة إشرافية"),
            entity: container.value(.entity, ""),
            visitKind: container.value(.visitKind, ""),
            date: container.value(.date, Date()),
            showTime: container.value(.showTime, false),
            dateStyle: container.value(.dateStyle, DateStyleOption.both),
            visitorName: container.value(.visitorName, ""),
            visitorTitle: container.value(.visitorTitle, ""),
            introText: container.value(.introText, ""),
            closingText: container.value(.closingText, ""),
            signatureNames: container.value(.signatureNames, [String]()),
            items: container.value(.items, [VisitItem]()),
            createdAt: container.value(.createdAt, Date()),
            updatedAt: container.value(.updatedAt, Date())
        )
    }
}

// MARK: - QuestionTemplate

extension QuestionTemplate {
    enum CodingKeys: String, CodingKey {
        case id, name, notes, questions, updatedAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            id: container.value(.id, UUID()),
            name: container.value(.name, ""),
            notes: container.value(.notes, ""),
            questions: container.value(.questions, [Question]()),
            updatedAt: container.value(.updatedAt, Date())
        )
    }
}

// MARK: - LetterheadSettings

extension LetterheadSettings {
    enum CodingKeys: String, CodingKey {
        case layout
        case showKingdomLine, kingdomLine
        case showMinistry, ministry
        case showAdministration, administration
        case showSection, section
        case showExtraLine, extraLine
        case showLeftLines, leftLines
        case showLogo, logoWidth, logoOffsetX, logoOffsetY, logoOpacity
        case logoRemoveWhite, logoWhiteThreshold
        case headerFontName, bodyFontName
        case kingdomFontSize, ministryFontSize, administrationFontSize, sectionFontSize
        case titleFontSize, bodyFontSize, headerBold
        case textColorHex, accentColorHex
        case showDivider, dividerThickness, dividerWidthRatio
        case headerBottomSpacing, repeatHeaderOnAllPages
        case marginTop, marginBottom, marginSide
        case borderStyle, borderInset
        case showPageNumbers, footerText
        case photoPlacement, photoMaxHeight, photoColumns
        case showQuestionNumbers, showEmptyAnswers, showMetaTable, blockSpacing
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let fallback = LetterheadSettings()
        self.init()

        layout = container.value(.layout, fallback.layout)

        showKingdomLine = container.value(.showKingdomLine, fallback.showKingdomLine)
        kingdomLine = container.value(.kingdomLine, fallback.kingdomLine)
        showMinistry = container.value(.showMinistry, fallback.showMinistry)
        ministry = container.value(.ministry, fallback.ministry)
        showAdministration = container.value(.showAdministration, fallback.showAdministration)
        administration = container.value(.administration, fallback.administration)
        showSection = container.value(.showSection, fallback.showSection)
        section = container.value(.section, fallback.section)
        showExtraLine = container.value(.showExtraLine, fallback.showExtraLine)
        extraLine = container.value(.extraLine, fallback.extraLine)

        showLeftLines = container.value(.showLeftLines, fallback.showLeftLines)
        leftLines = container.value(.leftLines, fallback.leftLines)

        showLogo = container.value(.showLogo, fallback.showLogo)
        logoWidth = container.value(.logoWidth, fallback.logoWidth)
        logoOffsetX = container.value(.logoOffsetX, fallback.logoOffsetX)
        logoOffsetY = container.value(.logoOffsetY, fallback.logoOffsetY)
        logoOpacity = container.value(.logoOpacity, fallback.logoOpacity)
        logoRemoveWhite = container.value(.logoRemoveWhite, fallback.logoRemoveWhite)
        logoWhiteThreshold = container.value(.logoWhiteThreshold, fallback.logoWhiteThreshold)

        headerFontName = container.value(.headerFontName, fallback.headerFontName)
        bodyFontName = container.value(.bodyFontName, fallback.bodyFontName)
        kingdomFontSize = container.value(.kingdomFontSize, fallback.kingdomFontSize)
        ministryFontSize = container.value(.ministryFontSize, fallback.ministryFontSize)
        administrationFontSize = container.value(.administrationFontSize, fallback.administrationFontSize)
        sectionFontSize = container.value(.sectionFontSize, fallback.sectionFontSize)
        titleFontSize = container.value(.titleFontSize, fallback.titleFontSize)
        bodyFontSize = container.value(.bodyFontSize, fallback.bodyFontSize)
        headerBold = container.value(.headerBold, fallback.headerBold)

        textColorHex = container.value(.textColorHex, fallback.textColorHex)
        accentColorHex = container.value(.accentColorHex, fallback.accentColorHex)

        showDivider = container.value(.showDivider, fallback.showDivider)
        dividerThickness = container.value(.dividerThickness, fallback.dividerThickness)
        dividerWidthRatio = container.value(.dividerWidthRatio, fallback.dividerWidthRatio)
        headerBottomSpacing = container.value(.headerBottomSpacing, fallback.headerBottomSpacing)
        repeatHeaderOnAllPages = container.value(.repeatHeaderOnAllPages, fallback.repeatHeaderOnAllPages)

        marginTop = container.value(.marginTop, fallback.marginTop)
        marginBottom = container.value(.marginBottom, fallback.marginBottom)
        marginSide = container.value(.marginSide, fallback.marginSide)

        borderStyle = container.value(.borderStyle, fallback.borderStyle)
        borderInset = container.value(.borderInset, fallback.borderInset)

        showPageNumbers = container.value(.showPageNumbers, fallback.showPageNumbers)
        footerText = container.value(.footerText, fallback.footerText)

        photoPlacement = container.value(.photoPlacement, fallback.photoPlacement)
        photoMaxHeight = container.value(.photoMaxHeight, fallback.photoMaxHeight)
        photoColumns = container.value(.photoColumns, fallback.photoColumns)

        showQuestionNumbers = container.value(.showQuestionNumbers, fallback.showQuestionNumbers)
        showEmptyAnswers = container.value(.showEmptyAnswers, fallback.showEmptyAnswers)
        showMetaTable = container.value(.showMetaTable, fallback.showMetaTable)
        blockSpacing = container.value(.blockSpacing, fallback.blockSpacing)
    }
}
