import SwiftUI

struct WelcomeView: View {
    @Binding var currentStep: OnboardingStep
    @State private var showSignIn = false
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            Image(systemName: "heart.circle.fill")
                .font(.system(size: 100))
                .foregroundColor(Color(hex: "#FFC7B2"))
            
            VStack(spacing: 16) {
                Text("Welcome to Peachy")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Connect with your family through moods and shared activities")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            Spacer()
            
            VStack(spacing: 16) {
                if showSignIn {
                    // Sign In Options
                    Button(action: {
                        currentStep = .auth
                    }) {
                        Text("Sign In with Email")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(hex: "#2BB3B3"))
                            .cornerRadius(12)
                    }
                    
                    Button(action: {
                        currentStep = .auth
                    }) {
                        HStack {
                            Image(systemName: "applelogo")
                            Text("Sign In with Apple")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.black)
                        .cornerRadius(12)
                    }
                    
                    Button(action: {
                        withAnimation {
                            showSignIn = false
                        }
                    }) {
                        Text("Don't have an account? Sign Up")
                            .font(.footnote)
                            .foregroundColor(Color(hex: "#2BB3B3"))
                    }
                } else {
                    // Sign Up Options
                    Button(action: {
                        currentStep = .signUp
                    }) {
                        Text("Sign Up")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(hex: "#2BB3B3"))
                            .cornerRadius(12)
                    }
                    
                    Button(action: {
                        currentStep = .auth
                    }) {
                        HStack {
                            Image(systemName: "applelogo")
                            Text("Sign In with Apple")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.black)
                        .cornerRadius(12)
                    }
                    
                    Button(action: {
                        withAnimation {
                            showSignIn = true
                        }
                    }) {
                        Text("Already have an account? Sign In")
                            .font(.footnote)
                            .foregroundColor(Color(hex: "#2BB3B3"))
                    }
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 50)
        }
    }
}

#Preview {
    WelcomeView(currentStep: .constant(.welcome))
}