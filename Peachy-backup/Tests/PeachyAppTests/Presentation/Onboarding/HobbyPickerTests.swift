import XCTest
@testable import PeachyApp

final class HobbyPickerTests: XCTestCase {
    
    func testSelectionLimit() {
        // Given
        var selectedHobbies: Set<String> = []
        let maxHobbies = 3
        let hobbies = ["Gaming", "Reading", "Music", "Sports", "Art"]
        
        // When - Try to add more than max
        for hobby in hobbies {
            if selectedHobbies.count < maxHobbies {
                selectedHobbies.insert(hobby)
            }
        }
        
        // Then
        XCTAssertEqual(selectedHobbies.count, maxHobbies, "Should not exceed max hobbies")
        XCTAssertTrue(selectedHobbies.contains("Gaming"))
        XCTAssertTrue(selectedHobbies.contains("Reading"))
        XCTAssertTrue(selectedHobbies.contains("Music"))
        XCTAssertFalse(selectedHobbies.contains("Sports"))
        XCTAssertFalse(selectedHobbies.contains("Art"))
    }
    
    func testToggleHobbySelection() {
        // Given
        var selectedHobbies: Set<String> = []
        let hobby = "Gaming"
        
        // When - First toggle (add)
        if selectedHobbies.contains(hobby) {
            selectedHobbies.remove(hobby)
        } else {
            selectedHobbies.insert(hobby)
        }
        
        // Then
        XCTAssertTrue(selectedHobbies.contains(hobby), "Hobby should be added")
        
        // When - Second toggle (remove)
        if selectedHobbies.contains(hobby) {
            selectedHobbies.remove(hobby)
        } else {
            selectedHobbies.insert(hobby)
        }
        
        // Then
        XCTAssertFalse(selectedHobbies.contains(hobby), "Hobby should be removed")
    }
    
    func testHobbySearchFiltering() {
        // Given
        let presetHobbies = ["Gaming", "Reading", "Music", "Sports", "Art"]
        let searchText = "ing"
        
        // When
        let filtered = presetHobbies.filter { 
            $0.localizedCaseInsensitiveContains(searchText) 
        }
        
        // Then
        XCTAssertEqual(filtered.count, 2, "Should find 2 hobbies containing 'ing'")
        XCTAssertTrue(filtered.contains("Gaming"))
        XCTAssertTrue(filtered.contains("Reading"))
    }
}