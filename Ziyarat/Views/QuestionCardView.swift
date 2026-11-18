import SwiftUI

/// بطاقة سؤال واحد داخل محرر الزيارة: نص السؤال + أدوات الجواب + الملاحظة + الصور (آخر خانة).
struct QuestionCardView: View {

    let visitID: UUID
    @Binding var item: VisitItem
    let onEditQuestion: () -> Void
    let onDeleteQuestion: () -> Void

    @State private var showingDeleteConfirm = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            header
            answerControls

            if item.question.allowsNote {
                TextField("ملاحظة (اختياري)", text: $item.answer.note, axis: .vertical)
                    .lineLimit(1...4)
                    .textFieldStyle(.roundedBorder)
            }

            if item.question.allowsPhotos {
                PhotoAttachRow(
                    visitID: visitID,
                    itemID: item.id,
                    photos: $item.answer.photos
                )
            }
        }
        .padding(.vertical, 6)
    }

    // MARK: - الرأس

    private var header: some View {
        HStack(alignment: .top, spacing: 8) {
            VStack(alignment: .leading, spacing: 3) {
                Text(item.question.text.isBlank ? "سؤال بدون نص" : item.question.text)
                    .font(.body.weight(.semibold))
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)

                HStack(spacing: 5) {
                    Image(systemName: item.question.kind.icon)
                    Text(item.question.kind.title)
                    if item.isAnswered {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                    }
                }
                .font(.caption2)
                .foregroundStyle(.secondary)
            }

            Menu {
                Button {
                    onEditQuestion()
                } label: {
                    Label("تعديل السؤال", systemImage: "square.and.pencil")
                }
                Button(role: .destructive) {
                    showingDeleteConfirm = true
                } label: {
                    Label("حذف السؤال", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .font(.title3)
            }
            .buttonStyle(.plain)
            .foregroundStyle(.tint)
            .confirmationDialog(
                "حذف هذا السؤال؟",
                isPresented: $showingDeleteConfirm,
                titleVisibility: .visible
            ) {
                Button("حذف", role: .destructive) { onDeleteQuestion() }
                Button("إلغاء", role: .cancel) {}
            } message: {
                Text("سيُحذف السؤال مع جوابه وملاحظته وصوره.")
            }
        }
    }

    // MARK: - أدوات الجواب حسب نوع السؤال

    @ViewBuilder
    private var answerControls: some View {
        switch item.question.kind {
        case .choice:
            optionsGrid(multiple: false)
        case .multiChoice:
            optionsGrid(multiple: true)
        case .text:
            TextField("اكتب الجواب", text: $item.answer.text, axis: .vertical)
                .lineLimit(2...8)
                .textFieldStyle(.roundedBorder)
        case .rating:
            ratingPicker
        }
    }

    private func optionsGrid(multiple: Bool) -> some View {
        LazyVGrid(
            columns: [GridItem(.adaptive(minimum: 96), spacing: 8)],
            alignment: .leading,
            spacing: 8
        ) {
            ForEach(item.question.options, id: \.self) { option in
                let isSelected = item.answer.selected.contains(option)
                Button {
                    toggle(option: option, multiple: multiple)
                } label: {
                    Text(option)
                        .font(.footnote)
                        .padding(.vertical, 7)
                        .padding(.horizontal, 10)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(isSelected ? Color.accentColor.opacity(0.18) : Color(.secondarySystemBackground))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 1.4)
                        )
                        .foregroundStyle(isSelected ? Color.accentColor : Color.primary)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var ratingPicker: some View {
        HStack(spacing: 8) {
            ForEach(1...max(1, item.question.ratingMax), id: \.self) { value in
                Button {
                    item.answer.rating = (item.answer.rating == value) ? 0 : value
                } label: {
                    Image(systemName: value <= item.answer.rating ? "star.fill" : "star")
                        .font(.title3)
                        .foregroundStyle(value <= item.answer.rating ? .orange : .secondary)
                }
                .buttonStyle(.plain)
            }
            Spacer(minLength: 0)
            if item.answer.rating > 0 {
                Text("\(item.answer.rating) من \(item.question.ratingMax)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func toggle(option: String, multiple: Bool) {
        if multiple {
            if let index = item.answer.selected.firstIndex(of: option) {
                item.answer.selected.remove(at: index)
            } else {
                item.answer.selected.append(option)
            }
        } else {
            item.answer.selected = item.answer.selected.contains(option) ? [] : [option]
        }
    }
}
