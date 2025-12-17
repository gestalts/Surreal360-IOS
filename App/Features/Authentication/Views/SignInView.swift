import SwiftUI

struct SignInView: View {
    @EnvironmentObject var container: DIContainer
    @StateObject private var viewModel: AuthViewModel
    @SwiftUI.Environment(\.colorScheme) private var colorScheme: ColorScheme

    @State private var showSignUp = false
    @State private var showResetPassword = false

    init(container: DIContainer) {
        _viewModel = StateObject(wrappedValue: AuthViewModel(authService: container.authService))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Logo and Title
                    VStack(spacing: 16) {
                        Image(systemName: "globe")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 80, height: 80)
                            .foregroundStyle(.blue.gradient)

                        Text("Surreal360")
                            .font(.largeTitle)
                            .fontWeight(.bold)

                        Text("Sign in to continue")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 40)
                    .padding(.bottom, 20)

                    // Sign In Form
                    VStack(spacing: 16) {
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

                        // Password Field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Password")
                                .font(.subheadline)
                                .fontWeight(.medium)

                            SecureField("Enter your password", text: $viewModel.password)
                                .textContentType(.password)
                                .textFieldStyle(RoundedTextFieldStyle())
                        }

                        // Forgot Password
                        HStack {
                            Spacer()
                            Button("Forgot Password?") {
                                showResetPassword = true
                            }
                            .font(.subheadline)
                            .foregroundColor(.blue)
                        }
                    }
                    .padding(.horizontal, 24)

                    // Sign In Button
                    Button {
                        Task {
                            await viewModel.signIn()
                        }
                    } label: {
                        HStack {
                            if viewModel.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Text("Sign In")
                                    .fontWeight(.semibold)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .disabled(viewModel.isLoading || !viewModel.isFormValid)
                    .opacity(viewModel.isFormValid ? 1.0 : 0.6)
                    .padding(.horizontal, 24)
                    .padding(.top, 8)

                    // Sign Up Link
                    HStack {
                        Text("Don't have an account?")
                            .foregroundColor(.secondary)
                        Button("Sign Up") {
                            showSignUp = true
                        }
                        .fontWeight(.semibold)
                        .foregroundColor(.blue)
                    }
                    .font(.subheadline)
                    .padding(.top, 8)

                    Spacer()
                }
            }
            .navigationBarHidden(true)
            .alert("Error", isPresented: $viewModel.showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage)
            }
            .sheet(isPresented: $showSignUp) {
                SignUpView(container: container)
            }
            .sheet(isPresented: $showResetPassword) {
                ResetPasswordView(container: container)
            }
        }
    }
}

// MARK: - Custom Text Field Style

struct RoundedTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(10)
    }
}

// MARK: - Preview

#Preview {
    SignInView(container: DIContainer())
}
