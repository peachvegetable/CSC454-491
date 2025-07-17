import SwiftUI

struct PairingView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.injected) var container: ServiceContainer
    @State private var pairingCode = ""
    @State private var generatedCode: String?
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 30) {
                Image(systemName: "person.2.circle")
                    .font(.system(size: 80))
                    .foregroundColor(Color("BrandTeal"))
                    .padding(.top, 40)
                
                Text("Connect Your Circle")
                    .font(.title)
                    .fontWeight(.semibold)
                
                Text("Link with your \(appState.userRole == UserRole.teen ? "parent" : "teen") to start sharing moods and activities")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                if appState.userRole == UserRole.parent {
                    parentView
                } else {
                    teenView
                }
                
                Spacer()
            }
            .navigationBarHidden(true)
        }
        .alert("Error", isPresented: $showError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
    }
    
    // MARK: - Parent View
    @ViewBuilder
    private var parentView: some View {
        VStack(spacing: 20) {
            if let code = generatedCode {
                VStack(spacing: 16) {
                    Text("Share this code with your teen:")
                        .font(.headline)
                    
                    Text(code)
                        .font(.system(size: 36, weight: .bold, design: .monospaced))
                        .foregroundColor(Color("BrandTeal"))
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color("BrandTeal").opacity(0.1))
                        )
                    
                    Button(action: copyCode) {
                        HStack {
                            Image(systemName: "doc.on.doc")
                            Text("Copy Code")
                        }
                        .font(.callout)
                        .foregroundColor(Color("BrandTeal"))
                    }
                }
            } else {
                Button(action: generateCode) {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text("Generate Pairing Code")
                    }
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color("BrandTeal"))
                .cornerRadius(12)
                .disabled(isLoading)
            }
        }
        .padding(.horizontal)
    }
    
    // MARK: - Teen View
    @ViewBuilder
    private var teenView: some View {
        VStack(spacing: 20) {
            TextField("Enter pairing code", text: $pairingCode)
                .font(.system(size: 24, weight: .semibold, design: .monospaced))
                .multilineTextAlignment(.center)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .autocapitalization(.allCharacters)
            
            Button(action: submitCode) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Text("Connect")
                }
            }
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(pairingCode.count >= 6 ? Color("BrandTeal") : Color.gray)
            .cornerRadius(12)
            .disabled(pairingCode.count < 6 || isLoading)
        }
        .padding(.horizontal)
    }
    
    // MARK: - Actions
    private func generateCode() {
        isLoading = true
        
        // Simulate API call
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            generatedCode = String((0..<6).map { _ in "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789".randomElement()! })
            isLoading = false
            
            // Auto-complete pairing after code generation (mock)
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                appState.isPaired = true
            }
        }
    }
    
    private func copyCode() {
        guard let code = generatedCode else { return }
        UIPasteboard.general.string = code
        
        // Show feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
    
    private func submitCode() {
        isLoading = true
        
        // Simulate API call
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            if pairingCode == "TEST123" || pairingCode.count == 6 {
                appState.isPaired = true
            } else {
                errorMessage = "Invalid pairing code"
                showError = true
            }
            isLoading = false
        }
    }
}