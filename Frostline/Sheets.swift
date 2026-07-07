import SwiftUI

/// One unified sheet enum for the home screen — stacking multiple `.sheet(item:)`
/// modifiers on the same view is a known SwiftUI bug where only the last one
/// reliably fires, so every sheet routes through this.
enum HomeSheetMode: Identifiable {
    case logToday
    case history
    case settings
    case paywall

    var id: String {
        switch self {
        case .logToday: return "logToday"
        case .history: return "history"
        case .settings: return "settings"
        case .paywall: return "paywall"
        }
    }
}

struct LogTodaySheet: View {
    @EnvironmentObject private var store: FrostlineStore
    @Environment(\.dismiss) private var dismiss

    @State private var tookShower: Bool
    @State private var minutesText: String
    @State private var secondsText: String
    @State private var note: String
    var onSaved: (Milestone?) -> Void

    init(existing: ColdEntry?, onSaved: @escaping (Milestone?) -> Void) {
        self.onSaved = onSaved
        _tookShower = State(initialValue: existing?.tookShower ?? true)
        if let seconds = existing?.durationSeconds {
            _minutesText = State(initialValue: String(seconds / 60))
            _secondsText = State(initialValue: String(seconds % 60))
        } else {
            _minutesText = State(initialValue: "")
            _secondsText = State(initialValue: "")
        }
        _note = State(initialValue: existing?.note ?? "")
    }

    private var totalDurationSeconds: Int? {
        let minutes = Int(minutesText) ?? 0
        let seconds = Int(secondsText) ?? 0
        let total = minutes * 60 + seconds
        return total > 0 ? total : nil
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Today") {
                    Toggle("Took a cold shower", isOn: $tookShower)
                        .accessibilityIdentifier("tookShowerToggle")
                }

                if tookShower {
                    Section("Duration (optional)") {
                        HStack {
                            TextField("Min", text: $minutesText)
                                .keyboardType(.numberPad)
                                .accessibilityIdentifier("durationMinutesField")
                            Text("min")
                                .foregroundStyle(FrostTheme.inkFaded)
                            TextField("Sec", text: $secondsText)
                                .keyboardType(.numberPad)
                                .accessibilityIdentifier("durationSecondsField")
                            Text("sec")
                                .foregroundStyle(FrostTheme.inkFaded)
                        }
                    }
                }

                Section("Note") {
                    TextField("Optional note", text: $note, axis: .vertical)
                        .accessibilityIdentifier("noteField")
                }
            }
            .navigationTitle("Log Today")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let milestone = store.logToday(tookShower: tookShower, durationSeconds: totalDurationSeconds, note: note)
                        if tookShower {
                            Haptics.success()
                        } else {
                            Haptics.warning()
                        }
                        dismiss()
                        onSaved(milestone)
                    }
                    .accessibilityIdentifier("logSaveButton")
                }
            }
        }
        .dismissKeyboardOnTap()
    }
}
