import Foundation

/// تنسيق التواريخ بالعربية — هجري (أم القرى) وميلادي وأسماء الأيام.
enum ArabicDate {

    static let locale = Locale(identifier: "ar_SA")

    private static var hijriCalendar: Calendar {
        var cal = Calendar(identifier: .islamicUmmAlQura)
        cal.locale = locale
        return cal
    }

    private static func formatter(
        template: String,
        calendar: Calendar
    ) -> DateFormatter {
        let df = DateFormatter()
        df.locale = locale
        df.calendar = calendar
        df.dateFormat = template
        return df
    }

    /// اسم اليوم: الأحد، الاثنين...
    static func dayName(_ date: Date) -> String {
        let df = DateFormatter()
        df.locale = locale
        df.calendar = Calendar(identifier: .gregorian)
        df.dateFormat = "EEEE"
        return df.string(from: date)
    }

    /// 1447/05/12 هـ
    static func hijri(_ date: Date) -> String {
        let df = formatter(template: "yyyy/MM/dd", calendar: hijriCalendar)
        return df.string(from: date) + " هـ"
    }

    /// 2026/11/18 م
    static func gregorian(_ date: Date) -> String {
        var cal = Calendar(identifier: .gregorian)
        cal.locale = locale
        let df = formatter(template: "yyyy/MM/dd", calendar: cal)
        return df.string(from: date) + " م"
    }

    static func time(_ date: Date) -> String {
        let df = DateFormatter()
        df.locale = locale
        df.calendar = Calendar(identifier: .gregorian)
        df.dateFormat = "hh:mm a"
        return df.string(from: date)
    }

    /// التاريخ حسب الاختيار في الزيارة.
    static func formatted(_ date: Date, style: DateStyleOption) -> String {
        switch style {
        case .hijri:     return hijri(date)
        case .gregorian: return gregorian(date)
        case .both:      return "\(hijri(date))  -  \(gregorian(date))"
        }
    }

    static func short(_ date: Date, style: DateStyleOption) -> String {
        switch style {
        case .hijri:     return hijri(date)
        case .gregorian: return gregorian(date)
        case .both:      return gregorian(date)
        }
    }

    /// لاسم ملف PDF.
    static func fileStamp(_ date: Date) -> String {
        var cal = Calendar(identifier: .gregorian)
        cal.locale = Locale(identifier: "en_US_POSIX")
        let df = DateFormatter()
        df.locale = Locale(identifier: "en_US_POSIX")
        df.calendar = cal
        df.dateFormat = "yyyy-MM-dd"
        return df.string(from: date)
    }
}
