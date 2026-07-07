import SwiftUI

@main
struct FrostlineApp: App {
    @StateObject private var store = FrostlineStore()
    @StateObject private var purchases = PurchaseManager()

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environmentObject(store)
                .environmentObject(purchases)
                .preferredColorScheme(.dark)
                .onAppear {
                    Haptics.enabled = store.hapticsEnabled
                }
        }
    }
}
