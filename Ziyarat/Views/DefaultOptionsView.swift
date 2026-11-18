import SwiftUI

/// الخيارات التي يبدأ بها كل سؤال جديد — يكتبها المستخدم بكلماته.
struct DefaultOptionsView: View {

    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss

    @State private var options: [String] = []
    @State private var newOption = ""

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    ForEach(Array(options.indices), id: \.self) { index in
                        HStack {
                            TextField(
                                "الخيار",
                                text: Binding(
                                    get: { index < options.count ? options[index] : "" },
                                    set: { newValue in
                                        guard index < options.count else { return }
                                        options[index] = newValue
                                    }
                                )
                            )
                            Button(role: .destructive) {
                                guard index < options.count else { return }
                                options.remove(at: index)
                            } label: {
                                Image(systemName: "minus.circle.fill").foregroundStyle(.red)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .onMove { source, destination in
                        options.move(fromOffsets: source, toOffset: destination)
                    }

                    HStack {
                        TextField("إضافة خيار", text: $newOption)
                        Button {
                            let value = newOption.trimmed
                            guard !value.isEmpty else { return }
                            options.append(value)
                            newOption = ""
                        } label: {
                            Image(systemName: "plus.circle.fill")
                        }
                        .buttonStyle(.plain)
                        .disabled(newOption.isBlank)
                    }
                } header: {
                    Text("الخيارات الافتراضية")
                } footer: {
                    Text("تُستخدم تلقائياً عند إنشاء أي سؤال من نوع «اختيار». الأسئلة الموجودة لا تتأثر — عدّلها من داخل السؤال نفسه.")
                }

                Section {
                    Menu("مجموعات جاهزة") {
                        Button("نعم / لا") { options = ["نعم", "لا"] }
                        Button("ملتزم / غير ملتزم") { options = ["ملتزم", "غير ملتزم"] }
                        Button("متوفر / غير متوفر") { options = ["متوفر", "غير متوفر"] }
                        Button("ممتاز / جيد جداً / جيد / يحتاج تحسين") {
                            options = ["ممتاز", "جيد جداً", "جيد", "يحتاج تحسين"]
                        }
                    }
                }
            }
            .navigationTitle("خيارات الأسئلة")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("إلغاء") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("حفظ") {
                        let cleaned = options.map(\.trimmed).filter { !$0.isEmpty }
                        store.updateDefaultOptions(cleaned.isEmpty ? Question.defaultOptions : cleaned)
                        dismiss()
                    }
                }
            }
            .onAppear {
                if options.isEmpty { options = store.defaultOptions }
            }
        }
    }
}
