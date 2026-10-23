import SwiftUI

public struct AuthView: View {
    @ObservedObject public var appState: AppState
    @StateObject private var viewModel: AuthViewModel
    @FocusState private var focusedField: Field?

    private enum Field {
        case email, password
    }

    public init(appState: AppState) {
        self.appState = appState
        _viewModel = StateObject(wrappedValue: AuthViewModel(appState: appState))
    }

    public var body: some View {
        NavigationStack {
            ZStack {
                Theme.pageBackground
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Header / Branding
                        VStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(Theme.primary.opacity(0.12))
                                    .frame(width: 84, height: 84)

                                Image(systemName: "books.vertical.fill")
                                    .font(.system(size: 38))
                                    .foregroundColor(Theme.primary)
                            }
                            .padding(.top, 24)

                            Text("Smart Library")
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundColor(.primary)

                            Text("Intelligent desk booking & presence tracking")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.horizontal)

                        // Mode Switcher (Sign In vs Sign Up)
                        Picker("Mode", selection: $viewModel.isSignUp) {
                            Text("Sign In").tag(false)
                            Text("Create Account").tag(true)
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal, 24)

                        // Form Card
                        VStack(spacing: 16) {
                            // Email Field
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Student / University Email")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(.secondary)

                                HStack {
                                    Image(systemName: "envelope.fill")
                                        .foregroundColor(.secondary)
                                        .frame(width: 20)

                                    TextField("student@university.edu", text: $viewModel.email)
                                        .textInputAutocapitalization(.never)
                                        .keyboardType(.emailAddress)
                                        .autocorrectionDisabled()
                                        .focused($focusedField, equals: .email)
                                }
                                .padding(14)
                                .background(Theme.pageBackground)
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            }

                            // Password Field
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Password")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(.secondary)

                                HStack {
                                    Image(systemName: "lock.fill")
                                        .foregroundColor(.secondary)
                                        .frame(width: 20)

                                    SecureField("At least 6 characters", text: $viewModel.password)
                                        .focused($focusedField, equals: .password)
                                }
                                .padding(14)
                                .background(Theme.pageBackground)
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            }

                            if let error = viewModel.errorMessage {
                                HStack(spacing: 8) {
                                    Image(systemName: "exclamationmark.circle.fill")
                                        .foregroundColor(Theme.occupied)
                                    Text(error)
                                        .font(.system(size: 13))
                                        .foregroundColor(Theme.occupied)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.top, 4)
                            }

                            // Submit Button
                            PrimaryButton(
                                viewModel.isSignUp ? "Create Student Account" : "Sign In",
                                iconName: viewModel.isSignUp ? "person.crop.circle.badge.plus" : "arrow.right.circle.fill",
                                isLoading: viewModel.isLoading
                            ) {
                                Task {
                                    focusedField = nil
                                    await viewModel.submit()
                                }
                            }
                            .padding(.top, 8)

                            // Quick Fill Demo Button
                            Button(action: {
                                viewModel.fillDemoCredentials()
                            }) {
                                HStack(spacing: 6) {
                                    Image(systemName: "wand.and.stars")
                                    Text("Fill Demo Credentials")
                                }
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(Theme.primary)
                            }
                            .padding(.top, 4)
                        }
                        .standardCard(cornerRadius: 20, padding: 20)
                        .padding(.horizontal, 20)

                        // Mode Toggle Info
                        VStack(spacing: 12) {
                            HStack {
                                Text(appState.isMockMode ? "🛠 Offline Mock Mode Active" : "🌐 Connected to Supabase Backend")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.secondary)

                                Button(action: {
                                    appState.toggleMockMode()
                                }) {
                                    Text("Switch")
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundColor(Theme.primary)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 3)
                                        .background(Theme.primary.opacity(0.12))
                                        .clipShape(Capsule())
                                }
                            }
                        }
                        .padding(.top, 8)

                        Spacer(minLength: 40)
                    }
                }
            }
            .navigationBarHidden(true)
            .alert("Success", isPresented: $viewModel.showSuccessToast) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.successMessage)
            }
        }
    }
}
