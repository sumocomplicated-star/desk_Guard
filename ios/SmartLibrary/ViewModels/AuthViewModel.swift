import Foundation
import SwiftUI

@MainActor
public final class AuthViewModel: ObservableObject {
    @Published public var email: String = ""
    @Published public var password: String = ""
    @Published public var isSignUp: Bool = false
    @Published public var isLoading: Bool = false
    @Published public var errorMessage: String?
    @Published public var showSuccessToast: Bool = false
    @Published public var successMessage: String = ""

    private let appState: AppState

    public init(appState: AppState) {
        self.appState = appState
    }

    public var isFormValid: Bool {
        return email.contains("@") && email.contains(".") && password.count >= 6
    }

    public func submit() async {
        guard isFormValid else {
            errorMessage = "Please enter a valid email and a password of at least 6 characters."
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            if appState.isMockMode {
                // Mock Auth
                try await Task.sleep(nanoseconds: 500_000_000)
                await appState.didSignIn(email: email)
                HapticFeedback.success()
            } else {
                if isSignUp {
                    let response = try await appState.supabaseService.signUp(email: email, password: password)
                    if response.session != nil {
                        await appState.didSignIn(email: email)
                        HapticFeedback.success()
                    } else {
                        successMessage = "Account created! If email confirmation is required, please check your inbox."
                        showSuccessToast = true
                        isSignUp = false
                    }
                } else {
                    _ = try await appState.supabaseService.signIn(email: email, password: password)
                    await appState.didSignIn(email: email)
                    HapticFeedback.success()
                }
            }
        } catch {
            HapticFeedback.error()
            let msg = error.localizedDescription
            if msg.localizedCaseInsensitiveContains("invalid login credentials") {
                errorMessage = "Incorrect email or password. Please try again."
            } else if msg.localizedCaseInsensitiveContains("user already registered") {
                errorMessage = "An account with this email already exists. Try signing in."
            } else {
                errorMessage = msg
            }
        }

        isLoading = false
    }

    public func toggleMode() {
        isSignUp.toggle()
        errorMessage = nil
    }

    public func fillDemoCredentials() {
        email = "student@library.edu"
        password = "Password123!"
    }
}
