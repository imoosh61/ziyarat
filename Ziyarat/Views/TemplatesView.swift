import SwiftUI

struct TemplatesListView: View {

    @EnvironmentObject private var store: AppStore
    @State private var path: [UUID] = []
    @State private var createdVisitAlert = false

    var body: some View {
        NavigationStack(path: $path) {
            Group {
                if store.templates.isEmpty {
                    ContentUnavailableView {
                        Label("لا توجد نماذج", systemImage: "square.stack.3d.up")
                    } description: {
                        Text("النموذج هو مجموعة أسئلة جاهزة تُستخدم في كل زيارة.")
                    } actions: {
                        Button("نموذج جديد") { createTemplate() }
                            .buttonStyle(.borderedProminent)
                    }
                } else {
                    List {
                        ForEach(store.templates) { template in
                            NavigationLink(value: template.id) {
                                VStack(alignment: .trailing, spacing: 3) {
                                    Text(template.name.isBlank ? "نموذج بدون اسم" : template.name)
                                        .font(.headline)
                                    Text("\(template.questions.count) سؤال")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                .frame(maxWidth: .infinity, alignment: .trailing)
                            }
                            .contextMenu {
                                Button {
                                    store.createVisit(from: template)
                                    createdVisitAlert = true
                                } label: {
                                    Label("إنشاء زيارة من هذا النموذج", systemImage: "plus.square.on.square")
                                }
                            }
                        }
                        .onDelete { store.deleteTemplates(at: $0) }
                    }
                }
            }
            .navigationTitle("نماذج الأسئلة")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        createTemplate()
                    } label: {
                        Image(systemName: "plus")
                    }
                }
                ToolbarItem(placement: .topBarLeading) {
                    if !store.templates.isEmpty { EditButton() }
                }
            }
            .navigationDestination(for: UUID.self) { id in
                TemplateEditorView(templateID: id)
            }
            .alert("تم إنشاء الزيارة", isPresented: $createdVisitAlert) {
                Button("حسناً", role: .cancel) {}
            } message: {
                Text("تجد الزيارة الجديدة في تبويب «الزيارات».")
            }
        }
    }

    private func createTemplate() {
        let template = store.addTemplate(QuestionTemplate(name: "نموذج جديد"))
        path.append(template.id)
    }
}

// MARK: - محرر النموذج

struct TemplateEditorView: View {

    @EnvironmentObject private var store: AppStore
    let templateID: UUID

    @State private var formMode: TemplateQuestionFormMode?
    @State private var createdVisitAlert = false

    private var template: Binding<QuestionTemplate> { store.templateBinding(for: templateID) }

    var body: some View {
        Form {
            Section("بيانات النموذج") {
                TextField("اسم النموذج", text: template.name)
                TextField("وصف مختصر (اختياري)", text: template.notes, axis: .vertical)
                    .lineLimit(1...4)
            }

            Section {
                if template.wrappedValue.questions.isEmpty {
                    Text("لا توجد أسئلة بعد.").foregroundStyle(.secondary)
                }

                ForEach(template.wrappedValue.questions) { question in
                    Button {
                        formMode = .edit(question: question)
                    } label: {
                        VStack(alignment: .trailing, spacing: 3) {
                            Text(question.text.isBlank ? "سؤال بدون نص" : question.text)
                                .multilineTextAlignment(.trailing)
                                .foregroundStyle(.primary)
                            HStack(spacing: 4) {
                                Image(systemName: question.kind.icon)
                                Text(question.kind.title)
                            }
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                }
                .onDelete { offsets in
                    template.wrappedValue.questions.remove(atOffsets: offsets)
                }
                .onMove { source, destination in
                    template.wrappedValue.questions.move(fromOffsets: source, toOffset: destination)
                }

                Button {
                    formMode = .create
                } label: {
                    Label("إضافة سؤال", systemImage: "plus.circle.fill")
                }
            } header: {
                Text("الأسئلة (\(template.wrappedValue.questions.count))")
            }

            Section {
                Button {
                    store.createVisit(from: template.wrappedValue)
                    createdVisitAlert = true
                } label: {
                    Label("إنشاء زيارة من هذا النموذج", systemImage: "plus.square.on.square")
                        .frame(maxWidth: .infinity, alignment: .center)
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .navigationTitle("تعديل النموذج")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { ToolbarItem(placement: .topBarTrailing) { EditButton() } }
        .sheet(item: $formMode) { mode in
            QuestionFormView(mode: mode.asQuestionFormMode) { question in
                var current = template.wrappedValue
                switch mode {
                case .create:
                    current.questions.append(question)
                case .edit(let existing):
                    if let index = current.questions.firstIndex(where: { $0.id == existing.id }) {
                        current.questions[index] = question
                    }
                }
                template.wrappedValue = current
            }
        }
        .alert("تم إنشاء الزيارة", isPresented: $createdVisitAlert) {
            Button("حسناً", role: .cancel) {}
        } message: {
            Text("تجد الزيارة الجديدة في تبويب «الزيارات».")
        }
    }
}

enum TemplateQuestionFormMode: Identifiable {
    case create
    case edit(question: Question)

    var id: String {
        switch self {
        case .create: return "create"
        case .edit(let question): return "edit-\(question.id.uuidString)"
        }
    }

    var asQuestionFormMode: QuestionFormMode {
        switch self {
        case .create: return .create
        case .edit(let question): return .edit(itemID: question.id, question: question)
        }
    }
}
