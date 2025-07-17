import SwiftUI

struct RolePickerView: View {
    @Binding var currentStep: OnboardingStep
    @EnvironmentObject var viewModel: OnboardingViewModel
    @State private var selectedRole: UserRole?
    @State private var isLoading = false
    
    var body: some View {
        VStack(spacing: 30) {
            Text("Who are you?")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.top, 50)
            
            Text("Select your role to personalize your experience")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            VStack(spacing: 16) {
                roleButton(role: UserRole.teen, 
                          icon: "person.fill",
                          description: "I'm under 18")
                
                roleButton(role: UserRole.parent,
                          icon: "figure.2",
                          description: "I'm a parent or guardian")
            }
            .padding(.horizontal)
            
            Spacer()
            
            VStack(spacing: 12) {
                Button(action: saveRole) {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text("Continue")
                    }
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(selectedRole != nil ? Color(hex: "#2BB3B3") : Color.gray)
                .cornerRadius(12)
                .disabled(selectedRole == nil || isLoading)
                
                Button(action: {
                    currentStep = .complete
                }) {
                    Text("Pair Later")
                        .font(.body)
                        .foregroundColor(Color(hex: "#2BB3B3"))
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 30)
        }
    }
    
    private func roleButton(role: UserRole, icon: String, description: String) -> some View {
        Button(action: { selectedRole = role }) {
            HStack(spacing: 20) {
                Image(systemName: icon)
                    .font(.system(size: 30))
                    .foregroundColor(selectedRole == role ? .white : Color(hex: "#2BB3B3"))
                    .frame(width: 50)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(role.rawValue)
                        .font(.headline)
                        .foregroundColor(selectedRole == role ? .white : .primary)
                    
                    Text(description)
                        .font(.caption)
                        .foregroundColor(selectedRole == role ? .white.opacity(0.8) : .secondary)
                }
                
                Spacer()
            }
            .padding()
            .background(selectedRole == role ? Color(hex: "#2BB3B3") : Color.gray.opacity(0.1))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(selectedRole == role ? Color(hex: "#2BB3B3") : Color.clear, lineWidth: 2)
            )
        }
    }
    
    private func saveRole() {
        guard let role = selectedRole else { return }
        isLoading = true
        
        Task {
            do {
                try await viewModel.updateUserRole(role)
                await MainActor.run {
                    currentStep = .complete
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                }
            }
        }
    }
}

#Preview {
    RolePickerView(currentStep: .constant(.rolePicker))
        .environmentObject(OnboardingViewModel())
}