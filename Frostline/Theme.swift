import SwiftUI

/// Frostline's identity: deep glacier-blue/slate with a bright cyan accent —
/// a cold-water, ice-under-moonlight feel. Deliberately distinct from Veil's
/// indigo-black/mist-blue night palette, Static's cloud-themed picker,
/// Unwind's rope-color presets, and Ledger's cream/ink-navy/amber family.
enum FrostTheme {
    static let backdrop = Color(red: 0.043, green: 0.086, blue: 0.137)      // deep glacier-slate near-black
    static let surface = Color(red: 0.075, green: 0.129, blue: 0.192)
    static let surfaceRaised = Color(red: 0.110, green: 0.176, blue: 0.247)
    static let cardBorder = Color(red: 0.549, green: 0.792, blue: 0.898).opacity(0.18)

    static let ink = Color(red: 0.902, green: 0.949, blue: 0.965)          // near-white ice text
    static let inkFaded = Color(red: 0.902, green: 0.949, blue: 0.965).opacity(0.56)

    static let cyan = Color(red: 0.298, green: 0.855, blue: 0.902)         // bright cyan accent
    static let cyanDeep = Color(red: 0.153, green: 0.635, blue: 0.706)
    static let frostBlue = Color(red: 0.463, green: 0.667, blue: 0.925)    // secondary ice-blue

    static let danger = Color(red: 0.910, green: 0.396, blue: 0.408)
    static let warning = Color(red: 0.933, green: 0.635, blue: 0.318)
    static let rule = Color.white.opacity(0.10)

    static let titleFont = Font.system(.title2, design: .rounded).weight(.bold)
    static let displayFont = Font.system(size: 44, weight: .bold, design: .rounded)
    static let headlineFont = Font.system(.headline, design: .rounded).weight(.semibold)
}

struct DismissKeyboardOnTap: ViewModifier {
    func body(content: Content) -> some View {
        content.simultaneousGesture(
            TapGesture().onEnded {
                UIApplication.shared.sendAction(
                    #selector(UIResponder.resignFirstResponder),
                    to: nil, from: nil, for: nil
                )
            }
        )
    }
}

extension View {
    func dismissKeyboardOnTap() -> some View {
        modifier(DismissKeyboardOnTap())
    }
}

enum Haptics {
    static var enabled: Bool = true

    static func light() {
        guard enabled else { return }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    static func medium() {
        guard enabled else { return }
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    static func success() {
        guard enabled else { return }
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    static func warning() {
        guard enabled else { return }
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
    }
}
