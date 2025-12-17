import SwiftUI

struct SignUpView: View {
    @SwiftUI.Environment(\.dismiss) private var dismiss: DismissAction
    @StateObject private var viewModel: AuthViewModel

    init(container: DIContainer) {
        _viewModel = StateObject(wrappedValue: AuthViewModel(authService: container.authService))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Text("Create Account")
                            .font(.largeTitle)
                            .fontWeight(.bold)

                        Text("Sign up to get started")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 20)

                    // Form Fields
                    VStack(spacing: 16) {
                        // First Name
                        VStack(alignment: .leading, spacing: 8) {
                            Text("First Name")
                                .font(.subheadline)
                                .fontWeight(.medium)

                            TextField("Enter your first name", text: $viewModel.firstName)
                                .textContentType(.givenName)
                                .textFieldStyle(RoundedTextFieldStyle())
                        }

                        // Last Name
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Last Name")
                                .font(.subheadline)
                                .fontWeight(.medium)

                            TextField("Enter your last name", text: $viewModel.lastName)
                                .textContentType(.familyName)
                                .textFieldStyle(RoundedTextFieldStyle())
                        }

                        // Email
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Email")
                                .font(.subheadline)
                                .fontWeight(.medium)

                            TextField("Enter your email", text: $viewModel.email)
                                .textContentType(.emailAddress)
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                                .textFieldStyle(RoundedTextFieldStyle())
                        }

                        // Password
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Password")
                                .font(.subheadline)
                                .fontWeight(.medium)

                            SecureField("Enter your password", text: $viewModel.password)
                                .textContentType(.newPassword)
                                .textFieldStyle(RoundedTextFieldStyle())

                            if !viewModel.password.isEmpty {
                                PasswordStrengthIndicator(password: viewModel.password)
                            }
                        }
                    }
                    .padding(.horizontal, 24)

                    // Sign Up Button
                    Button {
                        Task {
                            await viewModel.signUp()
                        }
                    } label: {
                        HStack {
                            if viewModel.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Text("Create Account")
                                    .fontWeight(.semibold)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .disabled(viewModel.isLoading || !viewModel.isSignUpFormValid)
                    .opacity(viewModel.isSignUpFormValid ? 1.0 : 0.6)
                    .padding(.horizontal, 24)
                    .padding(.top, 8)

                    // Terms and Privacy
                    Text("By signing up, you agree to our Terms of Service and Privacy Policy")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)

                    Spacer()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Error", isPresented: $viewModel.showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage)
            }
        }
    }
}

// MARK: - Password Strength Indicator

struct PasswordStrengthIndicator: View {
    let password: String

    var strength: PasswordStrength {
        if password.count < 8 {
            return .weak
        } else if password.count < 12 {
            return .medium
        } else {
            return .strong
        }
    }

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3, id: \.self) { index in
                RoundedRectangle(cornerRadius: 2)
                    .fill(index < strength.rawValue ? strength.color : Color.gray.opacity(0.3))
                    .frame(height: 4)
            }
        }
        .overlay(alignment: .trailing) {
            Text(strength.title)
                .font(.caption)
                .foregroundColor(strength.color)
                .padding(.leading, 8)
        }
    }
}

enum PasswordStrength: Int {
    case weak = 1
    case medium = 2
    case strong = 3

    var title: String {
        switch self {
        case .weak: return "Weak"
        case .medium: return "Medium"
        case .strong: return "Strong"
        }
    }

    var color: Color {
        switch self {
        case .weak: return .red
        case .medium: return .orange
        case .strong: return .green
        }
    }
}

// MARK: - Preview

#Preview {
    SignUpView(container: DIContainer())
}
