import SwiftUI
import PhotosUI
import UIKit

/// خانة الصور — دائماً آخر عنصر في السؤال.
struct PhotoAttachRow: View {

    @EnvironmentObject private var store: AppStore

    let visitID: UUID
    let itemID: UUID
    @Binding var photos: [PhotoRef]

    @State private var pickerItems: [PhotosPickerItem] = []
    @State private var showingCamera = false
    @State private var captionTargetID: UUID?
    @State private var captionText = ""
    @State private var isImporting = false

    var body: some View {
        VStack(alignment: .trailing, spacing: 8) {
            if !photos.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(photos) { ref in
                            thumbnail(for: ref)
                        }
                    }
                    .padding(.vertical, 2)
                }
            }

            HStack(spacing: 12) {
                PhotosPicker(
                    selection: $pickerItems,
                    maxSelectionCount: 8,
                    matching: .images,
                    photoLibrary: .shared()
                ) {
                    Label("صور", systemImage: "photo.on.rectangle.angled")
                        .font(.footnote)
                }

                Button {
                    showingCamera = true
                } label: {
                    Label("كاميرا", systemImage: "camera")
                        .font(.footnote)
                }

                if isImporting {
                    ProgressView().controlSize(.small)
                }

                Spacer(minLength: 0)

                if !photos.isEmpty {
                    Text("\(photos.count) صورة")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .onChange(of: pickerItems) { _, newItems in
            guard !newItems.isEmpty else { return }
            Task { await importPhotos(newItems) }
        }
        .sheet(isPresented: $showingCamera) {
            CameraPicker(
                onCapture: { image in
                    store.attachPhoto(image, to: visitID, itemID: itemID)
                },
                onFinish: { showingCamera = false }
            )
            .ignoresSafeArea()
        }
        .alert("تعليق الصورة", isPresented: Binding(
            get: { captionTargetID != nil },
            set: { if !$0 { captionTargetID = nil } }
        )) {
            TextField("مثال: ملاحظة على لوحة الإرشاد", text: $captionText)
            Button("حفظ") { saveCaption() }
            Button("إلغاء", role: .cancel) { captionTargetID = nil }
        } message: {
            Text("التعليق يظهر أسفل الصورة في ورقة A4. إذا تركته فارغاً يُكتب رقم السؤال تلقائياً.")
        }
    }

    // MARK: - المصغّرات

    private func thumbnail(for ref: PhotoRef) -> some View {
        let image = PhotoCache.shared.image(for: ref)

        return VStack(spacing: 4) {
            ZStack(alignment: .topLeading) {
                Group {
                    if let image {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                    } else {
                        Color(.secondarySystemBackground)
                            .overlay(Image(systemName: "photo").foregroundStyle(.secondary))
                    }
                }
                .frame(width: 84, height: 84)
                .clipShape(RoundedRectangle(cornerRadius: 10))

                Button {
                    store.removePhoto(ref, from: visitID, itemID: itemID)
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.body)
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(.white, .black.opacity(0.65))
                }
                .buttonStyle(.plain)
                .padding(3)
            }

            Text(ref.caption.isBlank ? "إضافة تعليق" : ref.caption)
                .font(.caption2)
                .lineLimit(1)
                .foregroundStyle(ref.caption.isBlank ? .secondary : .primary)
                .frame(width: 84)
        }
        .onTapGesture {
            captionText = ref.caption
            captionTargetID = ref.id
        }
    }

    // MARK: - الاستيراد

    @MainActor
    private func importPhotos(_ items: [PhotosPickerItem]) async {
        isImporting = true
        for item in items {
            do {
                if let data = try await item.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    store.attachPhoto(image, to: visitID, itemID: itemID)
                } else {
                    store.error = .photo("تعذّر قراءة إحدى الصور المختارة")
                }
            } catch {
                store.error = .photo(error.localizedDescription)
            }
        }
        pickerItems = []
        isImporting = false
    }

    private func saveCaption() {
        guard let targetID = captionTargetID,
              let index = photos.firstIndex(where: { $0.id == targetID }) else { return }
        photos[index].caption = captionText.trimmed
        captionTargetID = nil
        captionText = ""
    }
}

// MARK: - الكاميرا

struct CameraPicker: UIViewControllerRepresentable {

    let onCapture: (UIImage) -> Void
    let onFinish: () -> Void

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let controller = UIImagePickerController()
        controller.sourceType = UIImagePickerController.isSourceTypeAvailable(.camera)
            ? .camera
            : .photoLibrary
        controller.allowsEditing = false
        controller.delegate = context.coordinator
        return controller
    }

    func updateUIViewController(_ controller: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onCapture: onCapture, onFinish: onFinish)
    }

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

        private let onCapture: (UIImage) -> Void
        private let onFinish: () -> Void

        init(onCapture: @escaping (UIImage) -> Void, onFinish: @escaping () -> Void) {
            self.onCapture = onCapture
            self.onFinish = onFinish
        }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            if let image = info[.originalImage] as? UIImage {
                onCapture(image)
            }
            onFinish()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            onFinish()
        }
    }
}
