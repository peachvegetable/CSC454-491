import XCTest
@testable import PeachyApp

@MainActor
final class EmojiPickerViewModelTests: XCTestCase {
    var viewModel: EmojiPickerViewModel!
    
    override func setUp() {
        super.setUp()
        viewModel = EmojiPickerViewModel()
        // Clear UserDefaults for testing
        UserDefaults.standard.removeObject(forKey: "recentEmojis")
    }
    
    override func tearDown() {
        UserDefaults.standard.removeObject(forKey: "recentEmojis")
        super.tearDown()
    }
    
    func testSelectEmoji_SetsSelectedEmoji() {
        let testEmoji = "😊"
        viewModel.selectEmoji(testEmoji)
        
        XCTAssertEqual(viewModel.selectedEmoji, testEmoji)
    }
    
    func testSelectEmoji_AddsToRecentEmojis() {
        let testEmoji = "😊"
        viewModel.selectEmoji(testEmoji)
        
        XCTAssertTrue(viewModel.recentEmojis.contains(testEmoji))
        XCTAssertEqual(viewModel.recentEmojis.first, testEmoji)
    }
    
    func testSelectEmoji_MovesDuplicateToFront() {
        let emoji1 = "😊"
        let emoji2 = "😎"
        
        viewModel.selectEmoji(emoji1)
        viewModel.selectEmoji(emoji2)
        viewModel.selectEmoji(emoji1)
        
        XCTAssertEqual(viewModel.recentEmojis.count, 2)
        XCTAssertEqual(viewModel.recentEmojis.first, emoji1)
        XCTAssertEqual(viewModel.recentEmojis.last, emoji2)
    }
    
    func testRecentEmojis_LimitedToMaxCount() {
        // Add more than max emojis
        for i in 0..<15 {
            viewModel.selectEmoji("😊\(i)")
        }
        
        XCTAssertEqual(viewModel.recentEmojis.count, 12)
    }
    
    func testClearSelection_RemovesSelectedEmoji() {
        viewModel.selectEmoji("😊")
        XCTAssertNotNil(viewModel.selectedEmoji)
        
        viewModel.clearSelection()
        XCTAssertNil(viewModel.selectedEmoji)
    }
    
    func testRecentEmojis_PersistAcrossInstances() {
        let testEmoji = "😊"
        viewModel.selectEmoji(testEmoji)
        
        // Create new instance
        let newViewModel = EmojiPickerViewModel()
        
        XCTAssertTrue(newViewModel.recentEmojis.contains(testEmoji))
    }
}