import SwiftUI
import UIKit

/// المصدر الوحيد للحقيقة في التطبيق: الزيارات + النماذج + إعدادات الورقة.
/// الحفظ يتم تلقائياً بعد كل تعديل (مع تأجيل بسيط حتى لا نكتب على القرص مع كل حرف).
@MainActor
final class AppStore: ObservableObject {

    @Published var visits: [Visit] = []
    @Published var templates: [QuestionTemplate] = []
    @Published var letterhead: LetterheadSettings = .default
    @Published var logo: UIImage?
    @Published var error: AppError?

    private let storage = FileStorage.shared
    private var saveTask: Task<Void, Never>?

    private enum Files {
        static let visits = "visits.json"
        static let templates = "templates.json"
        static let letterhead = "letterhead.json"
    }

    init() {
        load()
    }

    // MARK: - التحميل

    func load() {
        do {
            visits = try storage.load([Visit].self, from: Files.visits) ?? []
            templates = try storage.load([QuestionTemplate].self, from: Files.templates) ?? []
            letterhead = try storage.load(LetterheadSettings.self, from: Files.letterhead) ?? .default
        } catch let appError as AppError {
            error = appError
        } catch {
            self.error = .load(error.localizedDescription)
        }
        logo = storage.loadLogo()
        visits.sort { $0.updatedAt > $1.updatedAt }
    }

    // MARK: - الحفظ

    private func scheduleSave() {
        saveTask?.cancel()
        saveTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 450_000_000)
            guard let self, !Task.isCancelled else { return }
            self.saveNow()
        }
    }

    func saveNow() {
        do {
            try storage.save(visits, as: Files.visits)
            try storage.save(templates, as: Files.templates)
            try storage.save(letterhead, as: Files.letterhead)
        } catch let appError as AppError {
            error = appError
        } catch {
            self.error = .save(error.localizedDescription)
        }
    }

    // MARK: - الزيارات

    func binding(for visitID: UUID) -> Binding<Visit> {
        Binding(
            get: { [weak self] in
                self?.visits.first(where: { $0.id == visitID }) ?? Visit()
            },
            set: { [weak self] updated in
                self?.update(updated)
            }
        )
    }

    @discardableResult
    func addVisit(_ visit: Visit = Visit()) -> Visit {
        var new = visit
        new.updatedAt = Date()
        visits.insert(new, at: 0)
        scheduleSave()
        return new
    }

    func update(_ visit: Visit) {
        guard let index = visits.firstIndex(where: { $0.id == visit.id }) else { return }
        var updated = visit
        updated.updatedAt = Date()
        visits[index] = updated
        scheduleSave()
    }

    func deleteVisits(at offsets: IndexSet) {
        let removed = offsets.map { visits[$0] }
        visits.remove(atOffsets: offsets)
        for visit in removed { cleanUpPhotos(of: visit) }
        scheduleSave()
    }

    func delete(visit: Visit) {
        visits.removeAll { $0.id == visit.id }
        cleanUpPhotos(of: visit)
        scheduleSave()
    }

    func duplicate(visit: Visit) {
        var copy = visit
        copy.id = UUID()
        copy.title = visit.title + " (نسخة)"
        copy.createdAt = Date()
        copy.updatedAt = Date()
        // الصور لا تُنسخ — المرفقات تبقى للتقرير الأصلي
        copy.items = visit.items.map { item in
            var newItem = item
            newItem.id = UUID()
            newItem.answer.photos = []
            return newItem
        }
        visits.insert(copy, at: 0)
        scheduleSave()
    }

    private func cleanUpPhotos(of visit: Visit) {
        for item in visit.items {
            for photo in item.answer.photos {
                PhotoCache.shared.remove(photo)
                storage.deletePhoto(photo)
            }
        }
    }

    // MARK: - الصور

    func attachPhoto(_ image: UIImage, to visitID: UUID, itemID: UUID, caption: String = "") {
        guard let visitIndex = visits.firstIndex(where: { $0.id == visitID }),
              let itemIndex = visits[visitIndex].items.firstIndex(where: { $0.id == itemID })
        else { return }

        let ref = PhotoRef(caption: caption)
        do {
            try storage.savePhoto(image, for: ref)
            PhotoCache.shared.store(image.downscaled(maxDimension: 2000), for: ref)
            visits[visitIndex].items[itemIndex].answer.photos.append(ref)
            visits[visitIndex].updatedAt = Date()
            scheduleSave()
        } catch let appError as AppError {
            error = appError
        } catch {
            self.error = .photo(error.localizedDescription)
        }
    }

    func removePhoto(_ ref: PhotoRef, from visitID: UUID, itemID: UUID) {
        guard let visitIndex = visits.firstIndex(where: { $0.id == visitID }),
              let itemIndex = visits[visitIndex].items.firstIndex(where: { $0.id == itemID })
        else { return }

        visits[visitIndex].items[itemIndex].answer.photos.removeAll { $0.id == ref.id }
        PhotoCache.shared.remove(ref)
        storage.deletePhoto(ref)
        scheduleSave()
    }

    /// كل صور الزيارة جاهزة للاستخدام في PDF.
    func images(for visit: Visit) -> [UUID: UIImage] {
        var result: [UUID: UIImage] = [:]
        for item in visit.items {
            for photo in item.answer.photos {
                if let image = PhotoCache.shared.image(for: photo) {
                    result[photo.id] = image
                }
            }
        }
        return result
    }

    // MARK: - النماذج

    func addTemplate(_ template: QuestionTemplate = QuestionTemplate(name: "نموذج جديد")) -> QuestionTemplate {
        templates.insert(template, at: 0)
        scheduleSave()
        return template
    }

    func templateBinding(for id: UUID) -> Binding<QuestionTemplate> {
        Binding(
            get: { [weak self] in
                self?.templates.first(where: { $0.id == id }) ?? QuestionTemplate()
            },
            set: { [weak self] updated in
                self?.updateTemplate(updated)
            }
        )
    }

    func updateTemplate(_ template: QuestionTemplate) {
        guard let index = templates.firstIndex(where: { $0.id == template.id }) else { return }
        var updated = template
        updated.updatedAt = Date()
        templates[index] = updated
        scheduleSave()
    }

    func deleteTemplates(at offsets: IndexSet) {
        templates.remove(atOffsets: offsets)
        scheduleSave()
    }

    /// إنشاء زيارة من نموذج أسئلة.
    @discardableResult
    func createVisit(from template: QuestionTemplate) -> Visit {
        let items = template.questions.map { VisitItem(question: $0.duplicated()) }
        let visit = Visit(
            title: template.name.isBlank ? "تقرير زيارة إشرافية" : template.name,
            items: items
        )
        return addVisit(visit)
    }

    /// حفظ أسئلة زيارة كنموذج لإعادة الاستخدام.
    func saveAsTemplate(visit: Visit, name: String) {
        let template = QuestionTemplate(
            name: name.isBlank ? visit.title : name,
            questions: visit.items.map { $0.question.duplicated() }
        )
        templates.insert(template, at: 0)
        scheduleSave()
    }

    // MARK: - الترويسة

    func updateLetterhead(_ new: LetterheadSettings) {
        letterhead = new
        scheduleSave()
    }

    var letterheadBinding: Binding<LetterheadSettings> {
        Binding(
            get: { [weak self] in self?.letterhead ?? .default },
            set: { [weak self] new in self?.updateLetterhead(new) }
        )
    }

    func setLogo(_ image: UIImage?) {
        if let image {
            let resized = image.downscaled(maxDimension: 800)
            do {
                try storage.saveOriginalLogo(resized)
                let processed = processedLogo(from: resized)
                try storage.saveLogo(processed)
                logo = processed
            } catch let appError as AppError {
                error = appError
            } catch {
                self.error = .photo(error.localizedDescription)
            }
        } else {
            storage.deleteLogo()
            storage.deleteOriginalLogo()
            logo = nil
        }
        scheduleSave()
    }

    /// تطبيق تفريغ الخلفية البيضاء حسب الإعدادات الحالية.
    private func processedLogo(from image: UIImage) -> UIImage {
        guard letterhead.logoRemoveWhite else { return image }
        return image.removingLightBackground(threshold: letterhead.logoWhiteThreshold) ?? image
    }

    /// إعادة معالجة الشعار من نسخته الأصلية بعد تغيير إعدادات التفريغ.
    func reprocessLogo() {
        guard let original = storage.loadOriginalLogo() ?? storage.loadLogo() else { return }
        let processed = processedLogo(from: original)
        do {
            try storage.saveLogo(processed)
            logo = processed
        } catch let appError as AppError {
            error = appError
        } catch {
            self.error = .photo(error.localizedDescription)
        }
    }

    func resetLetterhead() {
        letterhead = .default
        scheduleSave()
    }
}
