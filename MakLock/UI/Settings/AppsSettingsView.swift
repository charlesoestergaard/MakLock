import SwiftUI

/// Apps settings tab: manage the list of protected applications.
struct AppsSettingsView: View {
    @StateObject private var manager = ProtectedAppsManager.shared
    @State private var appPickerController = AppPickerWindowController()

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Protected Applications")
                .font(MakLockTypography.title)

            if manager.apps.isEmpty {
                emptyState
            } else {
                appsList
            }

            Spacer()

            HStack {
                Spacer()
                PrimaryButton("Add App", icon: "plus") {
                    appPickerController.show(from: NSApp.keyWindow)
                }
            }
        }
        .padding()
    }

    /// Minutes offered in the stay-unlocked menu (0 = ask every time).
    private static let stayUnlockedOptions = [0, 5, 15, 30, 60, 120, 240, 480]

    private static func stayUnlockedTitle(_ minutes: Int) -> String {
        switch minutes {
        case 0: return String(localized: "Ask every time")
        case ..<60: return String(localized: "Stay unlocked for \(minutes) minutes")
        case 60: return String(localized: "Stay unlocked for 1 hour")
        default: return String(localized: "Stay unlocked for \(minutes / 60) hours")
        }
    }

    private static func stayUnlockedShortTitle(_ minutes: Int) -> String {
        minutes < 60 ? String(localized: "\(minutes) min") : String(localized: "\(minutes / 60) h")
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "lock.open")
                .font(.system(size: 40))
                .foregroundColor(MakLockColors.textSecondary)
            Text("No protected apps yet")
                .font(MakLockTypography.headline)
                .foregroundColor(.secondary)
            Text("Add apps to protect them with Touch ID or password.")
                .font(MakLockTypography.caption)
                .foregroundColor(.secondary)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private var appsList: some View {
        List {
            ForEach(manager.apps) { app in
                HStack(spacing: 12) {
                    AppIconView(bundleIdentifier: app.bundleIdentifier, size: 32)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(app.name)
                            .font(MakLockTypography.headline)
                        Text(app.bundleIdentifier)
                            .font(MakLockTypography.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()

                    // Stay-unlocked period
                    Menu {
                        ForEach(Self.stayUnlockedOptions, id: \.self) { minutes in
                            Button {
                                manager.setStayUnlockedMinutes(minutes == 0 ? nil : minutes, for: app)
                            } label: {
                                if (app.stayUnlockedMinutes ?? 0) == minutes {
                                    Label(Self.stayUnlockedTitle(minutes), systemImage: "checkmark")
                                } else {
                                    Text(Self.stayUnlockedTitle(minutes))
                                }
                            }
                        }
                    } label: {
                        HStack(spacing: 3) {
                            Image(systemName: "hourglass")
                            if let minutes = app.stayUnlockedMinutes, minutes > 0 {
                                Text(Self.stayUnlockedShortTitle(minutes))
                            }
                        }
                        .font(.system(size: 12))
                        .foregroundColor(app.stayUnlockedMinutes == nil ? MakLockColors.textSecondary : MakLockColors.gold)
                    }
                    .menuStyle(.borderlessButton)
                    .menuIndicator(.hidden)
                    .fixedSize()
                    .help("How long the app stays unlocked before asking again")

                    // Auto-close toggle
                    Button(action: { manager.toggleAutoClose(app) }) {
                        Image(systemName: app.autoClose ? "timer" : "timer")
                            .font(.system(size: 12))
                            .foregroundColor(app.autoClose ? MakLockColors.gold : MakLockColors.textSecondary)
                    }
                    .buttonStyle(.plain)
                    .help(LocalizedStringKey(app.autoClose ? "Auto-close enabled" : "Enable auto-close when inactive"))

                    Toggle("", isOn: Binding(
                        get: { app.isEnabled },
                        set: { _ in manager.toggleApp(app) }
                    ))
                    .toggleStyle(.goldSwitch)
                    .labelsHidden()

                    Button(action: { manager.removeApp(app) }) {
                        Image(systemName: "trash")
                            .font(.system(size: 12))
                            .foregroundColor(MakLockColors.error)
                    }
                    .buttonStyle(.plain)
                }
                .id(app.id)
                .padding(.vertical, 4)
            }
            .onDelete { indexSet in
                let appsToRemove = indexSet.map { manager.apps[$0] }
                appsToRemove.forEach { manager.removeApp($0) }
            }
        }
    }
}
