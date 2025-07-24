import SwiftUI

struct HobbyDetailView: View {
    let hobby: HobbyModel
    @StateObject private var viewModel = HobbyDetailViewModel()
    @State private var editingFact = false
    @State private var newFact = ""
    
    private var isOwnHobby: Bool {
        guard let currentUserId = ServiceContainer.shared.authService.currentUser?.id else { return false }
        return hobby.ownerId == currentUserId
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Hobby Header
                VStack(alignment: .leading, spacing: 8) {
                    Text(hobby.name)
                        .font(.largeTitle)
                        .bold()
                    
                    if !isOwnHobby {
                        // Show owner name when viewing someone else's hobby
                        if let owner = viewModel.hobbyOwner {
                            Text("\(owner)'s hobby")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    if !hobby.fact.isEmpty {
                        Text(hobby.fact)
                            .font(.body)
                            .foregroundColor(.secondary)
                            .padding(.vertical, 8)
                    }
                }
                .padding(.horizontal)
                
                // AI-Generated Introduction
                VStack(alignment: .leading, spacing: 12) {
                    Label("About \(hobby.name)", systemImage: "info.circle.fill")
                        .font(.headline)
                        .foregroundColor(Color(hex: "#2BB3B3"))
                    
                    Text(viewModel.hobbyIntroduction)
                        .font(.body)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                }
                .padding(.horizontal)
                
                // Latest News & Updates
                VStack(alignment: .leading, spacing: 12) {
                    Label("Latest News", systemImage: "newspaper.fill")
                        .font(.headline)
                        .foregroundColor(Color(hex: "#FFC7B2"))
                    
                    ForEach(viewModel.hobbyNews, id: \.title) { news in
                        NewsCard(news: news)
                    }
                }
                .padding(.horizontal)
                
                // Upcoming Events
                VStack(alignment: .leading, spacing: 12) {
                    Label("Upcoming Events", systemImage: "calendar")
                        .font(.headline)
                        .foregroundColor(Color(hex: "#2BB3B3"))
                    
                    ForEach(viewModel.upcomingEvents, id: \.title) { event in
                        EventCard(event: event)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if isOwnHobby {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Edit") {
                        newFact = hobby.fact
                        editingFact = true
                    }
                }
            }
        }
        .sheet(isPresented: $editingFact) {
            EditHobbyFactSheet(hobby: hobby, fact: $newFact)
        }
        .onAppear {
            viewModel.loadHobbyInfo(for: hobby)
        }
    }
}

struct NewsCard: View {
    let news: HobbyNews
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(news.title)
                .font(.subheadline)
                .fontWeight(.medium)
            
            Text(news.summary)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(2)
            
            Text(news.date)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

struct EventCard: View {
    let event: HobbyEvent
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(event.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(event.location)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(event.date)
                    .font(.caption)
                    .fontWeight(.medium)
                
                Text(event.time)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

struct EditHobbyFactSheet: View {
    let hobby: HobbyModel
    @Binding var fact: String
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Share something interesting about \(hobby.name)")
                    .font(.headline)
                    .padding(.horizontal)
                
                TextEditor(text: $fact)
                    .padding(8)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .frame(minHeight: 100)
                    .padding(.horizontal)
                
                Spacer()
            }
            .navigationTitle("Edit Hobby Info")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        // Save the updated fact
                        do {
                            try RealmManager.shared.realm.write {
                                hobby.fact = fact
                            }
                            dismiss()
                        } catch {
                            print("Error updating hobby fact: \(error)")
                        }
                    }
                    .fontWeight(.medium)
                }
            }
        }
    }
}

// ViewModels and Models
struct HobbyNews {
    let title: String
    let summary: String
    let date: String
}

struct HobbyEvent {
    let title: String
    let location: String
    let date: String
    let time: String
}

@MainActor
class HobbyDetailViewModel: ObservableObject {
    @Published var hobbyIntroduction = ""
    @Published var hobbyNews: [HobbyNews] = []
    @Published var upcomingEvents: [HobbyEvent] = []
    @Published var hobbyOwner: String?
    
    func loadHobbyInfo(for hobby: HobbyModel) {
        // Load owner name if it's not the current user's hobby
        if let currentUserId = ServiceContainer.shared.authService.currentUser?.id,
           hobby.ownerId != currentUserId {
            // Find the owner's profile
            if let owner = RealmManager.shared.fetch(UserProfile.self, 
                predicate: NSPredicate(format: "id == %@", hobby.ownerId)).first {
                hobbyOwner = owner.displayName ?? owner.email
            }
        }
        
        // Generate introduction based on hobby
        generateIntroduction(for: hobby.name)
        
        // Load mock news and events
        loadMockNews(for: hobby.name)
        loadMockEvents(for: hobby.name)
    }
    
    private func generateIntroduction(for hobby: String) {
        // In production, this would use AI to generate personalized content
        switch hobby.lowercased() {
        case "gaming":
            hobbyIntroduction = "Gaming is more than entertainment - it's a way to develop problem-solving skills, hand-eye coordination, and social connections. Whether you prefer single-player adventures or multiplayer competitions, gaming offers endless worlds to explore and challenges to overcome."
        case "photography":
            hobbyIntroduction = "Photography captures moments and tells stories through images. It combines technical skills with artistic vision, teaching patience, attention to detail, and a unique way of seeing the world. From portraits to landscapes, every photo is an opportunity to create art."
        case "music":
            hobbyIntroduction = "Music is a universal language that expresses emotions and connects people across cultures. Whether you're playing an instrument, singing, or simply listening, music enhances creativity, improves memory, and provides a healthy outlet for self-expression."
        case "sports":
            hobbyIntroduction = "Sports build physical fitness, teamwork, and mental resilience. They teach valuable life lessons about dedication, perseverance, and sportsmanship while keeping you active and healthy. Every game is an opportunity to improve and push your limits."
        case "reading":
            hobbyIntroduction = "Reading opens doors to new worlds, ideas, and perspectives. It improves vocabulary, enhances empathy, and stimulates imagination. Whether fiction or non-fiction, each book is a journey that enriches your mind and broadens your understanding."
        case "cooking":
            hobbyIntroduction = "Cooking is both an art and a science, combining creativity with practical skills. It promotes healthy eating, cultural exploration, and brings people together. From simple recipes to gourmet dishes, cooking is a rewarding journey of flavors and techniques."
        default:
            hobbyIntroduction = "\(hobby) is a wonderful way to express yourself, learn new skills, and connect with others who share your interests. It offers opportunities for personal growth, creativity, and building a community around shared passions."
        }
    }
    
    private func loadMockNews(for hobby: String) {
        // In production, this would fetch real news from an API
        switch hobby.lowercased() {
        case "gaming":
            hobbyNews = [
                HobbyNews(title: "New Gaming Console Released", summary: "The latest gaming console features improved graphics and faster loading times", date: "2 days ago"),
                HobbyNews(title: "Esports Tournament Announced", summary: "Local tournament with $10,000 prize pool coming next month", date: "1 week ago"),
                HobbyNews(title: "Game Development Workshop", summary: "Free online workshop for aspiring game developers", date: "3 days ago")
            ]
        case "photography":
            hobbyNews = [
                HobbyNews(title: "Photography Exhibition Opens", summary: "Local gallery showcasing works from emerging photographers", date: "Today"),
                HobbyNews(title: "New Camera Technology", summary: "Breakthrough in low-light photography capabilities", date: "4 days ago"),
                HobbyNews(title: "Photo Contest Winners", summary: "National Geographic announces this year's winners", date: "1 week ago")
            ]
        default:
            hobbyNews = [
                HobbyNews(title: "Community Meetup", summary: "Local \(hobby) enthusiasts gathering this weekend", date: "Tomorrow"),
                HobbyNews(title: "New Techniques Discovered", summary: "Experts share innovative approaches to \(hobby)", date: "3 days ago"),
                HobbyNews(title: "Online Resources", summary: "Top websites and apps for learning \(hobby)", date: "5 days ago")
            ]
        }
    }
    
    private func loadMockEvents(for hobby: String) {
        // In production, this would fetch real events from an API
        upcomingEvents = [
            HobbyEvent(title: "\(hobby) Workshop", location: "Community Center", date: "Jan 15", time: "2:00 PM"),
            HobbyEvent(title: "Beginner's Class", location: "Online", date: "Jan 20", time: "6:00 PM"),
            HobbyEvent(title: "\(hobby) Competition", location: "City Arena", date: "Feb 1", time: "10:00 AM")
        ]
    }
}

#Preview {
    NavigationView {
        HobbyDetailView(hobby: HobbyModel(name: "Photography", ownerId: "123", fact: "I love capturing sunsets"))
    }
}