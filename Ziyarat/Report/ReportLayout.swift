import SwiftUI
import UIKit

/// حساب الهوامش ومساحة المحتوى داخل ورقة A4 — يستخدمه محرك التقسيم وعرض الصفحة معاً.
struct ReportGeometry {

    let letterhead: LetterheadSettings

    private var borderPadding: CGFloat {
        letterhead.borderStyle == .none ? 0 : CGFloat(letterhead.borderInset) + 8
    }

    var sideInset: CGFloat { CGFloat(letterhead.marginSide) + borderPadding }
    var topInset: CGFloat { CGFloat(letterhead.marginTop) + borderPadding }
    var bottomInset: CGFloat { CGFloat(letterhead.marginBottom) + borderPadding }

    var footerHeight: CGFloat {
        (letterhead.showPageNumbers || !letterhead.footerText.isBlank) ? 18 : 0
    }

    var contentWidth: CGFloat { A4.width - sideInset * 2 }

    var contentHeight: CGFloat { A4.height - topInset - bottomInset - footerHeight }

    var blockSpacing: CGFloat { CGFloat(letterhead.blockSpacing) }
}

/// يقسّم كتل المحتوى على صفحات A4 بحيث لا تُقطع أي كتلة (ولا صورة) بين صفحتين.
@MainActor
struct ReportLayoutEngine {

    let letterhead: LetterheadSettings
    let logo: UIImage?
    let images: [UUID: UIImage]
    let headerInfo: HeaderInfo

    private var geometry: ReportGeometry { ReportGeometry(letterhead: letterhead) }

    /// ارتفاع الترويسة كما ستُرسم فعلياً.
    func headerHeight() -> CGFloat {
        let view = LetterheadView(
            letterhead: letterhead,
            logo: logo,
            info: headerInfo,
            width: geometry.contentWidth
        )
        return Self.measure(view, width: geometry.contentWidth)
    }

    func paginate(_ blocks: [ReportBlock]) -> [[ReportBlock]] {
        guard !blocks.isEmpty else { return [[]] }

        let geo = geometry
        let header = headerHeight()
        let firstPageAvailable = max(80, geo.contentHeight - header)
        let otherPagesAvailable = letterhead.repeatHeaderOnAllPages
            ? max(80, geo.contentHeight - header)
            : geo.contentHeight

        var pages: [[ReportBlock]] = []
        var current: [ReportBlock] = []
        var used: CGFloat = 0
        var available = firstPageAvailable

        for block in blocks {
            let height = self.height(of: block, width: geo.contentWidth)
            let needed = current.isEmpty ? height : height + geo.blockSpacing

            if used + needed > available, !current.isEmpty {
                pages.append(current)
                current = []
                used = 0
                available = otherPagesAvailable
            }

            current.append(block)
            used += current.count == 1 ? height : height + geo.blockSpacing
        }

        if !current.isEmpty { pages.append(current) }
        return pages.isEmpty ? [[]] : pages
    }

    /// ارتفاع كتلة واحدة — الصور تُحسب رياضياً، والباقي يُقاس فعلياً.
    func height(of block: ReportBlock, width: CGFloat) -> CGFloat {
        if case .photo(_, let ref, let caption) = block {
            let image = images[ref.id]
            let box = PhotoBlockView.boxHeight(for: image, letterhead: letterhead, width: width)
            let captionHeight: CGFloat = caption.isBlank ? 0 : max(10, CGFloat(letterhead.bodyFontSize) + 4)
            return box + captionHeight + 6
        }

        let view = ReportBlockView(
            block: block,
            letterhead: letterhead,
            images: images,
            width: width
        )
        return Self.measure(view, width: width)
    }

    /// قياس ارتفاع أي View بعرض محدد باستخدام UIHostingController.
    static func measure<V: View>(_ view: V, width: CGFloat) -> CGFloat {
        let wrapped = view
            .frame(width: width)
            .fixedSize(horizontal: false, vertical: true)
            .environment(\.layoutDirection, .rightToLeft)
            .environment(\.locale, ArabicDate.locale)

        let controller = UIHostingController(rootView: wrapped)
        controller.view.backgroundColor = .clear
        controller.view.frame = CGRect(x: 0, y: 0, width: width, height: A4.height)
        controller.view.setNeedsLayout()
        controller.view.layoutIfNeeded()

        let size = controller.sizeThatFits(
            in: CGSize(width: width, height: .greatestFiniteMagnitude)
        )
        return ceil(max(size.height, 8))
    }
}

// MARK: - صفحة A4 واحدة

struct ReportPageView: View {

    let blocks: [ReportBlock]
    let letterhead: LetterheadSettings
    let logo: UIImage?
    let images: [UUID: UIImage]
    let headerInfo: HeaderInfo
    let pageIndex: Int
    let pageCount: Int

    private var geometry: ReportGeometry { ReportGeometry(letterhead: letterhead) }

    private var showsHeader: Bool {
        pageIndex == 0 || letterhead.repeatHeaderOnAllPages
    }

    var body: some View {
        ZStack {
            Color.white

            borderShape

            VStack(spacing: 0) {
                if showsHeader {
                    LetterheadView(
                        letterhead: letterhead,
                        logo: logo,
                        info: headerInfo,
                        width: geometry.contentWidth
                    )
                }

                VStack(alignment: .leading, spacing: geometry.blockSpacing) {
                    ForEach(Array(blocks.enumerated()), id: \.offset) { _, block in
                        ReportBlockView(
                            block: block,
                            letterhead: letterhead,
                            images: images,
                            width: geometry.contentWidth
                        )
                    }
                }
                .frame(width: geometry.contentWidth, alignment: .top)

                Spacer(minLength: 0)

                footer
            }
            .padding(.top, geometry.topInset)
            .padding(.bottom, geometry.bottomInset)
            .padding(.horizontal, geometry.sideInset)
        }
        .frame(width: A4.width, height: A4.height)
        .environment(\.layoutDirection, .rightToLeft)
        .environment(\.locale, ArabicDate.locale)
    }

    @ViewBuilder
    private var footer: some View {
        if letterhead.showPageNumbers || !letterhead.footerText.isBlank {
            HStack {
                if !letterhead.footerText.isBlank {
                    Text(letterhead.footerText)
                        .font(footerFont)
                        .foregroundStyle(letterhead.textColor.opacity(0.6))
                }
                Spacer(minLength: 0)
                if letterhead.showPageNumbers {
                    Text("صفحة \(pageIndex + 1) من \(pageCount)")
                        .font(footerFont)
                        .foregroundStyle(letterhead.textColor.opacity(0.6))
                }
            }
            .frame(width: geometry.contentWidth, height: geometry.footerHeight, alignment: .bottom)
        }
    }

    private var footerFont: Font {
        ArabicFonts.font(letterhead.bodyFontName, size: max(7.5, letterhead.bodyFontSize - 2.5))
    }

    @ViewBuilder
    private var borderShape: some View {
        let inset = CGFloat(letterhead.borderInset)
        switch letterhead.borderStyle {
        case .none:
            EmptyView()
        case .single:
            Rectangle()
                .stroke(letterhead.accentColor.opacity(0.7), lineWidth: 1.2)
                .padding(inset)
        case .double:
            ZStack {
                Rectangle()
                    .stroke(letterhead.accentColor.opacity(0.8), lineWidth: 1.6)
                    .padding(inset)
                Rectangle()
                    .stroke(letterhead.accentColor.opacity(0.5), lineWidth: 0.8)
                    .padding(inset + 4)
            }
        case .rounded:
            RoundedRectangle(cornerRadius: 10)
                .stroke(letterhead.accentColor.opacity(0.7), lineWidth: 1.2)
                .padding(inset)
        }
    }
}
