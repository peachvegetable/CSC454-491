import SwiftUI
import AuthenticationServices

struct AuthView: View {
    @Binding var currentStep: OnboardingStep
    @EnvironmentObject var viewModel: OnboardingViewModel
    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Sign In")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.top, 50)
            
            VStack(spacing: 16) {
                TextField("Email", text: $email)
                    .textFieldStyle(.roundedBorder)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                
                SecureField("Password", text: $password)
                    .textFieldStyle(.roundedBorder)
                
                if let error = errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
            .padding(.horizontal)
            
            VStack(spacing: 12) {
                Button(action: signInWithEmail) {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text("Sign In")
                    }
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(hex: "#2BB3B3"))
                .cornerRadius(12)
                .disabled(isLoading || email.isEmpty)
                
                SignInWithAppleButton(
                    onRequest: { request in
                        request.requestedScopes = [.fullName, .email]
                    },
                    onCompletion: { result in
                        handleAppleSignIn(result)
                    }
                )
                .signInWithAppleButtonStyle(.black)
                .frame(height: 50)
                .cornerRadius(12)
            }
            .padding(.horizontal)
            
            Spacer()
        }
        .disabled(isLoading)
    }
    
    private func signInWithEmail() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                try await viewModel.signIn(email: email, password: password)
                await MainActor.run {
                    currentStep = .hobbyPicker
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isLoading = false
                }
            }
        }
    }
    
    private func handleAppleSignIn(_ result: Result<ASAuthorization, Error>) {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                try await viewModel.signInWithApple()
                await MainActor.run {
                    currentStep = .hobbyPicker
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isLoading = false
                }
            }
        }
    }
}

#Preview {
    AuthView(currentStep: .constant(.auth))
        .environmentObject(OnboardingViewModel())
}