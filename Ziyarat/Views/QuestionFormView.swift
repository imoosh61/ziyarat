import SwiftUI

enum QuestionFormMode: Identifiable {
    case create
    case edit(itemID: UUID, question: Question)

    var id: String {
        switch self {
        case .create: return "create"
        case .edit(let itemID, _): return "edit-\(itemID.uuidString)"
        }
    }

    var existingQuestion: Question? {
        if case .edit(_, let question) = self { return question }
        return nil
    }

    var title: String {
        switch self {
        case .create: return "سؤال جديد"
        case .edit:   return "تعديل السؤال"
        }
    }
}

/// إضافة أو تعديل سؤال: النص، النوع، الخيارات، والسماح بالملاحظة والصور.
struct QuestionFormView: View {

    let mode: QuestionFormMode
    let onSave: (Question) -> Void

    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss
    @State private var question: Question
    @State private var newOption = ""
    @State private var savedDefaultsNotice = false

    init(
        mode: QuestionFormMode,
        defaultOptions: [String] = Question.defaultOptions,
        onSave: @escaping (Question) -> Void
    ) {
        self.mode = mode
        self.onSave = onSave
        _question = State(
            initialValue: mode.existingQuestion ?? Question(options: defaultOptions)
        )
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("نص السؤال") {
                    TextField("مثال: الالتزام بمواعيد العمل الرسمية", text: $question.text, axis: .vertical)
                        .lineLimit(2...6)
                }

                Section("نوع السؤال") {
                    Picker("النوع", selection: $question.kind) {
                        ForEach(QuestionKind.allCases) { kind in
                            Label(kind.title, systemImage: kind.icon).tag(kind)
                        }
                    }
                    .pickerStyle(.inline)
                    .labelsHidden()
                }

                if question.kind.usesOptions {
                    optionsSection
                }

                if question.kind == .rating {
                    Section("التقييم") {
                        Stepper("أقصى عدد للنجوم: \(question.ratingMax)", value: $question.ratingMax, in: 3...10)
                    }
                }

                Section("خانات إضافية") {
                    Toggle("السماح بكتابة ملاحظة", isOn: $question.allowsNote)
                    Toggle("السماح بإضافة صور", isOn: $question.allowsPhotos)
                }
            }
            .navigationTitle(mode.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("إلغاء") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("حفظ") {
                        var cleaned = question
                        cleaned.text = cleaned.text.trimmed
                        cleaned.options = cleaned.options.map(\.trimmed).filter { !$0.isEmpty }
                        if cleaned.kind.usesOptions, cleaned.options.isEmpty {
                            cleaned.options = Question.defaultOptions
                        }
                        onSave(cleaned)
                        dismiss()
                    }
                    .disabled(question.text.isBlank)
                }
            }
        }
    }

    // MARK: - الخيارات

    private var optionsSection: some View {
        Section {
            ForEach(Array(question.options.enumerated()), id: \.offset) { index, _ in
                HStack {
                    TextField(
                        "الخيار",
                        text: Binding(
                            get: { index < question.options.count ? question.options[index] : "" },
                            set: { newValue in
                                guard index < question.options.count else { return }
                                question.options[index] = newValue
                            }
                        )
                    )
                    Button(role: .destructive) {
                        guard index < question.options.count else { return }
                        question.options.remove(at: index)
                    } label: {
                        Image(systemName: "minus.circle.fill").foregroundStyle(.red)
                    }
                    .buttonStyle(.plain)
                }
            }
            .onMove { source, destination in
                question.options.move(fromOffsets: source, toOffset: destination)
            }

            HStack {
                TextField("إضافة خيار جديد", text: $newOption)
                Button {
                    addOption()
                } label: {
                    Image(systemName: "plus.circle.fill")
                }
                .buttonStyle(.plain)
                .disabled(newOption.isBlank)
            }

            Menu("مجموعات جاهزة") {
                Button("خياراتي الافتراضية") {
                    question.options = store.defaultOptions
                }
                Button("نعم / لا") {
                    question.options = Question.yesNoOptions
                }
                Button("ممتاز / جيد جداً / جيد / يحتاج تحسين") {
                    question.options = ["ممتاز", "جيد جداً", "جيد", "يحتاج تحسين"]
                }
                Button("متوفر / غير متوفر") {
                    question.options = ["متوفر", "غير متوفر"]
                }
            }

            Button {
                let cleaned = question.options.map(\.trimmed).filter { !$0.isEmpty }
                guard !cleaned.isEmpty else { return }
                store.updateDefaultOptions(cleaned)
                savedDefaultsNotice = true
            } label: {
                Label("اعتماد هذه الخيارات لكل سؤال جديد", systemImage: "star")
            }
        } header: {
            Text("الخيارات")
        } footer: {
            Text(savedDefaultsNotice
                 ? "تم الاعتماد — كل سؤال جديد سيبدأ بهذه الخيارات."
                 : "اكتب الكلمات التي تناسبك بدل الكلمات الموجودة، أو احذفها وأضف غيرها.")
        }
    }

    private func addOption() {
        let value = newOption.trimmed
        guard !value.isEmpty else { return }
        question.options.append(value)
        newOption = ""
    }
}
