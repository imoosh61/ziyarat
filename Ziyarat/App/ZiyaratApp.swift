import SwiftUI

@main
struct ZiyaratApp: App {

    @StateObject private var store = AppStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
                .environment(\.layoutDirection, .rightToLeft)
                .environment(\.locale, Locale(identifier: "ar"))
                .tint(store.letterhead.accentColor)
        }
    }
}

struct RootView: View {

    @EnvironmentObject private var store: AppStore
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        TabView {
            VisitsListView()
                .tabItem { Label("الزيارات", systemImage: "list.bullet.clipboard") }

            TemplatesListView()
                .tabItem { Label("النماذج", systemImage: "square.stack.3d.up") }

            LetterheadEditorView()
                .tabItem { Label("الترويسة", systemImage: "doc.richtext") }

            AboutView()
                .tabItem { Label("عن التطبيق", systemImage: "info.circle") }
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase != .active { store.saveNow() }
        }
        .alert(
            "تنبيه",
            isPresented: Binding(
                get: { store.error != nil },
                set: { if !$0 { store.error = nil } }
            ),
            presenting: store.error
        ) { _ in
            Button("حسناً", role: .cancel) { store.error = nil }
        } message: { error in
            Text(error.errorDescription ?? "حدث خطأ غير متوقع")
        }
    }
}
