import SwiftUI
import UIKit

/// الخطوط العربية المتاحة على الجهاز — تُفلتر وقت التشغيل فلا يظهر خط غير مثبّت.
enum ArabicFonts {

    struct Choice: Identifiable, Hashable {
        let id: String      // اسم الخط لـ UIFont ("" = خط النظام)
        let title: String   // الاسم المعروض
    }

    private static let candidates: [Choice] = [
        Choice(id: "", title: "خط النظام (SF Arabic)"),
        Choice(id: "GeezaPro", title: "جيزة برو"),
        Choice(id: "GeezaPro-Bold", title: "جيزة برو عريض"),
        Choice(id: "Damascus", title: "دمشق"),
        Choice(id: "DamascusBold", title: "دمشق عريض"),
        Choice(id: "AlNile", title: "النيل"),
        Choice(id: "AlNile-Bold", title: "النيل عريض"),
        Choice(id: "Baghdad", title: "بغداد"),
        Choice(id: "KufiStandardGK-Regular", title: "كوفي"),
        Choice(id: "DiwanKufi", title: "ديواني كوفي"),
        Choice(id: "Mishafi", title: "مصحفي"),
        Choice(id: "Muna", title: "منى"),
        Choice(id: "Nadeem", title: "نديم"),
        Choice(id: "Farah", title: "فرح"),
        Choice(id: "ArialMT", title: "Arial"),
        Choice(id: "TimesNewRomanPSMT", title: "Times New Roman")
    ]

    /// الخطوط المثبّتة فعلياً على هذا الجهاز.
    static let available: [Choice] = candidates.filter { choice in
        choice.id.isEmpty || UIFont(name: choice.id, size: 12) != nil
    }

    static func title(for id: String) -> String {
        available.first(where: { $0.id == id })?.title ?? "خط النظام (SF Arabic)"
    }

    /// خط SwiftUI مع رجوع آمن لخط النظام إذا لم يكن الخط مثبتاً.
    static func font(_ name: String, size: CGFloat, bold: Bool = false) -> Font {
        if !name.isEmpty, UIFont(name: name, size: size) != nil {
            return .custom(name, size: size)
        }
        return .system(size: size, weight: bold ? .bold : .regular)
    }

    /// UIFont — يُستخدم في قياس ارتفاع الكتل.
    static func uiFont(_ name: String, size: CGFloat, bold: Bool = false) -> UIFont {
        if !name.isEmpty, let font = UIFont(name: name, size: size) {
            return font
        }
        return .systemFont(ofSize: size, weight: bold ? .bold : .regular)
    }
}
