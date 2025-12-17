import SwiftUI

struct ResetPasswordView: View {
    @SwiftUI.Environment(\.dismiss) private var dismiss: DismissAction
    @StateObject private var viewModel: AuthViewModel
    @State private var showSuccess = false

    init(container: DIContainer) {
        _viewModel = StateObject(wrappedValue: AuthViewModel(authService: container.authService))
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                // Header
                VStack(spacing: 16) {
                    Image(systemName: "key.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 60, height: 60)
                        .foregroundStyle(.blue.gradient)

                    Text("Reset Password")
                        .font(.title)
                        .fontWeight(.bold)

                    Text("Enter your email address and we'll send you a link to reset your password")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
                .padding(.top, 40)

                // Email Field
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
                .padding(.horizontal, 24)

                // Reset Button
                Button {
                    Task {
                        await viewModel.resetPassword()
                        showSuccess = true
                    }
                } label: {
                    HStack {
                        if viewModel.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text("Send Reset Link")
                                .fontWeight(.semibold)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .disabled(viewModel.isLoading || viewModel.email.isEmpty || !viewModel.email.contains("@"))
                .opacity(viewModel.email.isEmpty || !viewModel.email.contains("@") ? 0.6 : 1.0)
                .padding(.horizontal, 24)

                Spacer()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Success", isPresented: $showSuccess) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("Password reset email sent. Please check your inbox.")
            }
            .alert("Error", isPresented: $viewModel.showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    ResetPasswordView(container: DIContainer())
}
