import SwiftUI

struct AboutView: View {

    @EnvironmentObject private var store: AppStore

    private var version: String {
        let short = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(short) (\(build))"
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    VStack(spacing: 8) {
                        Image(systemName: "list.bullet.clipboard.fill")
                            .font(.system(size: 42))
                            .foregroundStyle(.tint)
                        Text("زياراتي")
                            .font(.title2.bold())
                        Text("أسئلة الزيارات الإشرافية وتقارير A4")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }

                Section("المحتوى المحفوظ") {
                    LabeledContent("الزيارات", value: "\(store.visits.count)")
                    LabeledContent("نماذج الأسئلة", value: "\(store.templates.count)")
                    LabeledContent("الصور المرفقة", value: "\(store.visits.reduce(0) { $0 + $1.photosCount })")
                }

                Section("كيف يعمل التطبيق") {
                    bullet("أضف أسئلتك بأي نوع: اختيار، اختيار متعدد، نص حر، أو تقييم بالنجوم.")
                    bullet("أجب على الأسئلة وأضف الملاحظات والصور — الصورة آخر خانة في كل سؤال.")
                    bullet("اضبط الترويسة والشعار والخطوط من تبويب «الترويسة».")
                    bullet("رتّب الأسئلة والصور تلقائياً في ورقة A4 ثم صدّرها PDF.")
                }

                Section("المطوّر") {
                    LabeledContent("الإصدار", value: version)
                    LabeledContent("المطوّر", value: "imoosh")
                    if let url = URL(string: "mailto:imoosh61@outlook.sa") {
                        Link(destination: url) {
                            Label("imoosh61@outlook.sa", systemImage: "envelope")
                        }
                    }
                }
            }
            .navigationTitle("عن التطبيق")
        }
    }

    private func bullet(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.tint)
                .font(.caption)
                .padding(.top, 3)
            Text(text)
                .font(.footnote)
                .multilineTextAlignment(.leading)
            Spacer(minLength: 0)
        }
    }
}
