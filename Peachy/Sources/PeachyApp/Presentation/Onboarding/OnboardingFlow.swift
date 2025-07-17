import SwiftUI

struct OnboardingFlow: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.injected) var container: ServiceContainer
    @StateObject private var viewModel = OnboardingViewModel()
    
    var body: some View {
        NavigationStack {
            VStack {
                switch viewModel.currentStep {
                case .welcome:
                    WelcomeView()
                        .environmentObject(viewModel)
                case .roleSelection:
                    RoleSelectionView()
                        .environmentObject(viewModel)
                case .authentication:
                    AuthenticationView()
                        .environmentObject(viewModel)
                }
            }
            .animation(.easeInOut, value: viewModel.currentStep)
        }
        .onChange(of: viewModel.isComplete) { isComplete in
            if isComplete {
                appState.userRole = viewModel.selectedRole
                appState.isAuthenticated = true
            }
        }
    }
}

// MARK: - Welcome View
struct WelcomeView: View {
    @EnvironmentObject var viewModel: OnboardingViewModel
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            Image(systemName: "heart.circle.fill")
                .font(.system(size: 100))
                .foregroundColor(Color("BrandPeach"))
                .symbolEffect(.pulse)
            
            VStack(spacing: 16) {
                Text("Welcome to Peachy")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Bridge the communication gap with\ncolor-coded moods and shared activities")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            Spacer()
            
            Button(action: {
                viewModel.moveToStep(.roleSelection)
            }) {
                Text("Get Started")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color("BrandTeal"))
                    .cornerRadius(12)
            }
            .padding(.horizontal)
            .padding(.bottom, 40)
        }
    }
}

// MARK: - Role Selection View
struct RoleSelectionView: View {
    @EnvironmentObject var viewModel: OnboardingViewModel
    
    var body: some View {
        VStack(spacing: 30) {
            Text("I am a...")
                .font(.title)
                .fontWeight(.semibold)
                .padding(.top, 60)
            
            VStack(spacing: 20) {
                RoleCard(
                    role: .teen,
                    icon: "face.smiling",
                    description: "Express your moods and share your interests",
                    isSelected: viewModel.selectedRole == .teen
                ) {
                    viewModel.selectedRole = .teen
                }
                
                RoleCard(
                    role: .parent,
                    icon: "heart.fill",
                    description: "Understand and connect with your teen",
                    isSelected: viewModel.selectedRole == .parent
                ) {
                    viewModel.selectedRole = .parent
                }
            }
            .padding(.horizontal)
            
            Spacer()
            
            Button(action: {
                viewModel.moveToStep(.authentication)
            }) {
                Text("Continue")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(viewModel.selectedRole != nil ? Color("BrandTeal") : Color.gray)
                    .cornerRadius(12)
            }
            .disabled(viewModel.selectedRole == nil)
            .padding(.horizontal)
            .padding(.bottom, 40)
        }
    }
}

// MARK: - Role Card
struct RoleCard: View {
    let role: AppState.UserRole
    let icon: String
    let description: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 20) {
                Image(systemName: icon)
                    .font(.system(size: 40))
                    .foregroundColor(isSelected ? Color("BrandTeal") : .secondary)
                    .frame(width: 60)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(role.rawValue)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundColor(isSelected ? Color("BrandTeal") : .secondary)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color("BrandTeal").opacity(0.1) : Color(.systemGray6))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color("BrandTeal") : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Authentication View
struct AuthenticationView: View {
    @EnvironmentObject var viewModel: OnboardingViewModel
    @Environment(\.injected) var container: ServiceContainer
    @State private var email = ""
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        VStack(spacing: 30) {
            Text("Sign In")
                .font(.title)
                .fontWeight(.semibold)
                .padding(.top, 60)
            
            VStack(spacing: 20) {
                TextField("Email", text: $email)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .textContentType(.emailAddress)
                    .autocapitalization(.none)
                    .keyboardType(.emailAddress)
                
                Button(action: signInWithEmail) {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text("Continue with Email")
                    }
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color("BrandTeal"))
                .cornerRadius(12)
                .disabled(email.isEmpty || isLoading)
                
                Text("or")
                    .foregroundColor(.secondary)
                
                Button(action: signInWithApple) {
                    HStack {
                        Image(systemName: "applelogo")
                        Text("Sign in with Apple")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.black)
                    .cornerRadius(12)
                }
            }
            .padding(.horizontal)
            
            Spacer()
        }
        .alert("Error", isPresented: $showError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
    }
    
    private func signInWithEmail() {
        isLoading = true
        Task {
            do {
                try await container.authService.signIn(email: email)
                await MainActor.run {
                    viewModel.isComplete = true
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showError = true
                    isLoading = false
                }
            }
        }
    }
    
    private func signInWithApple() {
        isLoading = true
        Task {
            do {
                try await container.authService.signInWithApple()
                await MainActor.run {
                    viewModel.isComplete = true
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showError = true
                    isLoading = false
                }
            }
        }
    }
}

// MARK: - Onboarding ViewModel
class OnboardingViewModel: ObservableObject {
    @Published var currentStep: OnboardingStep = .welcome
    @Published var selectedRole: AppState.UserRole?
    @Published var isComplete = false
    
    enum OnboardingStep {
        case welcome
        case roleSelection
        case authentication
    }
    
    func moveToStep(_ step: OnboardingStep) {
        withAnimation {
            currentStep = step
        }
    }
}

