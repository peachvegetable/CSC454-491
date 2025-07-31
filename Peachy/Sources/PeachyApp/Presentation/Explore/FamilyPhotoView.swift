import SwiftUI
import PhotosUI

// MARK: - Models

struct FamilyPhoto: Identifiable, Equatable {
    let id: String
    let imageName: String // For mock data, using asset names
    let thumbnailName: String
    let uploadedBy: String
    let uploadedAt: Date
    let albumId: String?
    let challengeId: String?
    let moodInfo: MoodPhotoInfo?
    var tags: [String] = [] // family member IDs
    var reactions: [PhotoReaction] = []
    var comments: [PhotoComment] = []
    let location: String?
    let caption: String?
    var isFavorite: Bool = false
    
    static func == (lhs: FamilyPhoto, rhs: FamilyPhoto) -> Bool {
        lhs.id == rhs.id
    }
}

struct MoodPhotoInfo: Equatable {
    let moodColor: Color
    let moodEmoji: String
    let moodDescription: String
}

struct PhotoReaction: Equatable {
    let userId: String
    let type: ReactionType
    let timestamp: Date
}

enum ReactionType: String, CaseIterable {
    case love = "❤️"
    case laugh = "😂"
    case wow = "😮"
    case celebrate = "🎉"
}

struct PhotoComment: Equatable {
    let id: String
    let userId: String
    let text: String
    let timestamp: Date
}

struct PhotoAlbum: Identifiable {
    let id: String
    let name: String
    let coverPhotoName: String
    let photoCount: Int
    let createdBy: String
    let createdAt: Date
    let isDefault: Bool
}

struct DailyChallenge: Identifiable {
    let id: String
    let date: Date
    let prompt: String
    let icon: String
    let points: Int
    var submissions: [String] = [] // photo IDs
    var isCompleted: Bool {
        !submissions.isEmpty
    }
}

// MARK: - Main View

struct FamilyPhotoView: View {
    @StateObject private var viewModel = FamilyPhotoViewModel()
    @State private var selectedTab = 0
    @State private var showPhotoCapture = false
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: { dismiss() }) {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .semibold))
                            Text("Back")
                                .font(.body)
                        }
                        .foregroundColor(Color(hex: "#2BB3B3"))
                    }
                    
                    Spacer()
                    
                    // Stats button
                    Button(action: { }) {
                        HStack(spacing: 4) {
                            Image(systemName: "flame.fill")
                                .font(.caption)
                                .foregroundColor(.orange)
                            Text("\(viewModel.currentStreak)")
                                .font(.caption)
                                .bold()
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(20)
                    }
                }
                .padding()
                
                VStack(alignment: .leading) {
                    Text("Family Photos")
                        .font(.largeTitle)
                        .bold()
                    Text("Capture and share memories")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
                .padding(.bottom)
                
                // Tab selector
                Picker("", selection: $selectedTab) {
                    Text("Albums").tag(0)
                    Text("Challenge").tag(1)
                    Text("Mood").tag(2)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
                .padding(.bottom)
                
                // Content
                TabView(selection: $selectedTab) {
                    AlbumsView(viewModel: viewModel)
                        .tag(0)
                    
                    DailyChallengeView(viewModel: viewModel)
                        .tag(1)
                    
                    MoodPhotosView(viewModel: viewModel)
                        .tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }
            
            // Floating action button
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button(action: { showPhotoCapture = true }) {
                        Image(systemName: "camera.fill")
                            .font(.title2)
                            .foregroundColor(.white)
                            .frame(width: 56, height: 56)
                            .background(Color(hex: "#2BB3B3"))
                            .clipShape(Circle())
                            .shadow(radius: 4)
                    }
                    .padding()
                }
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showPhotoCapture) {
            PhotoCaptureView(viewModel: viewModel)
        }
    }
}

// MARK: - Albums View

struct AlbumsView: View {
    @ObservedObject var viewModel: FamilyPhotoViewModel
    @State private var selectedAlbum: PhotoAlbum?
    @State private var showCreateAlbum = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Quick stats
                HStack(spacing: 20) {
                    StatCard(
                        title: "Total Photos",
                        value: "\(viewModel.allPhotos.count)",
                        icon: "photo",
                        color: .blue
                    )
                    StatCard(
                        title: "This Month",
                        value: "\(viewModel.photosThisMonth)",
                        icon: "calendar",
                        color: .green
                    )
                    StatCard(
                        title: "Favorites",
                        value: "\(viewModel.favoritePhotos.count)",
                        icon: "heart.fill",
                        color: .pink
                    )
                }
                .padding(.horizontal)
                
                // Albums
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Albums")
                            .font(.headline)
                        Spacer()
                        Button(action: { showCreateAlbum = true }) {
                            Image(systemName: "plus.circle")
                                .foregroundColor(Color(hex: "#2BB3B3"))
                        }
                    }
                    .padding(.horizontal)
                    
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                        ForEach(viewModel.albums) { album in
                            AlbumCard(album: album) {
                                selectedAlbum = album
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                
                // Recent photos
                VStack(alignment: .leading, spacing: 12) {
                    Text("Recent Photos")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    PhotoGrid(photos: viewModel.recentPhotos, viewModel: viewModel)
                }
            }
            .padding(.vertical)
        }
        .sheet(item: $selectedAlbum) { album in
            AlbumDetailView(album: album, viewModel: viewModel)
        }
        .sheet(isPresented: $showCreateAlbum) {
            CreateAlbumView(viewModel: viewModel)
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            Text(value)
                .font(.title3)
                .bold()
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}

struct AlbumCard: View {
    let album: PhotoAlbum
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                // Cover photo
                RoundedRectangle(cornerRadius: 8)
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "#2BB3B3").opacity(0.3), Color(hex: "#FFC7B2").opacity(0.3)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(height: 120)
                    .overlay(
                        Image(systemName: "photo.stack")
                            .font(.largeTitle)
                            .foregroundColor(Color(hex: "#2BB3B3"))
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(album.name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    Text("\(album.photoCount) photos")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 8)
                .padding(.bottom, 8)
            }
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }
}

// MARK: - Daily Challenge View

struct DailyChallengeView: View {
    @ObservedObject var viewModel: FamilyPhotoViewModel
    @State private var showSubmitPhoto = false
    
    var todayChallenge: DailyChallenge? {
        viewModel.todayChallenge
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Today's challenge
                if let challenge = todayChallenge {
                    VStack(spacing: 16) {
                        // Challenge header
                        VStack(spacing: 12) {
                            Image(systemName: challenge.icon)
                                .font(.system(size: 50))
                                .foregroundColor(Color(hex: "#2BB3B3"))
                            
                            Text("Today's Challenge")
                                .font(.title2)
                                .bold()
                            
                            Text(challenge.prompt)
                                .font(.title3)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                            
                            HStack {
                                Image(systemName: "star.fill")
                                    .foregroundColor(.orange)
                                Text("\(challenge.points) points")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(
                            LinearGradient(
                                colors: [Color(hex: "#2BB3B3").opacity(0.1), Color(hex: "#2BB3B3").opacity(0.05)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .cornerRadius(16)
                        .padding(.horizontal)
                        
                        // Submit button or view submissions
                        if challenge.isCompleted {
                            VStack(spacing: 12) {
                                Label("Challenge Completed!", systemImage: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                    .font(.headline)
                                
                                Text("\(challenge.submissions.count) family members participated")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        } else {
                            Button(action: { showSubmitPhoto = true }) {
                                Label("Submit Photo", systemImage: "camera.fill")
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color(hex: "#2BB3B3"))
                                    .foregroundColor(.white)
                                    .cornerRadius(12)
                            }
                            .padding(.horizontal)
                        }
                        
                        // Family submissions
                        if !challenge.submissions.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Family Submissions")
                                    .font(.headline)
                                    .padding(.horizontal)
                                
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 12) {
                                        ForEach(challenge.submissions, id: \.self) { photoId in
                                            if let photo = viewModel.photo(by: photoId) {
                                                ChallengeSubmissionCard(photo: photo)
                                            }
                                        }
                                    }
                                    .padding(.horizontal)
                                }
                            }
                        }
                    }
                }
                
                // Challenge history
                VStack(alignment: .leading, spacing: 16) {
                    Text("Past Challenges")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    ForEach(viewModel.pastChallenges) { challenge in
                        PastChallengeRow(challenge: challenge, viewModel: viewModel)
                    }
                }
                .padding(.top)
            }
            .padding(.vertical)
        }
        .sheet(isPresented: $showSubmitPhoto) {
            PhotoCaptureView(viewModel: viewModel, challengeId: todayChallenge?.id)
        }
    }
}

struct ChallengeSubmissionCard: View {
    let photo: FamilyPhoto
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            RoundedRectangle(cornerRadius: 12)
                .fill(
                    LinearGradient(
                        colors: [Color.blue.opacity(0.3), Color.purple.opacity(0.3)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 120, height: 120)
                .overlay(
                    Image(systemName: "photo")
                        .font(.title)
                        .foregroundColor(.white)
                )
            
            HStack {
                if let member = FamilyMember.mock.first(where: { $0.id == photo.uploadedBy }) {
                    Circle()
                        .fill(member.color)
                        .frame(width: 24, height: 24)
                        .overlay(
                            Text(member.initial)
                                .font(.caption2)
                                .foregroundColor(.white)
                        )
                    Text(member.name)
                        .font(.caption)
                        .lineLimit(1)
                }
            }
        }
    }
}

struct PastChallengeRow: View {
    let challenge: DailyChallenge
    @ObservedObject var viewModel: FamilyPhotoViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: challenge.icon)
                    .foregroundColor(Color(hex: "#2BB3B3"))
                VStack(alignment: .leading, spacing: 4) {
                    Text(challenge.prompt)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Text(challenge.date.formatted(.dateTime.weekday(.wide).month().day()))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                
                if challenge.isCompleted {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("\(challenge.submissions.count)")
                            .font(.caption)
                    }
                }
            }
            
            // Photo previews
            if !challenge.submissions.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(challenge.submissions.prefix(5), id: \.self) { photoId in
                            if let photo = viewModel.photo(by: photoId) {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(width: 60, height: 60)
                                    .overlay(
                                        Image(systemName: "photo")
                                            .foregroundColor(.gray)
                                    )
                            }
                        }
                        
                        if challenge.submissions.count > 5 {
                            Text("+\(challenge.submissions.count - 5)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .frame(width: 60, height: 60)
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

// MARK: - Mood Photos View

struct MoodPhotosView: View {
    @ObservedObject var viewModel: FamilyPhotoViewModel
    @State private var selectedMember: String? = nil
    @State private var showAddMoodPhoto = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Add mood photo button
                Button(action: { showAddMoodPhoto = true }) {
                    HStack {
                        Image(systemName: "face.smiling")
                            .font(.title2)
                        VStack(alignment: .leading) {
                            Text("Share Your Mood")
                                .font(.headline)
                            Text("Express how you're feeling with a photo")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Image(systemName: "camera.fill")
                    }
                    .padding()
                    .background(
                        LinearGradient(
                            colors: [Color(hex: "#FFC7B2").opacity(0.2), Color(hex: "#FFC7B2").opacity(0.1)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(12)
                }
                .padding(.horizontal)
                
                // Member filter
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        FilterChip(
                            title: "All",
                            isSelected: selectedMember == nil,
                            color: .gray,
                            action: { selectedMember = nil }
                        )
                        
                        ForEach(FamilyMember.mock, id: \.id) { member in
                            FilterChip(
                                title: member.name,
                                isSelected: selectedMember == member.id,
                                color: member.color,
                                action: { selectedMember = member.id }
                            )
                        }
                    }
                    .padding(.horizontal)
                }
                
                // Mood timeline
                VStack(alignment: .leading, spacing: 16) {
                    Text("Mood Journey")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    ForEach(viewModel.moodPhotosByDate(member: selectedMember), id: \.key) { dateGroup in
                        VStack(alignment: .leading, spacing: 12) {
                            Text(dateGroup.key.formatted(.dateTime.weekday(.wide).month().day()))
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.horizontal)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(dateGroup.value) { photo in
                                        MoodPhotoCard(photo: photo, viewModel: viewModel)
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                    }
                }
                
                // Mood insights
                if selectedMember == nil {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Family Mood Insights")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        MoodInsightsCard()
                            .padding(.horizontal)
                    }
                }
            }
            .padding(.vertical)
        }
        .sheet(isPresented: $showAddMoodPhoto) {
            AddMoodPhotoView(viewModel: viewModel)
        }
    }
}

struct MoodPhotoCard: View {
    let photo: FamilyPhoto
    @ObservedObject var viewModel: FamilyPhotoViewModel
    @State private var showDetail = false
    
    var body: some View {
        Button(action: { showDetail = true }) {
            VStack(alignment: .leading, spacing: 8) {
                ZStack(alignment: .bottomLeading) {
                    RoundedRectangle(cornerRadius: 0)
                        .fill(
                            LinearGradient(
                                colors: [Color.purple.opacity(0.3), Color.pink.opacity(0.3)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 150, height: 200)
                        .overlay(
                            Image(systemName: "photo")
                                .font(.largeTitle)
                                .foregroundColor(.white)
                        )
                    
                    // Mood overlay
                    if let moodInfo = photo.moodInfo {
                        LinearGradient(
                            colors: [moodInfo.moodColor.opacity(0.8), moodInfo.moodColor.opacity(0.3)],
                            startPoint: .bottom,
                            endPoint: .top
                        )
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(moodInfo.moodEmoji)
                                .font(.title)
                            Text(moodInfo.moodDescription)
                                .font(.caption)
                                .foregroundColor(.white)
                                .lineLimit(2)
                        }
                        .padding(8)
                    }
                }
                .cornerRadius(12)
                
                // Uploader info
                HStack {
                    if let member = FamilyMember.mock.first(where: { $0.id == photo.uploadedBy }) {
                        Circle()
                            .fill(member.color)
                            .frame(width: 20, height: 20)
                            .overlay(
                                Text(member.initial)
                                    .font(.system(size: 10))
                                    .foregroundColor(.white)
                            )
                        Text(member.name)
                            .font(.caption)
                    }
                    Spacer()
                    Text(photo.uploadedAt.formatted(.relative(presentation: .named)))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .frame(width: 150)
        }
        .sheet(isPresented: $showDetail) {
            PhotoDetailView(photoId: photo.id, viewModel: viewModel)
        }
    }
}

struct MoodInsightsCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .foregroundColor(.green)
                Text("Mood Trend")
                    .font(.subheadline)
                    .fontWeight(.medium)
                Spacer()
                Text("↑ 15%")
                    .font(.caption)
                    .foregroundColor(.green)
            }
            
            Text("Your family's mood has been improving this week! Keep sharing and supporting each other.")
                .font(.caption)
                .foregroundColor(.secondary)
            
            HStack(spacing: 16) {
                HStack {
                    Text("😊")
                    Text("45%")
                        .font(.caption)
                        .bold()
                }
                HStack {
                    Text("😌")
                    Text("30%")
                        .font(.caption)
                        .bold()
                }
                HStack {
                    Text("😔")
                    Text("15%")
                        .font(.caption)
                        .bold()
                }
                HStack {
                    Text("😡")
                    Text("10%")
                        .font(.caption)
                        .bold()
                }
            }
            .font(.caption)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Photo Grid

struct PhotoGrid: View {
    let photos: [FamilyPhoto]
    @ObservedObject var viewModel: FamilyPhotoViewModel
    let columns = [GridItem(.flexible(), spacing: 2), GridItem(.flexible(), spacing: 2), GridItem(.flexible(), spacing: 2)]
    @State private var selectedPhoto: FamilyPhoto?
    
    var body: some View {
        LazyVGrid(columns: columns, spacing: 2) {
            ForEach(photos) { photo in
                Button(action: { 
                    print("Photo grid: Selected photo \(photo.id)")
                    selectedPhoto = photo 
                }) {
                    ZStack(alignment: .topTrailing) {
                        RoundedRectangle(cornerRadius: 0)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        [Color.blue.opacity(0.3), Color.green.opacity(0.3)],
                                        [Color.purple.opacity(0.3), Color.pink.opacity(0.3)],
                                        [Color.orange.opacity(0.3), Color.red.opacity(0.3)]
                                    ].randomElement()!,
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(height: 120)
                            .overlay(
                                Image(systemName: "photo")
                                    .font(.title)
                                    .foregroundColor(.white)
                            )
                        
                        if photo.isFavorite {
                            Image(systemName: "heart.fill")
                                .font(.caption)
                                .foregroundColor(.white)
                                .padding(4)
                                .background(Color.black.opacity(0.5))
                                .clipShape(Circle())
                                .padding(4)
                        }
                    }
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.horizontal, 2)
        .sheet(item: $selectedPhoto) { photo in
            PhotoDetailView(photoId: photo.id, viewModel: viewModel)
        }
    }
}

// MARK: - View Model

class FamilyPhotoViewModel: ObservableObject {
    @Published var allPhotos: [FamilyPhoto] = []
    @Published var albums: [PhotoAlbum] = []
    @Published var currentStreak = 3
    @Published var todayChallenge: DailyChallenge?
    @Published var pastChallenges: [DailyChallenge] = []
    @Published var selectedPhotoForDetail: FamilyPhoto?
    
    var recentPhotos: [FamilyPhoto] {
        allPhotos.sorted { $0.uploadedAt > $1.uploadedAt }.prefix(30).map { $0 }
    }
    
    var favoritePhotos: [FamilyPhoto] {
        allPhotos.filter { $0.isFavorite }
    }
    
    var photosThisMonth: Int {
        let calendar = Calendar.current
        let currentMonth = calendar.component(.month, from: Date())
        return allPhotos.filter { calendar.component(.month, from: $0.uploadedAt) == currentMonth }.count
    }
    
    init() {
        loadMockData()
    }
    
    func loadMockData() {
        // Mock albums
        albums = [
            PhotoAlbum(id: "1", name: "All Photos", coverPhotoName: "photo", photoCount: 156, createdBy: "system", createdAt: Date(), isDefault: true),
            PhotoAlbum(id: "2", name: "Summer Vacation", coverPhotoName: "sun.max", photoCount: 48, createdBy: "mom", createdAt: Date().addingTimeInterval(-2592000), isDefault: false),
            PhotoAlbum(id: "3", name: "Birthday Parties", coverPhotoName: "gift", photoCount: 32, createdBy: "dad", createdAt: Date().addingTimeInterval(-5184000), isDefault: false),
            PhotoAlbum(id: "4", name: "Holiday Moments", coverPhotoName: "snowflake", photoCount: 24, createdBy: "teen", createdAt: Date().addingTimeInterval(-7776000), isDefault: false),
            PhotoAlbum(id: "5", name: "School Events", coverPhotoName: "graduationcap", photoCount: 18, createdBy: "mom", createdAt: Date().addingTimeInterval(-3888000), isDefault: false),
            PhotoAlbum(id: "6", name: "Weekend Fun", coverPhotoName: "gamecontroller", photoCount: 42, createdBy: "kid", createdAt: Date().addingTimeInterval(-1296000), isDefault: false)
        ]
        
        // Mock photos - using SF Symbols for demo
        let mockPhotos = [
            FamilyPhoto(id: "1", imageName: "photo", thumbnailName: "photo", uploadedBy: "mom", uploadedAt: Date().addingTimeInterval(-3600), albumId: "2", challengeId: nil, moodInfo: nil, location: "Santa Monica Beach", caption: "Beach day with the family!", isFavorite: true),
            FamilyPhoto(id: "2", imageName: "photo", thumbnailName: "photo", uploadedBy: "dad", uploadedAt: Date().addingTimeInterval(-7200), albumId: "1", challengeId: nil, moodInfo: nil, location: nil, caption: "Dinner time!", isFavorite: false),
            FamilyPhoto(id: "3", imageName: "photo", thumbnailName: "photo", uploadedBy: "teen", uploadedAt: Date().addingTimeInterval(-86400), albumId: nil, challengeId: "1", moodInfo: nil, location: nil, caption: "Today's breakfast challenge"),
            FamilyPhoto(id: "4", imageName: "photo", thumbnailName: "photo", uploadedBy: "kid", uploadedAt: Date().addingTimeInterval(-172800), albumId: nil, challengeId: nil, moodInfo: MoodPhotoInfo(moodColor: .blue, moodEmoji: "😊", moodDescription: "Feeling happy today!"), location: nil, caption: nil),
            FamilyPhoto(id: "5", imageName: "photo", thumbnailName: "photo", uploadedBy: "mom", uploadedAt: Date().addingTimeInterval(-259200), albumId: "3", challengeId: nil, moodInfo: nil, location: nil, caption: "Alex's birthday party!", isFavorite: true),
            FamilyPhoto(id: "6", imageName: "photo", thumbnailName: "photo", uploadedBy: "teen", uploadedAt: Date().addingTimeInterval(-345600), albumId: nil, challengeId: nil, moodInfo: MoodPhotoInfo(moodColor: .green, moodEmoji: "😌", moodDescription: "Peaceful evening"), location: nil, caption: nil),
            FamilyPhoto(id: "7", imageName: "photo", thumbnailName: "photo", uploadedBy: "dad", uploadedAt: Date().addingTimeInterval(-432000), albumId: "6", challengeId: nil, moodInfo: nil, location: nil, caption: "Game night winners!", isFavorite: false),
            FamilyPhoto(id: "8", imageName: "photo", thumbnailName: "photo", uploadedBy: "kid", uploadedAt: Date().addingTimeInterval(-518400), albumId: nil, challengeId: "2", moodInfo: nil, location: nil, caption: "My pet turtle"),
            FamilyPhoto(id: "9", imageName: "photo", thumbnailName: "photo", uploadedBy: "mom", uploadedAt: Date().addingTimeInterval(-604800), albumId: "4", challengeId: nil, moodInfo: nil, location: "Home", caption: "Holiday decorations"),
            FamilyPhoto(id: "10", imageName: "photo", thumbnailName: "photo", uploadedBy: "teen", uploadedAt: Date().addingTimeInterval(-691200), albumId: nil, challengeId: nil, moodInfo: MoodPhotoInfo(moodColor: .orange, moodEmoji: "😎", moodDescription: "Feeling confident!"), location: nil, caption: nil)
        ]
        
        // Add reactions and comments
        allPhotos = mockPhotos.map { photo in
            var updatedPhoto = photo
            updatedPhoto.reactions = [
                PhotoReaction(userId: "mom", type: .love, timestamp: Date()),
                PhotoReaction(userId: "dad", type: .celebrate, timestamp: Date())
            ]
            updatedPhoto.comments = [
                PhotoComment(id: "1", userId: "mom", text: "Love this moment!", timestamp: Date()),
                PhotoComment(id: "2", userId: "teen", text: "Best day ever!", timestamp: Date())
            ]
            updatedPhoto.tags = ["mom", "dad", "teen", "kid"]
            return updatedPhoto
        }
        
        // Mock challenges
        todayChallenge = DailyChallenge(
            id: "today",
            date: Date(),
            prompt: "Share Your Favorite Meal Today",
            icon: "fork.knife",
            points: 10,
            submissions: ["3", "2", "1"]
        )
        
        pastChallenges = [
            DailyChallenge(id: "1", date: Date().addingTimeInterval(-86400), prompt: "Morning Sunrise", icon: "sunrise", points: 10, submissions: ["1", "2", "5", "7"]),
            DailyChallenge(id: "2", date: Date().addingTimeInterval(-172800), prompt: "Family Pet Moment", icon: "pawprint", points: 10, submissions: ["8", "4", "6"]),
            DailyChallenge(id: "3", date: Date().addingTimeInterval(-259200), prompt: "Something That Made You Smile", icon: "face.smiling", points: 10, submissions: ["1", "2", "3", "9"]),
            DailyChallenge(id: "4", date: Date().addingTimeInterval(-345600), prompt: "Your Cozy Corner", icon: "house", points: 10, submissions: ["5", "10"]),
            DailyChallenge(id: "5", date: Date().addingTimeInterval(-432000), prompt: "Nature Walk Discovery", icon: "leaf", points: 10, submissions: ["7", "8", "9", "10"])
        ]
    }
    
    func photo(by id: String) -> FamilyPhoto? {
        allPhotos.first { $0.id == id }
    }
    
    func moodPhotosByDate(member: String? = nil) -> [(key: Date, value: [FamilyPhoto])] {
        let moodPhotos = allPhotos.filter { photo in
            photo.moodInfo != nil && (member == nil || photo.uploadedBy == member)
        }
        
        let grouped = Dictionary(grouping: moodPhotos) { photo in
            Calendar.current.startOfDay(for: photo.uploadedAt)
        }
        
        return grouped.sorted { $0.key > $1.key }
    }
    
    func addPhoto(_ photo: FamilyPhoto) {
        allPhotos.insert(photo, at: 0)
    }
    
    func toggleFavorite(_ photo: FamilyPhoto) {
        print("ViewModel: Toggling favorite for photo \(photo.id)")
        if let index = allPhotos.firstIndex(where: { $0.id == photo.id }) {
            allPhotos[index].isFavorite.toggle()
            print("ViewModel: Favorite toggled. Is now: \(allPhotos[index].isFavorite)")
        }
    }
    
    func addReaction(_ reaction: PhotoReaction, to photo: FamilyPhoto) {
        print("ViewModel: Adding reaction to photo \(photo.id)")
        if let index = allPhotos.firstIndex(where: { $0.id == photo.id }) {
            // Remove existing reaction from same user
            allPhotos[index].reactions.removeAll { $0.userId == reaction.userId }
            allPhotos[index].reactions.append(reaction)
            print("ViewModel: Reaction added successfully. Total reactions: \(allPhotos[index].reactions.count)")
        } else {
            print("ViewModel: Photo not found with id: \(photo.id)")
        }
    }
    
    func addComment(_ comment: PhotoComment, to photo: FamilyPhoto) {
        print("ViewModel: Adding comment to photo \(photo.id)")
        if let index = allPhotos.firstIndex(where: { $0.id == photo.id }) {
            allPhotos[index].comments.append(comment)
            print("ViewModel: Comment added successfully. Total comments: \(allPhotos[index].comments.count)")
        } else {
            print("ViewModel: Photo not found with id: \(photo.id)")
        }
    }
}

// MARK: - Supporting Views (Placeholders)

struct PhotoCaptureView: View {
    @ObservedObject var viewModel: FamilyPhotoViewModel
    var challengeId: String? = nil
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            VStack {
                Text("Photo Capture")
                    .font(.largeTitle)
                    .padding()
                
                Text("In a real app, this would open the camera or photo library")
                    .foregroundColor(.secondary)
                    .padding()
                
                Spacer()
            }
            .navigationTitle("New Photo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

struct PhotoDetailView: View {
    let photoId: String
    @ObservedObject var viewModel: FamilyPhotoViewModel
    @Environment(\.dismiss) var dismiss
    @State private var newComment = ""
    @State private var showingReactionPicker = false
    @FocusState private var isCommentFocused: Bool
    
    var photo: FamilyPhoto? {
        viewModel.allPhotos.first { $0.id == photoId }
    }
    
    var body: some View {
        NavigationStack {
            if let photo = photo {
                ScrollView {
                    VStack(spacing: 0) {
                        // Photo
                    RoundedRectangle(cornerRadius: 0)
                        .fill(
                            LinearGradient(
                                colors: [Color.blue.opacity(0.3), Color.purple.opacity(0.3)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .aspectRatio(1.0, contentMode: .fit)
                        .overlay(
                            Image(systemName: "photo")
                                .font(.system(size: 60))
                                .foregroundColor(.white)
                        )
                    
                    VStack(alignment: .leading, spacing: 16) {
                        // Photo info
                        HStack {
                            if let member = FamilyMember.mock.first(where: { $0.id == photo.uploadedBy }) {
                                Circle()
                                    .fill(member.color)
                                    .frame(width: 40, height: 40)
                                    .overlay(
                                        Text(member.initial)
                                            .font(.subheadline)
                                            .foregroundColor(.white)
                                    )
                                
                                VStack(alignment: .leading) {
                                    Text(member.name)
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                    Text(photo.uploadedAt.formatted(.relative(presentation: .named)))
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            Spacer()
                            
                            Button(action: { 
                                print("Favorite button tapped for photo: \(photo.id)")
                                viewModel.toggleFavorite(photo) 
                            }) {
                                Image(systemName: photo.isFavorite ? "heart.fill" : "heart")
                                    .font(.title2)
                                    .foregroundColor(photo.isFavorite ? .red : .gray)
                                    .frame(width: 44, height: 44) // Add tap area
                                    .contentShape(Rectangle()) // Ensure full area is tappable
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        .padding(.horizontal)
                        .padding(.top)
                        
                        // Caption and location
                        if let caption = photo.caption {
                            Text(caption)
                                .font(.body)
                                .padding(.horizontal)
                        }
                        
                        if let location = photo.location {
                            Label(location, systemImage: "location")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.horizontal)
                        }
                        
                        // Reactions bar
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(ReactionType.allCases, id: \.self) { type in
                                    ReactionButton(
                                        type: type,
                                        count: photo.reactions.filter { $0.type == type }.count,
                                        isSelected: photo.reactions.contains { $0.userId == "currentUser" && $0.type == type },
                                        action: {
                                            withAnimation(.easeInOut(duration: 0.2)) {
                                                print("Adding reaction \(type.rawValue) to photo: \(photo.id)")
                                                let reaction = PhotoReaction(userId: "currentUser", type: type, timestamp: Date())
                                                viewModel.addReaction(reaction, to: photo)
                                            }
                                        }
                                    )
                                }
                            }
                            .padding(.horizontal)
                        }
                        .padding(.vertical, 8)
                        .contentShape(Rectangle()) // Ensure proper hit testing
                        
                        Divider()
                        
                        // Comments section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Comments (\(photo.comments.count))")
                                .font(.headline)
                                .padding(.horizontal)
                            
                            if photo.comments.isEmpty {
                                Text("Be the first to comment!")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .padding(.horizontal)
                                    .padding(.vertical, 20)
                            } else {
                                ForEach(photo.comments, id: \.id) { comment in
                                    CommentRow(comment: comment)
                                }
                            }
                            
                            // Add comment field
                            HStack(spacing: 12) {
                                if let currentUser = FamilyMember.mock.first(where: { $0.id == "teen" }) {
                                    Circle()
                                        .fill(currentUser.color)
                                        .frame(width: 36, height: 36)
                                        .overlay(
                                            Text(currentUser.initial)
                                                .font(.caption)
                                                .foregroundColor(.white)
                                        )
                                }
                                
                                HStack {
                                    TextField("Add a comment...", text: $newComment, axis: .vertical)
                                        .textFieldStyle(.plain)
                                        .lineLimit(1...4)
                                        .focused($isCommentFocused)
                                        .onSubmit {
                                            postComment()
                                        }
                                    
                                    if !newComment.isEmpty {
                                        Button(action: postComment) {
                                            Image(systemName: "paperplane.fill")
                                                .foregroundColor(Color(hex: "#2BB3B3"))
                                                .frame(width: 30, height: 30)
                                                .contentShape(Rectangle())
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                    }
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(Color(.systemGray6))
                                .cornerRadius(20)
                            }
                            .padding(.horizontal)
                            .padding(.bottom)
                        }
                    }
                }
            }
            } else {
                Text("Photo not found")
                    .foregroundColor(.secondary)
                    .padding()
            }
        }
        .navigationTitle("Photo Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Done") { dismiss() }
            }
        }
        .interactiveDismissDisabled(false)
    }
    
    func postComment() {
        guard !newComment.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              let photo = photo else { 
            print("Cannot post comment: empty text or photo not found")
            return 
        }
        
        print("Posting comment for photo: \(photo.id)")
        
        let comment = PhotoComment(
            id: UUID().uuidString,
            userId: "teen", // Current user
            text: newComment,
            timestamp: Date()
        )
        
        viewModel.addComment(comment, to: photo)
        newComment = ""
        isCommentFocused = false
    }
}

struct ReactionButton: View {
    let type: ReactionType
    let count: Int
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Text(type.rawValue)
                    .font(.title3)
                if count > 0 {
                    Text("\(count)")
                        .font(.caption)
                        .fontWeight(.medium)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(isSelected ? Color(hex: "#2BB3B3").opacity(0.2) : Color(.systemGray6))
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(isSelected ? Color(hex: "#2BB3B3") : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct CommentRow: View {
    let comment: PhotoComment
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            if let member = FamilyMember.mock.first(where: { $0.id == comment.userId }) {
                Circle()
                    .fill(member.color)
                    .frame(width: 36, height: 36)
                    .overlay(
                        Text(member.initial)
                            .font(.caption)
                            .foregroundColor(.white)
                    )
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(FamilyMember.mock.first(where: { $0.id == comment.userId })?.name ?? "")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Text("•")
                        .foregroundColor(.secondary)
                    
                    Text(comment.timestamp.formatted(.relative(presentation: .named)))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Text(comment.text)
                    .font(.body)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
}

struct AlbumDetailView: View {
    let album: PhotoAlbum
    @ObservedObject var viewModel: FamilyPhotoViewModel
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                PhotoGrid(photos: viewModel.allPhotos.filter { $0.albumId == album.id }, viewModel: viewModel)
            }
            .navigationTitle(album.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

struct CreateAlbumView: View {
    @ObservedObject var viewModel: FamilyPhotoViewModel
    @Environment(\.dismiss) var dismiss
    @State private var albumName = ""
    
    var body: some View {
        NavigationStack {
            Form {
                TextField("Album Name", text: $albumName)
            }
            .navigationTitle("New Album")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create") {
                        // Create album logic
                        dismiss()
                    }
                    .disabled(albumName.isEmpty)
                }
            }
        }
    }
}

struct AddMoodPhotoView: View {
    @ObservedObject var viewModel: FamilyPhotoViewModel
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            VStack {
                Text("Add Mood Photo")
                    .font(.largeTitle)
                    .padding()
                
                Text("Select a photo and describe your mood")
                    .foregroundColor(.secondary)
                    .padding()
                
                Spacer()
            }
            .navigationTitle("Mood Photo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        FamilyPhotoView()
    }
}