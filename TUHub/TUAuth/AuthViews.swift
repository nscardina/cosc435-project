// AuthViews.swift
import SwiftUI

// MARK: - Auth Routing
enum AuthRoute: Hashable { case login, signup }

// MARK: - Auth Container View
struct AuthView: View {
    @State private var route: AuthRoute = .login

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                AuthHeader()

                Picker("Auth Route", selection: $route) {
                    Text("Log in").tag(AuthRoute.login)
                    Text("Sign up").tag(AuthRoute.signup)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                switch route {
                case .login:
                    LoginView()
                case .signup:
                    SignupView()
                }

                Spacer(minLength: 12)
            }
            .background(TUHubAuthTheme.background.ignoresSafeArea())
            .navigationTitle("Welcome")
        }
    }
}

// MARK: - Header with Towson Logo
struct AuthHeader: View {
    var body: some View {
        VStack(spacing: 8) {
            Image("TUHubLogo")
                .resizable()
                .scaledToFit()
                .frame(width: 140, height: 140)
                .accessibilityHidden(true)

            Text("Sign in or create your account")
                .font(.subheadline)
                .foregroundStyle(TUHubAuthTheme.textSecondary)
        }
        .padding(.top)
    }
}

// MARK: - Login View
struct LoginView: View {
    
    @EnvironmentObject private var loginViewModel: LoginViewModel
    @FocusState private var focusField: Field?

    enum Field { case email, password }

    var body: some View {
        VStack(spacing: 16) {
            GroupBox {
                VStack(spacing: 12) {
                    TUTextField(title: "Email", text: $loginViewModel.email, keyboard: .emailAddress)
                        .focused($focusField, equals: .email)
                        .submitLabel(.next)
                        .onSubmit { focusField = .password }

                    TUSecureField(title: "Password", text: $loginViewModel.password)
                        .focused($focusField, equals: .password)
                        .submitLabel(.go)
                        .onSubmit { submit() }

                    Toggle(isOn: $loginViewModel.rememberMe) {
                        Text("Remember me")
                    }
                }
                .padding(12)
            }
            .padding(.horizontal)

            if let error = loginViewModel.errorMessage {
                TUErrorText(message: error)
            }

            TUPrimaryButton(
                title: loginViewModel.isLoading ? "Signing in..." : "Sign in",
                action: submit
            )
            .disabled(!loginViewModel.canSubmit)
            .padding(.horizontal)

            Button("Forgot password?") { }
                .font(.callout)
                .foregroundStyle(TUHubAuthTheme.textSecondary)
        }
        .padding(.top, 8)
    }

    private func submit() {
        Task { await loginViewModel.login() }
    }
}

// MARK: - Signup View
struct SignupView: View {
    
    @EnvironmentObject private var signupViewModel: SignupViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                GroupBox {
                    VStack(spacing: 12) {
                        TUTextField(title: "Full name", text: $signupViewModel.fullName)

                        TUTextField(title: "Email", text: $signupViewModel.email, keyboard: .emailAddress)

                        // Major dropdown
                        TUDropdownField(
                            title: "Major",
                            placeholder: "Select your major",
                            selection: $signupViewModel.major,
                            options: TowsonMajors.undergraduate
                        )

                        // Student organization dropdown
                        TUDropdownField(
                            title: "Student Organization",
                            placeholder: "Select an organization (optional)",
                            selection: $signupViewModel.org,
                            options: TowsonStudentOrgs.sample
                        )

                        TUSecureField(title: "Password", text: $signupViewModel.password)
                        TUSecureField(title: "Confirm password", text: $signupViewModel.confirmPassword)

                        Toggle(isOn: $signupViewModel.acceptedTerms) {
                            Text("I agree to the Terms of Service")
                        }
                    }
                    .padding(12)
                }

                if let error = signupViewModel.errorMessage {
                    TUErrorText(message: error)
                }

                TUPrimaryButton(
                    title: signupViewModel.isLoading ? "Creating account..." : "Create account"
                ) {
                    Task { await signupViewModel.signup() }
                }
                .disabled(!signupViewModel.canSubmit)
                .padding(.horizontal)
            }
            .padding(.vertical, 8)
        }
    }
}

// MARK: - Preview
#Preview("Auth Container") {
    AuthView()
}
