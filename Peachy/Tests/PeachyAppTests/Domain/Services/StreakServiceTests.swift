import XCTest
@testable import PeachyApp

final class StreakServiceTests: XCTestCase {
    var streakService: MockStreakService!
    var realmManager: RealmManager!
    let testUserId = "test-user-123"
    
    override func setUp() {
        super.setUp()
        streakService = MockStreakService()
        realmManager = RealmManager.shared
        
        // Clear existing data
        try? realmManager.deleteAll(MoodLog.self)
    }
    
    override func tearDown() {
        try? realmManager.deleteAll(MoodLog.self)
        super.tearDown()
    }
    
    func testCalculateStreak_NoMoodLogs_ReturnsZero() async {
        let streak = await streakService.calculateStreak(for: testUserId)
        XCTAssertEqual(streak, 0)
    }
    
    func testCalculateStreak_SingleDayLog_ReturnsOne() async {
        let moodLog = MoodLog()
        moodLog.userId = testUserId
        moodLog.colorHex = MoodColor.good.hex
        moodLog.createdAt = Date()
        
        try? realmManager.save(moodLog)
        
        let streak = await streakService.calculateStreak(for: testUserId)
        XCTAssertEqual(streak, 1)
    }
    
    func testCalculateStreak_ConsecutiveDays_ReturnsCorrectStreak() async {
        let calendar = Calendar.current
        let today = Date()
        
        // Create logs for 3 consecutive days
        for i in 0..<3 {
            let date = calendar.date(byAdding: .day, value: -i, to: today)!
            let moodLog = MoodLog()
            moodLog.userId = testUserId
            moodLog.colorHex = MoodColor.good.hex
            moodLog.createdAt = date
            try? realmManager.save(moodLog)
        }
        
        let streak = await streakService.calculateStreak(for: testUserId)
        XCTAssertEqual(streak, 3)
    }
    
    func testCalculateStreak_MissedDay_ReturnsPartialStreak() async {
        let calendar = Calendar.current
        let today = Date()
        
        // Create log for today
        let todayLog = MoodLog()
        todayLog.userId = testUserId
        todayLog.colorHex = MoodColor.good.hex
        todayLog.createdAt = today
        try? realmManager.save(todayLog)
        
        // Create log for 2 days ago (missing yesterday)
        let twoDaysAgo = calendar.date(byAdding: .day, value: -2, to: today)!
        let oldLog = MoodLog()
        oldLog.userId = testUserId
        oldLog.colorHex = MoodColor.okay.hex
        oldLog.createdAt = twoDaysAgo
        try? realmManager.save(oldLog)
        
        let streak = await streakService.calculateStreak(for: testUserId)
        XCTAssertEqual(streak, 1)
    }
    
    func testGetTodayMoodCount_NoLogs_ReturnsZero() async {
        let count = await streakService.getTodayMoodCount(for: testUserId)
        XCTAssertEqual(count, 0)
    }
    
    func testGetTodayMoodCount_MultipleLogs_ReturnsCorrectCount() async {
        let today = Date()
        
        // Create 3 logs for today
        for i in 0..<3 {
            let moodLog = MoodLog()
            moodLog.userId = testUserId
            moodLog.colorHex = MoodColor.allCases[i % 3].hex
            moodLog.createdAt = today
            try? realmManager.save(moodLog)
        }
        
        // Create 1 log for yesterday (should not be counted)
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today)!
        let yesterdayLog = MoodLog()
        yesterdayLog.userId = testUserId
        yesterdayLog.colorHex = MoodColor.good.hex
        yesterdayLog.createdAt = yesterday
        try? realmManager.save(yesterdayLog)
        
        let count = await streakService.getTodayMoodCount(for: testUserId)
        XCTAssertEqual(count, 3)
    }
}