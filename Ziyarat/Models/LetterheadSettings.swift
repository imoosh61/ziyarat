import Foundation
import SwiftUI
import UIKit

/// توزيع عناصر الترويسة في أعلى ورقة A4.
enum LetterheadLayout: String, Codable, CaseIterable, Identifiable {
    case threeColumns   // نص يمين • شعار وسط • نص يسار
    case logoTopCenter  // الشعار في الأعلى والنصوص تحته بالوسط
    case logoRight      // الشعار يمين والنصوص بجانبه
    case logoLeft       // الشعار يسار والنصوص بجانبه

    var id: String { rawValue }

    var title: String {
        switch self {
        case .threeColumns:  return "ثلاثة أعمدة (الشعار بالوسط)"
        case .logoTopCenter: return "الشعار أعلى الوسط"
        case .logoRight:     return "الشعار يمين"
        case .logoLeft:      return "الشعار يسار"
        }
    }
}

/// شكل إطار الصفحة.
enum PageBorderStyle: String, Codable, CaseIterable, Identifiable {
    case none
    case single
    case double
    case rounded

    var id: String { rawValue }

    var title: String {
        switch self {
        case .none:    return "بدون إطار"
        case .single:  return "إطار بسيط"
        case .double:  return "إطار مزدوج"
        case .rounded: return "إطار بزوايا دائرية"
        }
    }
}

/// مكان الصور في الورقة.
enum PhotoPlacement: String, Codable, CaseIterable, Identifiable {
    case afterQuestion   // تحت السؤال نفسه، وتنتقل للصفحة التالية إذا لم تكفِ المساحة
    case appendix        // صفحة ملاحق في النهاية

    var id: String { rawValue }

    var title: String {
        switch self {
        case .afterQuestion: return "بعد كل سؤال"
        case .appendix:      return "ملاحق في النهاية"
        }
    }
}

/// كل ما يتعلق بشكل ورقة A4: الترويسة، الشعار، الخطوط، الهوامش، الإطار.
struct LetterheadSettings: Codable, Hashable {

    // MARK: الترويسة
    var layout: LetterheadLayout = .threeColumns

    var showKingdomLine: Bool = true
    var kingdomLine: String = "المملكة العربية السعودية"

    var showMinistry: Bool = true
    var ministry: String = "وزارة التعليم"

    var showAdministration: Bool = true
    var administration: String = "الإدارة العامة للتعليم"

    var showSection: Bool = true
    var section: String = "قسم الإشراف التربوي"

    var showExtraLine: Bool = false
    var extraLine: String = ""

    /// الأسطر على يسار الترويسة (الرقم / التاريخ / المشفوعات).
    var showLeftLines: Bool = false
    var leftLines: [String] = ["الرقم: ", "التاريخ: "]

    // MARK: الشعار
    var showLogo: Bool = true
    var logoWidth: Double = 72        // بالنقاط داخل ورقة A4
    var logoOffsetX: Double = 0
    var logoOffsetY: Double = 0
    var logoOpacity: Double = 1.0
    /// تفريغ الخلفية البيضاء من الشعار تلقائياً عند رفعه.
    var logoRemoveWhite: Bool = true
    var logoWhiteThreshold: Double = 0.90

    // MARK: الخطوط
    var headerFontName: String = ""   // "" = خط النظام
    var bodyFontName: String = ""
    var kingdomFontSize: Double = 11
    var ministryFontSize: Double = 13
    var administrationFontSize: Double = 11
    var sectionFontSize: Double = 10.5
    var titleFontSize: Double = 15
    var bodyFontSize: Double = 11
    var headerBold: Bool = true

    // MARK: الألوان
    var textColorHex: String = "#111111"
    var accentColorHex: String = "#145A32"

    // MARK: الفواصل والهوامش والإطار
    var showDivider: Bool = true
    var dividerThickness: Double = 1.2
    var dividerWidthRatio: Double = 1.0
    var headerBottomSpacing: Double = 14
    var repeatHeaderOnAllPages: Bool = true

    var marginTop: Double = 34
    var marginBottom: Double = 38
    var marginSide: Double = 40

    var borderStyle: PageBorderStyle = .none
    var borderInset: Double = 14

    var showPageNumbers: Bool = true
    var footerText: String = ""

    // MARK: المحتوى
    var photoPlacement: PhotoPlacement = .afterQuestion
    var photoMaxHeight: Double = 250
    var photoColumns: Int = 1
    var showQuestionNumbers: Bool = true
    var showEmptyAnswers: Bool = false      // إظهار الأسئلة غير المجابة
    var showMetaTable: Bool = true          // جدول بيانات الزيارة
    var blockSpacing: Double = 10

    // MARK: ألوان محسوبة
    var textColor: Color { Color(hex: textColorHex) ?? .black }
    var accentColor: Color { Color(hex: accentColorHex) ?? Color(red: 0.08, green: 0.35, blue: 0.2) }

    static let `default` = LetterheadSettings()
}

// MARK: - تحويل الألوان

extension Color {
    init?(hex: String) {
        var value = hex.trimmed
        if value.hasPrefix("#") { value.removeFirst() }
        guard value.count == 6, let intValue = UInt64(value, radix: 16) else { return nil }
        let r = Double((intValue & 0xFF0000) >> 16) / 255
        let g = Double((intValue & 0x00FF00) >> 8) / 255
        let b = Double(intValue & 0x0000FF) / 255
        self = Color(red: r, green: g, blue: b)
    }

    /// تمثيل hex للّون — يُستخدم لتخزين اختيار المستخدم.
    var hexString: String {
        #if canImport(UIKit)
        let ui = UIColor(self)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        guard ui.getRed(&r, green: &g, blue: &b, alpha: &a) else { return "#000000" }
        return String(format: "#%02X%02X%02X", Int(r * 255), Int(g * 255), Int(b * 255))
        #else
        return "#000000"
        #endif
    }
}
