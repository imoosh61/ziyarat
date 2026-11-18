import SwiftUI
import PhotosUI
import UIKit

/// تحكم كامل في شكل ورقة A4: الترويسة، الشعار، الخطوط، الألوان، الهوامش، الإطار، الصور.
struct LetterheadEditorView: View {

    @EnvironmentObject private var store: AppStore
    @State private var logoItem: PhotosPickerItem?
    @State private var showingResetConfirm = false

    private var settings: Binding<LetterheadSettings> { store.letterheadBinding }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    A4LivePreview(letterhead: store.letterhead, logo: store.logo)
                        .listRowInsets(EdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10))
                } header: {
                    Text("معاينة مباشرة")
                } footer: {
                    Text("المعاينة تعرض الصفحة الأولى بنفس مقاس A4 الحقيقي.")
                }

                layoutSection
                headerSideSection
                textsSection
                logoSection
                fontsSection
                colorsSection
                marginsSection
                frameSection
                contentSection

                Section {
                    Button(role: .destructive) {
                        showingResetConfirm = true
                    } label: {
                        Label("إعادة الإعدادات الافتراضية", systemImage: "arrow.counterclockwise")
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                }
            }
            .navigationTitle("ترويسة الورقة")
            .onChange(of: logoItem) { _, item in
                guard let item else { return }
                Task { await loadLogo(item) }
            }
            .confirmationDialog(
                "إعادة الإعدادات الافتراضية؟",
                isPresented: $showingResetConfirm,
                titleVisibility: .visible
            ) {
                Button("إعادة التعيين", role: .destructive) { store.resetLetterhead() }
                Button("إلغاء", role: .cancel) {}
            }
        }
    }

    // MARK: - التوزيع

    private var layoutSection: some View {
        Section("توزيع الترويسة") {
            Picker("التوزيع", selection: settings.layout) {
                ForEach(LetterheadLayout.allCases) { layout in
                    Text(layout.title).tag(layout)
                }
            }
            .pickerStyle(.inline)
            .labelsHidden()

            Toggle("تكرار الترويسة في كل صفحة", isOn: settings.repeatHeaderOnAllPages)

            Picker("مكان نصوص الترويسة", selection: settings.headerAlignment) {
                ForEach(HeaderTextAlignment.allCases) { alignment in
                    Text(alignment.title).tag(alignment)
                }
            }
            .pickerStyle(.segmented)

            slider(title: "تحريك الترويسة أفقياً", value: settings.headerOffsetX, range: -80...80, unit: "نقطة")
            slider(title: "تحريك الترويسة رأسياً", value: settings.headerOffsetY, range: -30...50, unit: "نقطة")
        }
    }

    // MARK: - أعلى يسار الصفحة

    private var headerSideSection: some View {
        Section {
            Toggle("إظهار التاريخ أعلى يسار الصفحة", isOn: settings.showHeaderDate)
            if settings.wrappedValue.showHeaderDate {
                TextField("نص التاريخ", text: settings.headerDateLabel)
            }

            Toggle("إظهار الرقم", isOn: settings.showHeaderNumber)
            if settings.wrappedValue.showHeaderNumber {
                TextField("نص الرقم", text: settings.headerNumberLabel)
                TextField("قيمة الرقم (اختياري)", text: settings.headerNumberValue)
            }

            Toggle("إظهار المشفوعات", isOn: settings.showHeaderAttachments)
            if settings.wrappedValue.showHeaderAttachments {
                TextField("نص المشفوعات", text: settings.headerAttachmentsLabel)
                TextField("قيمة المشفوعات (اختياري)", text: settings.headerAttachmentsValue)
            }
        } header: {
            Text("التاريخ والرقم (أعلى اليسار)")
        } footer: {
            Text("التاريخ يُعبّأ تلقائياً من تاريخ الزيارة (هجري/ميلادي حسب اختيارك في الزيارة)، ولا يتكرر في جدول البيانات.")
        }
    }

    // MARK: - النصوص

    private var textsSection: some View {
        Section {
            toggleField(
                title: "سطر المملكة",
                isOn: settings.showKingdomLine,
                text: settings.kingdomLine,
                placeholder: "المملكة العربية السعودية"
            )
            toggleField(
                title: "الوزارة",
                isOn: settings.showMinistry,
                text: settings.ministry,
                placeholder: "وزارة التعليم"
            )
            toggleField(
                title: "الإدارة",
                isOn: settings.showAdministration,
                text: settings.administration,
                placeholder: "الإدارة العامة للتعليم بـ..."
            )
            toggleField(
                title: "القسم",
                isOn: settings.showSection,
                text: settings.section,
                placeholder: "قسم الإشراف التربوي"
            )
            toggleField(
                title: "سطر إضافي",
                isOn: settings.showExtraLine,
                text: settings.extraLine,
                placeholder: "مثال: مكتب التعليم بـ..."
            )

            Toggle("أسطر جانب اليسار (الرقم / التاريخ)", isOn: settings.showLeftLines)

            if settings.wrappedValue.showLeftLines {
                ForEach(Array(settings.wrappedValue.leftLines.indices), id: \.self) { index in
                    TextField(
                        "سطر \(index + 1)",
                        text: Binding(
                            get: {
                                let lines = settings.wrappedValue.leftLines
                                return index < lines.count ? lines[index] : ""
                            },
                            set: { newValue in
                                var current = settings.wrappedValue
                                while current.leftLines.count <= index { current.leftLines.append("") }
                                current.leftLines[index] = newValue
                                settings.wrappedValue = current
                            }
                        )
                    )
                }

                HStack {
                    Button {
                        var current = settings.wrappedValue
                        current.leftLines.append("")
                        settings.wrappedValue = current
                    } label: {
                        Label("إضافة سطر", systemImage: "plus.circle")
                    }
                    Spacer()
                    if settings.wrappedValue.leftLines.count > 1 {
                        Button(role: .destructive) {
                            var current = settings.wrappedValue
                            current.leftLines.removeLast()
                            settings.wrappedValue = current
                        } label: {
                            Label("حذف الأخير", systemImage: "minus.circle")
                        }
                    }
                }
                .font(.footnote)
            }
        } header: {
            Text("نصوص الترويسة")
        }
    }

    private func toggleField(
        title: String,
        isOn: Binding<Bool>,
        text: Binding<String>,
        placeholder: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Toggle(title, isOn: isOn)
            if isOn.wrappedValue {
                TextField(placeholder, text: text)
                    .textFieldStyle(.roundedBorder)
            }
        }
    }

    // MARK: - الشعار

    private var logoSection: some View {
        Section {
            Toggle("إظهار الشعار", isOn: settings.showLogo)

            HStack(spacing: 14) {
                if let logo = store.logo {
                    Image(uiImage: logo)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 62, height: 62)
                        .background(Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                } else {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(.secondarySystemBackground))
                        .frame(width: 62, height: 62)
                        .overlay(Image(systemName: "photo").foregroundStyle(.secondary))
                }

                VStack(alignment: .leading, spacing: 8) {
                    PhotosPicker(selection: $logoItem, matching: .images) {
                        Label(store.logo == nil ? "اختيار شعار" : "تغيير الشعار", systemImage: "photo.badge.plus")
                    }
                    if store.logo != nil {
                        Button(role: .destructive) {
                            store.setLogo(nil)
                        } label: {
                            Label("حذف الشعار", systemImage: "trash")
                        }
                    }
                }
                .font(.footnote)

                Spacer(minLength: 0)
            }

            Toggle(
                "تفريغ خلفية الشعار البيضاء",
                isOn: Binding(
                    get: { settings.wrappedValue.logoRemoveWhite },
                    set: { newValue in
                        var current = settings.wrappedValue
                        current.logoRemoveWhite = newValue
                        settings.wrappedValue = current
                        store.reprocessLogo()
                    }
                )
            )

            if settings.wrappedValue.logoRemoveWhite {
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text("درجة التفريغ")
                        Spacer()
                        Text(String(format: "%.0f%%", settings.wrappedValue.logoWhiteThreshold * 100))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Slider(
                        value: settings.logoWhiteThreshold,
                        in: 0.60...0.99,
                        onEditingChanged: { editing in
                            if !editing { store.reprocessLogo() }
                        }
                    )
                }
            }

            slider(
                title: "حجم الشعار",
                value: settings.logoWidth,
                range: 30...200,
                unit: "نقطة"
            )
            slider(
                title: "تحريك أفقي",
                value: settings.logoOffsetX,
                range: -80...80,
                unit: "نقطة"
            )
            slider(
                title: "تحريك رأسي",
                value: settings.logoOffsetY,
                range: -40...60,
                unit: "نقطة"
            )
            slider(
                title: "شفافية الشعار",
                value: settings.logoOpacity,
                range: 0.2...1.0,
                unit: "",
                decimals: 2
            )
        } header: {
            Text("الشعار")
        } footer: {
            Text("عند رفع الشعار تُفرَّغ خلفيته البيضاء تلقائياً. إذا اختفت أجزاء فاتحة من الشعار قلّل «درجة التفريغ»، وإذا بقيت خلفية رمادية زِدها. يمكنك إيقاف التفريغ إذا كان الشعار PNG شفافاً أصلاً.")
        }
    }

    // MARK: - الخطوط

    private var fontsSection: some View {
        Section("الخطوط والأحجام") {
            Picker("خط الترويسة", selection: settings.headerFontName) {
                ForEach(ArabicFonts.available) { choice in
                    Text(choice.title).tag(choice.id)
                }
            }
            Picker("خط المحتوى", selection: settings.bodyFontName) {
                ForEach(ArabicFonts.available) { choice in
                    Text(choice.title).tag(choice.id)
                }
            }
            Toggle("ترويسة عريضة", isOn: settings.headerBold)

            slider(title: "حجم سطر المملكة", value: settings.kingdomFontSize, range: 7...20)
            slider(title: "حجم الوزارة", value: settings.ministryFontSize, range: 8...24)
            slider(title: "حجم الإدارة", value: settings.administrationFontSize, range: 7...20)
            slider(title: "حجم القسم", value: settings.sectionFontSize, range: 7...18)
            slider(title: "حجم عنوان التقرير", value: settings.titleFontSize, range: 10...26)
            slider(title: "حجم نص الأسئلة", value: settings.bodyFontSize, range: 8...16)
        }
    }

    // MARK: - الألوان

    private var colorsSection: some View {
        Section("الألوان") {
            ColorPicker(
                "لون النص",
                selection: Binding(
                    get: { settings.wrappedValue.textColor },
                    set: { newValue in
                        var current = settings.wrappedValue
                        current.textColorHex = newValue.hexString
                        settings.wrappedValue = current
                    }
                ),
                supportsOpacity: false
            )

            ColorPicker(
                "اللون المميّز (الفواصل والعناوين)",
                selection: Binding(
                    get: { settings.wrappedValue.accentColor },
                    set: { newValue in
                        var current = settings.wrappedValue
                        current.accentColorHex = newValue.hexString
                        settings.wrappedValue = current
                    }
                ),
                supportsOpacity: false
            )
        }
    }

    // MARK: - الهوامش والفاصل

    private var marginsSection: some View {
        Section("الفاصل والهوامش") {
            Toggle("خط فاصل تحت الترويسة", isOn: settings.showDivider)
            if settings.wrappedValue.showDivider {
                slider(title: "سماكة الفاصل", value: settings.dividerThickness, range: 0.5...4, decimals: 1)
                slider(title: "عرض الفاصل", value: settings.dividerWidthRatio, range: 0.3...1.0, decimals: 2)
            }
            slider(title: "مسافة أسفل الترويسة", value: settings.headerBottomSpacing, range: 0...50)
            slider(title: "الهامش العلوي", value: settings.marginTop, range: 15...80)
            slider(title: "الهامش السفلي", value: settings.marginBottom, range: 15...80)
            slider(title: "الهوامش الجانبية", value: settings.marginSide, range: 15...80)
            slider(title: "المسافة بين الأسئلة", value: settings.blockSpacing, range: 4...26)
        }
    }

    // MARK: - الإطار والترقيم

    private var frameSection: some View {
        Section("إطار الصفحة والتذييل") {
            Picker("الإطار", selection: settings.borderStyle) {
                ForEach(PageBorderStyle.allCases) { style in
                    Text(style.title).tag(style)
                }
            }
            if settings.wrappedValue.borderStyle != .none {
                slider(title: "بُعد الإطار عن الحافة", value: settings.borderInset, range: 6...40)
            }
            Toggle("ترقيم الصفحات", isOn: settings.showPageNumbers)
            TextField("نص التذييل (اختياري)", text: settings.footerText)
        }
    }

    // MARK: - المحتوى والصور

    private var contentSection: some View {
        Section {
            Picker("مكان الصور", selection: settings.photoPlacement) {
                ForEach(PhotoPlacement.allCases) { placement in
                    Text(placement.title).tag(placement)
                }
            }
            slider(title: "أقصى ارتفاع للصورة", value: settings.photoMaxHeight, range: 120...520)
            Toggle("ترقيم الأسئلة", isOn: settings.showQuestionNumbers)
            Toggle("جدول بيانات الزيارة", isOn: settings.showMetaTable)
            Toggle("إظهار الأسئلة غير المجابة", isOn: settings.showEmptyAnswers)
        } header: {
            Text("المحتوى والصور")
        } footer: {
            Text("الصورة تظهر كاملة دائماً؛ إذا لم تكفِ المساحة في الصفحة تنتقل تلقائياً إلى الصفحة التالية.")
        }
    }

    // MARK: - أدوات

    private func slider(
        title: String,
        value: Binding<Double>,
        range: ClosedRange<Double>,
        unit: String = "",
        decimals: Int = 0
    ) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Text(title)
                Spacer()
                Text(formatted(value.wrappedValue, decimals: decimals) + (unit.isEmpty ? "" : " \(unit)"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Slider(value: value, in: range)
        }
    }

    private func formatted(_ value: Double, decimals: Int) -> String {
        String(format: "%.\(decimals)f", value)
    }

    @MainActor
    private func loadLogo(_ item: PhotosPickerItem) async {
        do {
            if let data = try await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                store.setLogo(image)
            } else {
                store.error = .photo("تعذّر قراءة ملف الشعار")
            }
        } catch {
            store.error = .photo(error.localizedDescription)
        }
        logoItem = nil
    }
}

// MARK: - معاينة A4 مصغّرة

struct A4LivePreview: View {

    let letterhead: LetterheadSettings
    let logo: UIImage?

    var body: some View {
        Color.clear
            .aspectRatio(A4.width / A4.height, contentMode: .fit)
            .overlay {
                GeometryReader { geo in
                    let scale = geo.size.width / A4.width
                    let visit = Self.sampleVisit
                    ReportPageView(
                        blocks: ReportContentBuilder(visit: visit, letterhead: letterhead).build(),
                        letterhead: letterhead,
                        logo: logo,
                        images: [:],
                        headerInfo: HeaderInfo.make(visit: visit, letterhead: letterhead),
                        pageIndex: 0,
                        pageCount: 1
                    )
                    .scaleEffect(scale, anchor: .topLeading)
                    .frame(width: geo.size.width, height: geo.size.height, alignment: .topLeading)
                    .clipped()
                }
            }
            .background(Color.white)
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(Color(.separator), lineWidth: 0.6)
            )
            .shadow(color: .black.opacity(0.12), radius: 3, y: 1)
    }

    static var sampleVisit: Visit {
        var sample = Visit(
            title: "تقرير زيارة إشرافية",
            entity: "مكتب التعليم — نموذج معاينة",
            visitKind: "زيارة متابعة",
            visitorName: "اسم القائم بالزيارة",
            visitorTitle: "مشرف",
            introText: "هذه معاينة لشكل الورقة. النصوص هنا للتوضيح فقط وتتغيّر حسب الزيارة الفعلية."
        )
        sample.items = [
            VisitItem(
                question: Question(text: "الالتزام بمواعيد العمل الرسمية", kind: .choice),
                answer: Answer(selected: ["مطبق"], note: "لا توجد ملاحظات.")
            ),
            VisitItem(
                question: Question(text: "أبرز الملاحظات الميدانية", kind: .text),
                answer: Answer(text: "تم الاطلاع على السجلات ووُجدت محدّثة.")
            )
        ]
        return sample
    }
}
