import SwiftUI

struct VisitEditorView: View {

    @EnvironmentObject private var store: AppStore
    let visitID: UUID

    @State private var questionFormMode: QuestionFormMode?
    @State private var showingPreview = false
    @State private var showingSaveTemplate = false
    @State private var showingClearConfirm = false
    @State private var templateName = ""

    private var visitBinding: Binding<Visit> { store.binding(for: visitID) }

    var body: some View {
        Form {
            detailsSection
            introSection
            questionsSection
            closingSection
            signaturesSection
            exportSection
        }
        .navigationTitle("تفاصيل الزيارة")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        templateName = visitBinding.wrappedValue.title
                        showingSaveTemplate = true
                    } label: {
                        Label("حفظ الأسئلة كنموذج", systemImage: "square.stack.3d.up.badge.a")
                    }
                    Button {
                        showingPreview = true
                    } label: {
                        Label("معاينة وتصدير PDF", systemImage: "doc.richtext")
                    }
                    if !visitBinding.wrappedValue.items.isEmpty {
                        Divider()
                        Button(role: .destructive) {
                            showingClearConfirm = true
                        } label: {
                            Label("حذف كل الأسئلة", systemImage: "trash")
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
            ToolbarItem(placement: .topBarLeading) { EditButton() }
        }
        .sheet(item: $questionFormMode) { mode in
            QuestionFormView(mode: mode) { question in
                apply(question: question, mode: mode)
            }
        }
        .sheet(isPresented: $showingPreview) {
            ReportPreviewView(visitID: visitID)
        }
        .confirmationDialog(
            "حذف كل أسئلة هذه الزيارة؟",
            isPresented: $showingClearConfirm,
            titleVisibility: .visible
        ) {
            Button("حذف الكل", role: .destructive) { clearAllQuestions() }
            Button("إلغاء", role: .cancel) {}
        }
        .alert("حفظ كنموذج", isPresented: $showingSaveTemplate) {
            TextField("اسم النموذج", text: $templateName)
            Button("حفظ") {
                store.saveAsTemplate(visit: visitBinding.wrappedValue, name: templateName)
            }
            Button("إلغاء", role: .cancel) {}
        } message: {
            Text("تُحفظ الأسئلة فقط بدون الأجوبة والصور، لتعيد استخدامها في زيارات قادمة.")
        }
    }

    // MARK: - بيانات الزيارة

    private var detailsSection: some View {
        Section("بيانات الزيارة") {
            TextField("عنوان التقرير", text: visitBinding.title)
            TextField("الجهة المزارة", text: visitBinding.entity)
            TextField("نوع الزيارة (اختياري)", text: visitBinding.visitKind)

            DatePicker(
                "التاريخ",
                selection: visitBinding.date,
                displayedComponents: visitBinding.wrappedValue.showTime ? [.date, .hourAndMinute] : [.date]
            )

            LabeledContent("اليوم", value: ArabicDate.dayName(visitBinding.wrappedValue.date))

            Toggle("إظهار وقت الزيارة", isOn: visitBinding.showTime)

            Picker("شكل التاريخ", selection: visitBinding.dateStyle) {
                ForEach(DateStyleOption.allCases) { option in
                    Text(option.title).tag(option)
                }
            }

            TextField("اسم القائم بالزيارة", text: visitBinding.visitorName)
            TextField("المسمى الوظيفي", text: visitBinding.visitorTitle)
        }
    }

    private var introSection: some View {
        Section("مقدمة التقرير (اختياري)") {
            TextField(
                "مثال: تمت الزيارة الإشرافية بتاريخ ... بهدف ...",
                text: visitBinding.introText,
                axis: .vertical
            )
            .lineLimit(3...8)
        }
    }

    // MARK: - الأسئلة

    private var questionsSection: some View {
        Section {
            if visitBinding.wrappedValue.items.isEmpty {
                Text("لم تُضف أسئلة بعد.")
                    .foregroundStyle(.secondary)
            }

            ForEach(visitBinding.items) { $item in
                QuestionCardView(
                    visitID: visitID,
                    item: $item,
                    onEditQuestion: {
                        questionFormMode = .edit(itemID: item.id, question: item.question)
                    },
                    onDeleteQuestion: {
                        deleteItem(id: item.id)
                    }
                )
            }
            .onDelete { offsets in
                visitBinding.wrappedValue.items.remove(atOffsets: offsets)
            }
            .onMove { source, destination in
                visitBinding.wrappedValue.items.move(fromOffsets: source, toOffset: destination)
            }

            Button {
                questionFormMode = .create
            } label: {
                Label("إضافة سؤال", systemImage: "plus.circle.fill")
            }

            if !store.templates.isEmpty {
                Menu {
                    ForEach(store.templates) { template in
                        Button {
                            addQuestions(from: template)
                        } label: {
                            Text(template.name.isBlank ? "نموذج بدون اسم" : template.name)
                        }
                    }
                } label: {
                    Label("إضافة أسئلة من نموذج", systemImage: "square.stack.3d.up")
                }
            }
        } header: {
            HStack {
                Text("الأسئلة")
                Spacer()
                Text("\(visitBinding.wrappedValue.answeredCount) مجاب من \(visitBinding.wrappedValue.items.count)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        } footer: {
            Text("الصور تُضاف داخل كل سؤال، وتُرتّب تلقائياً في ورقة A4 — تظهر بعد السؤال إن توفرت مساحة، وإلا تنتقل للصفحة التالية كاملة.")
        }
    }

    // MARK: - التوصيات والتوقيعات

    private var closingSection: some View {
        Section("التوصيات / الخاتمة (اختياري)") {
            TextField("التوصيات", text: visitBinding.closingText, axis: .vertical)
                .lineLimit(3...10)
        }
    }

    private var signaturesSection: some View {
        Section {
            ForEach(Array(visitBinding.wrappedValue.signatureNames.enumerated()), id: \.offset) { index, _ in
                HStack {
                    TextField(
                        "الاسم والمسمى",
                        text: Binding(
                            get: {
                                let names = visitBinding.wrappedValue.signatureNames
                                return index < names.count ? names[index] : ""
                            },
                            set: { newValue in
                                var visit = visitBinding.wrappedValue
                                guard index < visit.signatureNames.count else { return }
                                visit.signatureNames[index] = newValue
                                visitBinding.wrappedValue = visit
                            }
                        )
                    )
                    Button(role: .destructive) {
                        var visit = visitBinding.wrappedValue
                        guard index < visit.signatureNames.count else { return }
                        visit.signatureNames.remove(at: index)
                        visitBinding.wrappedValue = visit
                    } label: {
                        Image(systemName: "minus.circle.fill")
                            .foregroundStyle(.red)
                    }
                    .buttonStyle(.plain)
                }
            }

            Button {
                var visit = visitBinding.wrappedValue
                visit.signatureNames.append("")
                visitBinding.wrappedValue = visit
            } label: {
                Label("إضافة توقيع", systemImage: "signature")
            }
        } header: {
            Text("التوقيعات")
        } footer: {
            Text("توقيع واحد يظهر في الوسط، واثنان أو ثلاثة تُوزّع في صف واحد أسفل التقرير.")
        }
    }

    private var exportSection: some View {
        Section {
            Button {
                showingPreview = true
            } label: {
                Label("معاينة ورقة A4 وتصدير PDF", systemImage: "doc.richtext.fill")
                    .frame(maxWidth: .infinity, alignment: .center)
                    .fontWeight(.semibold)
            }
            .buttonStyle(.borderedProminent)
            .listRowInsets(EdgeInsets())
            .padding(.vertical, 4)
        }
    }

    // MARK: - منطق الأسئلة

    private func apply(question: Question, mode: QuestionFormMode) {
        var visit = visitBinding.wrappedValue
        switch mode {
        case .create:
            visit.items.append(VisitItem(question: question))
        case .edit(let itemID, _):
            guard let index = visit.items.firstIndex(where: { $0.id == itemID }) else { return }
            let oldKind = visit.items[index].question.kind
            visit.items[index].question = question
            // تغيير نوع السؤال يُلغي جواباً لم يعد مناسباً، مع الحفاظ على الملاحظة والصور
            if oldKind != question.kind {
                visit.items[index].answer.selected = []
                visit.items[index].answer.rating = 0
                if question.kind != .text { visit.items[index].answer.text = "" }
            } else if question.kind.usesOptions {
                visit.items[index].answer.selected = visit.items[index].answer.selected
                    .filter { question.options.contains($0) }
            }
        }
        visitBinding.wrappedValue = visit
    }

    private func deleteItem(id: UUID) {
        var visit = visitBinding.wrappedValue
        if let item = visit.items.first(where: { $0.id == id }) {
            for photo in item.answer.photos {
                store.removePhoto(photo, from: visitID, itemID: id)
            }
        }
        visit = visitBinding.wrappedValue
        visit.items.removeAll { $0.id == id }
        visitBinding.wrappedValue = visit
    }

    private func clearAllQuestions() {
        var visit = visitBinding.wrappedValue
        let ids = visit.items.map(\.id)
        for id in ids { deleteItem(id: id) }
        visit = visitBinding.wrappedValue
        visit.items.removeAll()
        visitBinding.wrappedValue = visit
    }

    private func addQuestions(from template: QuestionTemplate) {
        var visit = visitBinding.wrappedValue
        visit.items.append(contentsOf: template.questions.map { VisitItem(question: $0.duplicated()) })
        visitBinding.wrappedValue = visit
    }
}
