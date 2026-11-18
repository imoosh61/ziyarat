import SwiftUI

struct SettingsView: View {

    @EnvironmentObject private var store: AppStore
    @State private var showingDefaultOptions = false
    @State private var appliedToReport = false

    private var version: String {
        let short = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(short) (\(build))"
    }

    var body: some View {
        NavigationStack {
            Form {
                colorsSection
                appearanceSection
                questionsSection
                contentSection
                aboutSection
            }
            .navigationTitle("الإعدادات")
            .sheet(isPresented: $showingDefaultOptions) {
                DefaultOptionsView().environmentObject(store)
            }
        }
    }

    // MARK: - ألوان التطبيق

    private var colorsSection: some View {
        Section {
            LazyVGrid(
                columns: [GridItem(.adaptive(minimum: 54), spacing: 12)],
                spacing: 12
            ) {
                ForEach(AppTheme.presets, id: \.hex) { preset in
                    Button {
                        var theme = store.theme
                        theme.accentHex = preset.hex
                        store.updateTheme(theme)
                        appliedToReport = false
                    } label: {
                        Circle()
                            .fill(Color(hex: preset.hex) ?? .gray)
                            .frame(height: 46)
                            .overlay(
                                Circle()
                                    .stroke(Color.primary.opacity(0.85), lineWidth: isSelected(preset.hex) ? 3 : 0)
                            )
                            .overlay(
                                Image(systemName: "checkmark")
                                    .font(.footnote.bold())
                                    .foregroundStyle(.white)
                                    .opacity(isSelected(preset.hex) ? 1 : 0)
                            )
                            .accessibilityLabel(preset.name)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 4)

            ColorPicker(
                "لون مخصص",
                selection: Binding(
                    get: { store.theme.accentColor },
                    set: { newValue in
                        var theme = store.theme
                        theme.accentHex = newValue.hexString
                        store.updateTheme(theme)
                        appliedToReport = false
                    }
                ),
                supportsOpacity: false
            )

            Button {
                store.applyThemeColorToReport()
                appliedToReport = true
            } label: {
                Label(
                    appliedToReport ? "تم تطبيق اللون على الورقة" : "استخدام نفس اللون في ورقة التقرير",
                    systemImage: appliedToReport ? "checkmark.circle.fill" : "doc.richtext"
                )
            }
            .disabled(appliedToReport)
        } header: {
            Text("لون التطبيق")
        } footer: {
            Text("لون الورقة المطبوعة يُضبط بشكل مستقل من تبويب «الترويسة»، ويمكنك توحيدهما بالزر أعلاه.")
        }
    }

    private func isSelected(_ hex: String) -> Bool {
        store.theme.accentHex.uppercased() == hex.uppercased()
    }

    // MARK: - المظهر

    private var appearanceSection: some View {
        Section("مظهر التطبيق") {
            Picker("المظهر", selection: store.themeBinding.appearance) {
                ForEach(ThemeAppearance.allCases) { appearance in
                    Text(appearance.title).tag(appearance)
                }
            }
            .pickerStyle(.segmented)
        }
    }

    // MARK: - الأسئلة

    private var questionsSection: some View {
        Section {
            Button {
                showingDefaultOptions = true
            } label: {
                HStack {
                    Label("الخيارات الافتراضية للأسئلة", systemImage: "list.bullet.rectangle")
                    Spacer()
                    Text(store.defaultOptions.prefix(2).joined(separator: " / "))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
        } header: {
            Text("الأسئلة")
        } footer: {
            Text("اكتب الكلمات التي تناسبك (مثل: ملتزم / غير ملتزم) وستظهر في كل سؤال جديد.")
        }
    }

    // MARK: - المحتوى

    private var contentSection: some View {
        Section("المحتوى المحفوظ") {
            LabeledContent("الزيارات", value: "\(store.visits.count)")
            LabeledContent("نماذج الأسئلة", value: "\(store.templates.count)")
            LabeledContent("الصور المرفقة", value: "\(store.visits.reduce(0) { $0 + $1.photosCount })")
        }
    }

    // MARK: - عن التطبيق

    private var aboutSection: some View {
        Section {
            LabeledContent("الإصدار", value: version)
            LabeledContent("المطوّر", value: "imoosh")
            if let url = URL(string: "mailto:imoosh61@outlook.sa") {
                Link(destination: url) {
                    Label("imoosh61@outlook.sa", systemImage: "envelope")
                }
            }
        } header: {
            Text("عن التطبيق")
        } footer: {
            Text("زياراتي — أسئلة الزيارات الإشرافية وتقارير A4. جميع البيانات محفوظة داخل جهازك فقط.")
        }
    }
}
