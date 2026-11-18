import SwiftUI

struct VisitsListView: View {

    @EnvironmentObject private var store: AppStore
    @State private var path: [UUID] = []

    var body: some View {
        NavigationStack(path: $path) {
            Group {
                if store.visits.isEmpty {
                    emptyState
                } else {
                    visitsList
                }
            }
            .navigationTitle("الزيارات الإشرافية")
            .toolbar { toolbarContent }
            .navigationDestination(for: UUID.self) { visitID in
                VisitEditorView(visitID: visitID)
            }
        }
    }

    // MARK: - القائمة

    private var visitsList: some View {
        List {
            ForEach(store.visits) { visit in
                NavigationLink(value: visit.id) {
                    VisitRow(visit: visit)
                }
                .contextMenu {
                    Button {
                        store.duplicate(visit: visit)
                    } label: {
                        Label("نسخة جديدة من الأسئلة", systemImage: "plus.square.on.square")
                    }
                    Button {
                        store.saveAsTemplate(visit: visit, name: visit.title)
                    } label: {
                        Label("حفظ الأسئلة كنموذج", systemImage: "square.stack.3d.up.badge.a")
                    }
                    Button(role: .destructive) {
                        store.delete(visit: visit)
                    } label: {
                        Label("حذف", systemImage: "trash")
                    }
                }
            }
            .onDelete { store.deleteVisits(at: $0) }
        }
        .listStyle(.insetGrouped)
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("لا توجد زيارات بعد", systemImage: "list.bullet.clipboard")
        } description: {
            Text("أضف زيارة جديدة، أو ابدأ من نموذج أسئلة جاهز.")
        } actions: {
            Button("زيارة جديدة") { createEmptyVisit() }
                .buttonStyle(.borderedProminent)
        }
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            if !store.visits.isEmpty { EditButton() }
        }
        ToolbarItem(placement: .topBarTrailing) {
            Menu {
                Button {
                    createEmptyVisit()
                } label: {
                    Label("زيارة فارغة", systemImage: "doc")
                }

                if !store.templates.isEmpty {
                    Section("من نموذج أسئلة") {
                        ForEach(store.templates) { template in
                            Button {
                                let visit = store.createVisit(from: template)
                                path.append(visit.id)
                            } label: {
                                Label(
                                    template.name.isBlank ? "نموذج بدون اسم" : template.name,
                                    systemImage: "square.stack.3d.up"
                                )
                            }
                        }
                    }
                }
            } label: {
                Image(systemName: "plus")
                    .font(.headline)
            }
        }
    }

    private func createEmptyVisit() {
        let visit = store.addVisit()
        path.append(visit.id)
    }
}

// MARK: - صف الزيارة

struct VisitRow: View {

    let visit: Visit

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(visit.title.isBlank ? "تقرير بدون عنوان" : visit.title)
                .font(.headline)
                .multilineTextAlignment(.leading)

            Text(visit.subtitleLine)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            HStack(spacing: 10) {
                badge(
                    text: "\(visit.answeredCount)/\(visit.items.count) سؤال",
                    icon: "checkmark.circle"
                )
                if visit.photosCount > 0 {
                    badge(text: "\(visit.photosCount) صورة", icon: "photo")
                }
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 2)
    }

    private func badge(text: String, icon: String) -> some View {
        HStack(spacing: 3) {
            Image(systemName: icon)
            Text(text)
        }
    }
}
