import Foundation

public final class MockHobbyService: HobbyServiceProtocol {
    public init() {}
    
    public func getHobbies() -> [String] {
        return [
            "Gaming", "Reading", "Music", "Sports", "Art", "Cooking",
            "Photography", "Dancing", "Writing", "Coding", "Movies",
            "Anime", "Travel", "Fashion", "Fitness", "Yoga",
            "Swimming", "Basketball", "Soccer", "Tennis", "Running",
            "Drawing", "Painting", "Singing", "Guitar", "Piano",
            "Chess", "Board Games", "Hiking", "Camping", "Gardening",
            "Volunteering", "Drama", "Debate", "Science", "Math"
        ]
    }
}