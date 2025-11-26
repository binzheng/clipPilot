import SwiftUI

struct SettingsView: View {
    @ObservedObject private var preferences = Preferences.shared
    @State private var newExcludedApp = ""

    var body: some View {
        TabView {
            GeneralSettingsView(preferences: preferences)
                .tabItem {
                    Label(NSLocalizedString("general", comment: ""), systemImage: "gearshape")
                }

            HistorySettingsView(preferences: preferences)
                .tabItem {
                    Label(NSLocalizedString("history", comment: ""), systemImage: "clock")
                }

            ExclusionsSettingsView(
                preferences: preferences,
                newExcludedApp: $newExcludedApp
            )
            .tabItem {
                Label(NSLocalizedString("exclusions", comment: ""), systemImage: "eye.slash")
            }

            AboutView()
                .tabItem {
                    Label(NSLocalizedString("about", comment: ""), systemImage: "info.circle")
                }
        }
        .frame(width: 500, height: 400)
    }
}

struct GeneralSettingsView: View {
    @ObservedObject var preferences: Preferences

    var body: some View {
        Form {
            Section {
                Toggle(NSLocalizedString("launch_at_login", comment: ""), isOn: $preferences.launchAtLogin)

                HStack {
                    Text(NSLocalizedString("global_shortcut", comment: ""))
                    Spacer()
                    Text("⌥⌘V")
                        .font(.system(.body, design: .monospaced))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.secondary.opacity(0.2))
                        .cornerRadius(4)
                }
            }

            Section {
                VStack(alignment: .leading, spacing: 4) {
                    Toggle(NSLocalizedString("energy_optimization", comment: ""), isOn: $preferences.energyOptimizationEnabled)
                    Text(NSLocalizedString("energy_optimization_description", comment: ""))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Section {
                HStack {
                    Text(NSLocalizedString("permissions", comment: ""))
                        .font(.headline)
                    Spacer()
                }
                .padding(.top, 8)

                Button(NSLocalizedString("open_accessibility_settings", comment: "")) {
                    if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
                        NSWorkspace.shared.open(url)
                    }
                }
            }
        }
        .padding()
    }
}

struct HistorySettingsView: View {
    @ObservedObject var preferences: Preferences

    var body: some View {
        Form {
            Section {
                HStack {
                    Text(NSLocalizedString("max_history_items", comment: ""))
                    Spacer()
                    TextField("", value: $preferences.maxHistoryItems, format: .number)
                        .frame(width: 80)
                        .textFieldStyle(.roundedBorder)
                }

                HStack {
                    Text(NSLocalizedString("max_history_days", comment: ""))
                    Spacer()
                    TextField("", value: $preferences.maxHistoryDays, format: .number)
                        .frame(width: 80)
                        .textFieldStyle(.roundedBorder)
                }
            }

            Section {
                HStack {
                    Text(NSLocalizedString("max_text_length", comment: ""))
                    Spacer()
                    TextField("", value: $preferences.maxTextLength, format: .number)
                        .frame(width: 80)
                        .textFieldStyle(.roundedBorder)
                }

                HStack {
                    Text(NSLocalizedString("max_image_size", comment: ""))
                    Spacer()
                    TextField("", value: $preferences.maxImageSizeKB, format: .number)
                        .frame(width: 80)
                        .textFieldStyle(.roundedBorder)
                    Text("KB")
                }
            }
        }
        .padding()
    }
}

struct ExclusionsSettingsView: View {
    @ObservedObject var preferences: Preferences
    @Binding var newExcludedApp: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(NSLocalizedString("excluded_apps_description", comment: ""))
                .font(.caption)
                .foregroundColor(.secondary)

            HStack {
                TextField(NSLocalizedString("bundle_identifier", comment: ""), text: $newExcludedApp)
                    .textFieldStyle(.roundedBorder)

                Button(NSLocalizedString("add", comment: "")) {
                    if !newExcludedApp.isEmpty && !preferences.excludedApps.contains(newExcludedApp) {
                        preferences.excludedApps.append(newExcludedApp)
                        newExcludedApp = ""
                    }
                }
                .disabled(newExcludedApp.isEmpty)
            }

            List {
                ForEach(preferences.excludedApps, id: \.self) { app in
                    HStack {
                        Text(app)
                        Spacer()
                        Button(action: {
                            preferences.excludedApps.removeAll { $0 == app }
                        }) {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            Text(NSLocalizedString("common_exclusions", comment: ""))
                .font(.caption)
                .foregroundColor(.secondary)

            HStack {
                Button("com.apple.keychainaccess") {
                    addIfNotExists("com.apple.keychainaccess")
                }
                Button("com.lastpass.LastPass") {
                    addIfNotExists("com.lastpass.LastPass")
                }
                Button("com.agilebits.onepassword7") {
                    addIfNotExists("com.agilebits.onepassword7")
                }
            }
            .buttonStyle(.bordered)
            .font(.caption)
        }
        .padding()
    }

    private func addIfNotExists(_ bundleId: String) {
        if !preferences.excludedApps.contains(bundleId) {
            preferences.excludedApps.append(bundleId)
        }
    }
}

struct AboutView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.on.clipboard")
                .font(.system(size: 64))
                .foregroundColor(.accentColor)

            Text("ClipPilot")
                .font(.title)
                .fontWeight(.bold)

            Text("Version 1.0")
                .foregroundColor(.secondary)

            Text(NSLocalizedString("about_description", comment: ""))
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal)

            Spacer()

            Text("© 2025 ClipPilot")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
