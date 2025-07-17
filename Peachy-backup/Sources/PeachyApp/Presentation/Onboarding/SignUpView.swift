import SwiftUI

struct SignUpView: View {
    @Binding var currentStep: OnboardingStep
    @EnvironmentObject var viewModel: OnboardingViewModel
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Create Account")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.top, 50)
            
            VStack(spacing: 16) {
                TextField("Email", text: $email)
                    .textFieldStyle(.roundedBorder)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .textContentType(.emailAddress)
                
                SecureField("Password", text: $password)
                    .textFieldStyle(.roundedBorder)
                    .textContentType(.newPassword)
                
                SecureField("Confirm Password", text: $confirmPassword)
                    .textFieldStyle(.roundedBorder)
                    .textContentType(.newPassword)
                
                if let error = errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(.horizontal)
            
            VStack(spacing: 12) {
                Button(action: signUp) {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text("Sign Up")
                    }
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(isFormValid ? Color(hex: "#2BB3B3") : Color.gray)
                .cornerRadius(12)
                .disabled(!isFormValid || isLoading)
                
                Button(action: {
                    currentStep = .welcome
                }) {
                    Text("Already have an account? Sign In")
                        .font(.footnote)
                        .foregroundColor(Color(hex: "#2BB3B3"))
                }
            }
            .padding(.horizontal)
            
            Spacer()
        }
        .disabled(isLoading)
    }
    
    private var isFormValid: Bool {
        !email.isEmpty && 
        email.contains("@") && 
        !password.isEmpty && 
        password.count >= 6 &&
        password == confirmPassword
    }
    
    private func signUp() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                try await viewModel.signUp(email: email, password: password)
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
    SignUpView(currentStep: .constant(.signUp))
        .environmentObject(OnboardingViewModel())
}