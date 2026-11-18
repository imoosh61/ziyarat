import SwiftUI
import UIKit

// ملاحظة مهمة: الورقة تُرسم باتجاه RTL، لذلك:
//   .leading  = يمين الصفحة
//   .trailing = يسار الصفحة

/// بيانات الترويسة المتغيّرة حسب الزيارة (التاريخ والرقم والمشفوعات).
struct HeaderInfo: Hashable {
    var dateLines: [String] = []
    var number: String = ""
    var attachments: String = ""

    var isEmpty: Bool {
        dateLines.isEmpty && number.isBlank && attachments.isBlank
    }

    static func make(visit: Visit, letterhead: LetterheadSettings) -> HeaderInfo {
        var info = HeaderInfo()

        if letterhead.showHeaderDate {
            switch visit.dateStyle {
            case .hijri:
                info.dateLines = [ArabicDate.hijri(visit.date)]
            case .gregorian:
                info.dateLines = [ArabicDate.gregorian(visit.date)]
            case .both:
                info.dateLines = [ArabicDate.hijri(visit.date), ArabicDate.gregorian(visit.date)]
            }
        }

        if letterhead.showHeaderNumber {
            info.number = letterhead.headerNumberValue
        }
        if letterhead.showHeaderAttachments {
            info.attachments = letterhead.headerAttachmentsValue
        }
        return info
    }

    static let preview = HeaderInfo(dateLines: ["١٤٤٨/٠٦/٠٨ هـ", "٢٠٢٦/١١/١٨ م"])
}

// MARK: - الترويسة الرسمية

struct LetterheadView: View {

    let letterhead: LetterheadSettings
    let logo: UIImage?
    let info: HeaderInfo
    let width: CGFloat

    var body: some View {
        VStack(spacing: 8) {
            layoutContent
                .frame(width: width, alignment: .top)

            if letterhead.showDivider {
                Rectangle()
                    .fill(letterhead.accentColor)
                    .frame(
                        width: max(40, width * letterhead.dividerWidthRatio),
                        height: letterhead.dividerThickness
                    )
            }
        }
        .padding(.bottom, letterhead.headerBottomSpacing)
    }

    // MARK: التوزيع

    @ViewBuilder
    private var layoutContent: some View {
        switch letterhead.layout {
        case .threeColumns:
            HStack(alignment: .top, spacing: 8) {
                textBlock
                    .frame(maxWidth: .infinity, alignment: blockFrameAlignment)
                logoView
                infoColumn
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }

        case .logoTopCenter:
            HStack(alignment: .top, spacing: 8) {
                VStack(alignment: stackAlignment, spacing: 6) {
                    logoView
                    textBlock
                }
                .frame(maxWidth: .infinity, alignment: blockFrameAlignment)

                if !infoIsEmpty {
                    infoColumn
                }
            }

        case .logoRight:
            HStack(alignment: .top, spacing: 12) {
                logoView
                textBlock
                Spacer(minLength: 0)
                if !infoIsEmpty { infoColumn }
            }

        case .logoLeft:
            HStack(alignment: .top, spacing: 12) {
                textBlock
                    .frame(maxWidth: .infinity, alignment: blockFrameAlignment)
                if !infoIsEmpty { infoColumn }
                logoView
            }
        }
    }

    // MARK: العناصر

    @ViewBuilder
    private var logoView: some View {
        if letterhead.showLogo, let logo {
            Image(uiImage: logo)
                .resizable()
                .scaledToFit()
                .frame(width: letterhead.logoWidth, height: letterhead.logoWidth)
                .opacity(letterhead.logoOpacity)
                .offset(x: letterhead.logoOffsetX, y: letterhead.logoOffsetY)
        } else if letterhead.showLogo {
            Color.clear
                .frame(width: letterhead.logoWidth, height: letterhead.logoWidth)
        }
    }

    private var textBlock: some View {
        VStack(alignment: stackAlignment, spacing: 2) {
            if letterhead.showKingdomLine, !letterhead.kingdomLine.isBlank {
                headerText(letterhead.kingdomLine, size: letterhead.kingdomFontSize)
            }
            if letterhead.showMinistry, !letterhead.ministry.isBlank {
                headerText(letterhead.ministry, size: letterhead.ministryFontSize)
            }
            if letterhead.showAdministration, !letterhead.administration.isBlank {
                headerText(letterhead.administration, size: letterhead.administrationFontSize)
            }
            if letterhead.showSection, !letterhead.section.isBlank {
                headerText(letterhead.section, size: letterhead.sectionFontSize)
            }
            if letterhead.showExtraLine, !letterhead.extraLine.isBlank {
                headerText(letterhead.extraLine, size: letterhead.sectionFontSize)
            }
        }
        .multilineTextAlignment(textAlignment)
        .offset(x: letterhead.headerOffsetX, y: letterhead.headerOffsetY)
    }

    /// العمود الأيسر: التاريخ والرقم والمشفوعات وأي أسطر يكتبها المستخدم.
    private var infoColumn: some View {
        VStack(alignment: .trailing, spacing: 3) {
            if letterhead.showHeaderNumber {
                infoText(line(label: letterhead.headerNumberLabel, value: info.number))
            }
            if !info.dateLines.isEmpty {
                infoText(line(label: letterhead.headerDateLabel, value: info.dateLines[0]))
                if info.dateLines.count > 1 {
                    infoText(line(label: "الموافق:", value: info.dateLines[1]))
                }
            }
            if letterhead.showHeaderAttachments {
                infoText(line(label: letterhead.headerAttachmentsLabel, value: info.attachments))
            }
            if letterhead.showLeftLines {
                ForEach(Array(letterhead.leftLines.enumerated()), id: \.offset) { _, text in
                    if !text.isBlank { infoText(text) }
                }
            }
        }
        .multilineTextAlignment(.trailing)
        .fixedSize(horizontal: true, vertical: false)
    }

    private var infoIsEmpty: Bool {
        let hasCustom = letterhead.showLeftLines && letterhead.leftLines.contains { !$0.isBlank }
        return info.isEmpty && !hasCustom && !letterhead.showHeaderNumber && !letterhead.showHeaderAttachments
    }

    private func line(label: String, value: String) -> String {
        value.isBlank ? label : "\(label) \(value)"
    }

    private func headerText(_ value: String, size: Double) -> some View {
        Text(value)
            .font(ArabicFonts.font(letterhead.headerFontName, size: size, bold: letterhead.headerBold))
            .fontWeight(letterhead.headerBold ? .bold : .regular)
            .foregroundStyle(letterhead.textColor)
            .fixedSize(horizontal: false, vertical: true)
    }

    private func infoText(_ value: String) -> some View {
        Text(value)
            .font(ArabicFonts.font(letterhead.headerFontName, size: letterhead.sectionFontSize))
            .foregroundStyle(letterhead.textColor)
            .fixedSize(horizontal: false, vertical: true)
    }

    // MARK: المحاذاة

    private var stackAlignment: HorizontalAlignment {
        switch letterhead.headerAlignment {
        case .right:  return .leading     // RTL: يمين
        case .center: return .center
        case .left:   return .trailing    // RTL: يسار
        }
    }

    private var blockFrameAlignment: Alignment {
        switch letterhead.headerAlignment {
        case .right:  return .leading
        case .center: return .center
        case .left:   return .trailing
        }
    }

    private var textAlignment: TextAlignment {
        switch letterhead.headerAlignment {
        case .right:  return .leading
        case .center: return .center
        case .left:   return .trailing
        }
    }
}

// MARK: - كتلة محتوى واحدة

struct ReportBlockView: View {

    let block: ReportBlock
    let letterhead: LetterheadSettings
    let images: [UUID: UIImage]
    let width: CGFloat

    var body: some View {
        switch block {
        case .title(let text):
            Text(text)
                .font(ArabicFonts.font(letterhead.headerFontName, size: letterhead.titleFontSize, bold: true))
                .fontWeight(.bold)
                .foregroundStyle(letterhead.accentColor)
                .multilineTextAlignment(.center)
                .frame(width: width, alignment: .center)
                .padding(.vertical, 4)

        case .sectionTitle(let text):
            HStack(spacing: 6) {
                Rectangle()
                    .fill(letterhead.accentColor)
                    .frame(width: 3, height: letterhead.bodyFontSize + 4)
                Text(text)
                    .font(ArabicFonts.font(letterhead.headerFontName, size: letterhead.bodyFontSize + 1.5, bold: true))
                    .fontWeight(.bold)
                    .foregroundStyle(letterhead.accentColor)
                Spacer(minLength: 0)
            }
            .frame(width: width, alignment: .leading)
            .padding(.top, 4)

        case .meta(let rows):
            MetaTableView(rows: rows, letterhead: letterhead, width: width)

        case .paragraph(let label, let text):
            VStack(alignment: .leading, spacing: 3) {
                if !label.isBlank {
                    Text(label)
                        .font(bodyFont(bold: true))
                        .fontWeight(.bold)
                        .foregroundStyle(letterhead.textColor)
                }
                Text(text)
                    .font(bodyFont())
                    .foregroundStyle(letterhead.textColor)
                    .multilineTextAlignment(.leading)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(width: width, alignment: .leading)

        case .question(let number, let item):
            QuestionBlockView(
                number: number,
                item: item,
                letterhead: letterhead,
                width: width
            )

        case .photo(_, let ref, let caption):
            PhotoBlockView(
                image: images[ref.id],
                caption: caption,
                letterhead: letterhead,
                width: width
            )

        case .signatures(let names):
            SignaturesView(names: names, letterhead: letterhead, width: width)
        }
    }

    private func bodyFont(bold: Bool = false) -> Font {
        ArabicFonts.font(letterhead.bodyFontName, size: letterhead.bodyFontSize, bold: bold)
    }
}

// MARK: - جدول بيانات الزيارة

struct MetaTableView: View {

    let rows: [MetaRow]
    let letterhead: LetterheadSettings
    let width: CGFloat

    var body: some View {
        VStack(spacing: 0) {
            ForEach(Array(rows.enumerated()), id: \.offset) { index, row in
                HStack(alignment: .top, spacing: 0) {
                    Text(row.label)
                        .font(font(bold: true))
                        .fontWeight(.bold)
                        .foregroundStyle(letterhead.textColor)
                        .frame(width: labelWidth, alignment: .leading)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .background(letterhead.accentColor.opacity(0.08))

                    Rectangle()
                        .fill(letterhead.accentColor.opacity(0.3))
                        .frame(width: 0.6)

                    Text(row.value)
                        .font(font())
                        .foregroundStyle(letterhead.textColor)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .fixedSize(horizontal: false, vertical: true)
                }

                if index < rows.count - 1 {
                    Rectangle()
                        .fill(letterhead.accentColor.opacity(0.3))
                        .frame(height: 0.6)
                }
            }
        }
        .frame(width: width)
        .overlay(
            Rectangle()
                .stroke(letterhead.accentColor.opacity(0.45), lineWidth: 0.8)
        )
    }

    private var labelWidth: CGFloat { min(130, width * 0.28) }

    private func font(bold: Bool = false) -> Font {
        ArabicFonts.font(letterhead.bodyFontName, size: letterhead.bodyFontSize, bold: bold)
    }
}

// MARK: - سؤال وجوابه (السؤال يمين، والجواب تحته)

struct QuestionBlockView: View {

    let number: Int
    let item: VisitItem
    let letterhead: LetterheadSettings
    let width: CGFloat

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(questionLine)
                .font(font(bold: true))
                .fontWeight(.bold)
                .foregroundStyle(letterhead.textColor)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)

            if !answerText.isBlank {
                labeledLine(label: answerLabel, value: answerText, highlight: true)
            }

            if !item.answer.note.isBlank {
                labeledLine(label: "ملاحظة:", value: item.answer.note, highlight: false)
            }
        }
        .padding(8)
        .frame(width: width, alignment: .leading)
        .background(Color.white)
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .stroke(letterhead.accentColor.opacity(0.35), lineWidth: 0.8)
        )
    }

    private var questionLine: String {
        letterhead.showQuestionNumbers ? "\(number). \(item.question.text)" : item.question.text
    }

    private var answerLabel: String {
        switch item.question.kind {
        case .rating: return "التقييم:"
        default:      return "الإجابة:"
        }
    }

    private var answerText: String {
        item.answer.displayText(for: item.question)
    }

    private func labeledLine(label: String, value: String, highlight: Bool) -> some View {
        HStack(alignment: .top, spacing: 4) {
            Text(label)
                .font(font(bold: true))
                .fontWeight(.bold)
                .foregroundStyle(highlight ? letterhead.accentColor : letterhead.textColor.opacity(0.75))
            Text(value)
                .font(font())
                .foregroundStyle(letterhead.textColor)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func font(bold: Bool = false) -> Font {
        ArabicFonts.font(letterhead.bodyFontName, size: letterhead.bodyFontSize, bold: bold)
    }
}

// MARK: - صورة داخل الورقة

struct PhotoBlockView: View {

    let image: UIImage?
    let caption: String
    let letterhead: LetterheadSettings
    let width: CGFloat

    /// الصورة تظهر كاملة دائماً (scaledToFit) داخل مساحة محسوبة مسبقاً.
    static func boxHeight(
        for image: UIImage?,
        letterhead: LetterheadSettings,
        width: CGFloat
    ) -> CGFloat {
        guard let image, image.size.width > 0 else { return 60 }
        let ratio = image.size.height / image.size.width
        return min(width * ratio, CGFloat(letterhead.photoMaxHeight))
    }

    var body: some View {
        VStack(spacing: 4) {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(
                        width: width,
                        height: Self.boxHeight(for: image, letterhead: letterhead, width: width)
                    )
                    .clipped()
                    .overlay(
                        Rectangle()
                            .stroke(letterhead.accentColor.opacity(0.35), lineWidth: 0.8)
                    )
            } else {
                Text("لم يتم العثور على ملف الصورة")
                    .font(captionFont)
                    .foregroundStyle(.red)
                    .frame(width: width, height: 40)
            }

            if !caption.isBlank {
                Text(caption)
                    .font(captionFont)
                    .foregroundStyle(letterhead.textColor.opacity(0.75))
                    .multilineTextAlignment(.center)
                    .frame(width: width, alignment: .center)
            }
        }
        .frame(width: width)
    }

    private var captionFont: Font {
        ArabicFonts.font(letterhead.bodyFontName, size: max(8, letterhead.bodyFontSize - 1.5))
    }
}

// MARK: - التوقيعات

struct SignaturesView: View {

    let names: [String]
    let letterhead: LetterheadSettings
    let width: CGFloat

    var body: some View {
        Group {
            if names.count == 1 {
                signatureCell(names[0])
                    .frame(width: width, alignment: .center)
            } else {
                HStack(alignment: .top, spacing: 12) {
                    ForEach(Array(names.prefix(3).enumerated()), id: \.offset) { _, name in
                        signatureCell(name)
                            .frame(maxWidth: .infinity)
                    }
                }
                .frame(width: width)
            }
        }
        .padding(.top, 18)
    }

    private func signatureCell(_ name: String) -> some View {
        VStack(spacing: 10) {
            Text(name)
                .font(ArabicFonts.font(letterhead.bodyFontName, size: letterhead.bodyFontSize, bold: true))
                .fontWeight(.bold)
                .foregroundStyle(letterhead.textColor)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            Rectangle()
                .fill(letterhead.textColor.opacity(0.35))
                .frame(height: 0.8)
                .padding(.horizontal, 10)

            Text("التوقيع")
                .font(ArabicFonts.font(letterhead.bodyFontName, size: max(8, letterhead.bodyFontSize - 2)))
                .foregroundStyle(letterhead.textColor.opacity(0.6))
        }
    }
}
