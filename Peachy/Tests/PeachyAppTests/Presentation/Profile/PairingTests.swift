import XCTest
@testable import PeachyApp

final class PairingTests: XCTestCase {
    var viewModel: ProfileViewModel!
    
    override func setUp() {
        super.setUp()
        viewModel = ProfileViewModel()
    }
    
    override func tearDown() {
        viewModel = nil
        super.tearDown()
    }
    
    func testGeneratePairCodeDoesNotCrash() {
        // Given - User is signed in
        let expectation = expectation(description: "Pairing code generation should not crash")
        
        // When - Generate pairing code
        Task {
            // Sign in first
            let authService = ServiceContainer.shared.authService
            _ = try? await authService.signIn(email: "test@example.com", password: "password")
            
            await MainActor.run {
                // Load user profile
                viewModel.loadUserProfile()
                
                // Generate pairing code - should not crash
                viewModel.generatePairingCode()
                
                // Verify code was generated
                XCTAssertNotNil(viewModel.pairingCode, "Pairing code should be generated")
                XCTAssertEqual(viewModel.pairingCode?.count, 6, "Pairing code should be 6 digits")
                
                expectation.fulfill()
            }
        }
        
        waitForExpectations(timeout: 5.0)
    }
    
    func testPairingCodeIsNumeric() {
        // Given
        viewModel.generatePairingCode()
        
        // Then
        if let code = viewModel.pairingCode {
            XCTAssertTrue(Int(code) != nil, "Pairing code should be numeric")
            XCTAssertTrue(code.allSatisfy { $0.isNumber }, "All characters should be numbers")
        }
    }
    
    func testPairingCodeRangeIsValid() {
        // When
        for _ in 0..<10 {
            viewModel.generatePairingCode()
            
            // Then
            if let code = viewModel.pairingCode,
               let numericCode = Int(code) {
                XCTAssertGreaterThanOrEqual(numericCode, 100000, "Code should be at least 100000")
                XCTAssertLessThanOrEqual(numericCode, 999999, "Code should be at most 999999")
            }
        }
    }
}