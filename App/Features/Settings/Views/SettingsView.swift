import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var container: DIContainer
    @StateObject private var viewModel: AuthViewModel
    @State private var showingSignOutConfirmation = false

    init(container: DIContainer) {
        _viewModel = StateObject(wrappedValue: AuthViewModel(authService: container.authService))
    }

    var body: some View {
        NavigationStack {
            List {
                // Account Section
                Section {
                    NavigationLink(destination: AccountView()) {
                        SettingsRow(icon: "person.circle.fill", title: "Account", color: .blue)
                    }

                    NavigationLink(destination: PreferencesView()) {
                        SettingsRow(icon: "gearshape.fill", title: "Preferences", color: .gray)
                    }
                } header: {
                    Text("Settings")
                }

                // App Section
                Section {
                    NavigationLink(destination: NotificationsView()) {
                        SettingsRow(icon: "bell.fill", title: "Notifications", color: .red)
                    }

                    NavigationLink(destination: PrivacyView()) {
                        SettingsRow(icon: "lock.fill", title: "Privacy & Security", color: .indigo)
                    }
                } header: {
                    Text("App")
                }

                // About Section
                Section {
                    NavigationLink(destination: AboutView()) {
                        SettingsRow(icon: "info.circle.fill", title: "About", color: .purple)
                    }

                    NavigationLink(destination: HelpView()) {
                        SettingsRow(icon: "questionmark.circle.fill", title: "Help & Support", color: .green)
                    }
                } header: {
                    Text("Information")
                }

                // Sign Out Section
                Section {
                    Button(role: .destructive) {
                        showingSignOutConfirmation = true
                    } label: {
                        SettingsRow(icon: "rectangle.portrait.and.arrow.right", title: "Sign Out", color: .red)
                    }
                }
            }
            .navigationTitle("Settings")
            .confirmationDialog("Sign Out", isPresented: $showingSignOutConfirmation) {
                Button("Sign Out", role: .destructive) {
                    Task {
                        await viewModel.signOut()
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Are you sure you want to sign out?")
            }
        }
    }
}

// MARK: - Settings Row

struct SettingsRow: View {
    let icon: String
    let title: String
    let color: Color

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.white)
                .frame(width: 28, height: 28)
                .background(color)
                .cornerRadius(6)

            Text(title)
        }
    }
}

// MARK: - Placeholder Views

struct AccountView: View {
    var body: some View {
        Form {
            Section("Profile") {
                TextField("First Name", text: .constant("John"))
                TextField("Last Name", text: .constant("Doe"))
                TextField("Email", text: .constant("john.doe@example.com"))
                    .disabled(true)
            }

            Section {
                Button("Change Password") {
                    // TODO: Implement
                }
            }
        }
        .navigationTitle("Account")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct PreferencesView: View {
    @AppStorage("enableNotifications") private var enableNotifications = true
    @AppStorage("theme") private var theme = "System"

    var body: some View {
        Form {
            Section("Appearance") {
                Picker("Theme", selection: $theme) {
                    Text("Light").tag("Light")
                    Text("Dark").tag("Dark")
                    Text("System").tag("System")
                }
            }

            Section("General") {
                Toggle("Enable Notifications", isOn: $enableNotifications)
            }
        }
        .navigationTitle("Preferences")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct NotificationsView: View {
    var body: some View {
        Form {
            Section("Notifications") {
                Toggle("Push Notifications", isOn: .constant(true))
                Toggle("Email Notifications", isOn: .constant(true))
                Toggle("In-App Notifications", isOn: .constant(true))
            }
        }
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct PrivacyView: View {
    var body: some View {
        Form {
            Section("Security") {
                Toggle("Biometric Authentication", isOn: .constant(false))
                Toggle("Require Password", isOn: .constant(true))
            }

            Section {
                Button("Clear Cache") {
                    // TODO: Implement
                }
            }
        }
        .navigationTitle("Privacy & Security")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct AboutView: View {
    var body: some View {
        Form {
            Section("App Information") {
                LabeledContent("Version", value: "1.0.0 (1)")
                LabeledContent("Build", value: "MVP")
            }

            Section {
                Link("Terms of Service", destination: URL(string: "https://surreal360.com/terms")!)
                Link("Privacy Policy", destination: URL(string: "https://surreal360.com/privacy")!)
            }
        }
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct HelpView: View {
    var body: some View {
        Form {
            Section("Support") {
                Button("Contact Support") {
                    // TODO: Implement
                }
                Button("Report a Bug") {
                    // TODO: Implement
                }
                Button("Documentation") {
                    // TODO: Implement
                }
            }
        }
        .navigationTitle("Help & Support")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Preview

#Preview {
    SettingsView(container: DIContainer())
        .environmentObject(DIContainer())
}
