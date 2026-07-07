import SwiftUI

struct RootTabView: View {
    var body: some View {
        StreakView()
    }
}

#Preview {
    RootTabView()
        .environmentObject(FrostlineStore())
        .environmentObject(PurchaseManager())
}
