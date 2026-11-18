import SwiftUI
import PDFKit

/// معاينة ورقة A4 النهائية + التصدير والمشاركة.
struct ReportPreviewView: View {

    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss

    let visitID: UUID

    @State private var phase: Phase = .building

    enum Phase {
        case building
        case ready(url: URL, pageCount: Int)
        case failed(message: String)
    }

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("معاينة التقرير")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("إغلاق") { dismiss() }
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        if case .ready(let url, _) = phase {
                            ShareLink(item: url) {
                                Image(systemName: "square.and.arrow.up")
                            }
                        }
                    }
                }
                .task { await rebuild() }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch phase {
        case .building:
            VStack(spacing: 14) {
                ProgressView()
                Text("جاري ترتيب الأسئلة والصور في ورقة A4…")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

        case .ready(let url, let pageCount):
            VStack(spacing: 0) {
                PDFKitView(url: url)
                    .background(Color(.systemGray5))

                HStack {
                    Label("\(pageCount) صفحة", systemImage: "doc.on.doc")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    Spacer()
                    ShareLink(item: url) {
                        Label("تصدير PDF", systemImage: "square.and.arrow.up")
                            .fontWeight(.semibold)
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding(.horizontal)
                .padding(.vertical, 10)
                .background(.bar)
            }

        case .failed(let message):
            ContentUnavailableView {
                Label("تعذّر إنشاء التقرير", systemImage: "exclamationmark.triangle")
            } description: {
                Text(message)
            } actions: {
                Button("إعادة المحاولة") {
                    Task { await rebuild() }
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }

    @MainActor
    private func rebuild() async {
        phase = .building

        guard let visit = store.visits.first(where: { $0.id == visitID }) else {
            phase = .failed(message: "لم يتم العثور على الزيارة")
            return
        }

        // مهلة قصيرة حتى تظهر حالة التحميل قبل العمل الثقيل
        try? await Task.sleep(nanoseconds: 80_000_000)

        do {
            let images = store.images(for: visit)
            let output = try PDFBuilder.build(
                visit: visit,
                letterhead: store.letterhead,
                logo: store.logo,
                images: images
            )
            phase = .ready(url: output.url, pageCount: output.pageCount)
        } catch let error as AppError {
            phase = .failed(message: error.errorDescription ?? "خطأ غير معروف")
        } catch {
            phase = .failed(message: error.localizedDescription)
        }
    }
}

/// عارض PDF من PDFKit.
struct PDFKitView: UIViewRepresentable {

    let url: URL

    func makeUIView(context: Context) -> PDFView {
        let view = PDFView()
        view.autoScales = true
        view.displayMode = .singlePageContinuous
        view.displayDirection = .vertical
        view.backgroundColor = .systemGray5
        view.document = PDFDocument(url: url)
        return view
    }

    func updateUIView(_ view: PDFView, context: Context) {
        if view.document?.documentURL != url {
            view.document = PDFDocument(url: url)
        }
    }
}
