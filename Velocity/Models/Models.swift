import Foundation

// MARK: - Profile
struct Profile: Codable, Identifiable, Sendable {
    let id: Int64
    let createdDate: Date?
    let userId: String?
    let firstName: String?
    let lastName: String?
    let publicUserName: String?
    let dob: Date?
    let email: String?
    let subscriptionTypeId: Int64?
    let avatarName: String?
    let friends: [Int64]?

    var displayName: String {
        if let pub = publicUserName, !pub.isEmpty { return pub }
        return [firstName, lastName].compactMap { $0 }.joined(separator: " ")
    }
}

// MARK: - Subscription Type
struct SubscriptionType: Codable, Identifiable, Sendable {
    let id: Int64
    let createdDate: Date?
    let subscriptionName: String?
}

// MARK: - Park
struct Park: Codable, Identifiable, Sendable {
    let id: Int64
    let createdDate: Date?
    let name: String?
    let description: String?
    let streetAddress: String?
    let city: String?
    let state: String?
    let zip: String?
    let country: String?
    let longitude: String?
    let latitude: String?
    let phoneNumber: String?
    let website: String?
    let email: String?
    let mainImageURL: String?
    let isProduction: Bool?
    let sundayHours: String?
    let mondayHours: String?
    let tuesdayHours: String?
    let wednesdayHours: String?
    let thursdayHours: String?
    let fridayHours: String?
    let saturdayHours: String?

    var displayName: String { name ?? "Unknown Park" }

    var locationString: String {
        [city, state, country].compactMap { $0?.isEmpty == true ? nil : $0 }.joined(separator: ", ")
    }
}

// MARK: - Ride (Coaster)
struct Ride: Codable, Identifiable, Sendable {
    let id: Int64
    let createdDate: Date?
    let name: String
    let description: String?
    let manufacturer: String?
    let gForce: Float?
    let trackLength: Int16?
    let height: Int16?
    let speed: Int16?
    let inversions: Int16?
    let mainImageURL: String?
    let parkId: Int64?
    let numberOfReviews: Int16?
    let numberOfStars: Int16?

    // Joined park data (populated via select query with park!inner)
    let park: Park?

    var starRating: Double {
        guard let reviews = numberOfReviews, reviews > 0, let stars = numberOfStars else { return 0 }
        return Double(stars) / Double(reviews)
    }
}

// MARK: - Profile Ride (Check-In)
struct ProfileRide: Codable, Identifiable, Sendable {
    let id: Int64
    let createdDate: Date?
    let profileId: Int64
    let rideId: Int64
    let comments: String?
    let score: Int16?
    let waitTime: Int16?
    let seatRow: String?

    // Joined data
    let ride: Ride?
    let profile: Profile?
}

// MARK: - Profile Ride Images
struct ProfileRideImage: Codable, Identifiable, Sendable {
    let id: Int64
    let createdDate: Date?
    let profileRideId: Int64?
    let imageURL: String?
    let makePublic: Bool?
}

// MARK: - Profile Ride Note
struct ProfileRideNote: Codable, Identifiable, Sendable {
    let id: Int64
    let createdDate: Date?
    let updatedDate: Date?
    let profileId: Int64
    let rideId: Int64
    let note: String?
}

// MARK: - Profile Ride Review
struct ProfileRideReview: Codable, Identifiable, Sendable {
    let id: Int64
    let createdDate: Date?
    let profileId: Int64
    let rideId: Int64
    let reviewText: String
    let upVotes: Int16?
    let downVotes: Int16?
    let stars: Int16?

    // Joined profile
    let profile: Profile?
}

// MARK: - Profile Ride Review Rating (Vote)
struct ProfileRideReviewRating: Codable, Identifiable, Sendable {
    let id: Int64
    let createdDate: Date?
    let profileId: Int64
    let profileRideReviewId: Int64
    let approve: Bool
}

// MARK: - Message
struct Message: Codable, Identifiable, Sendable {
    let id: Int64
    let createdDate: Date?
    let messageTitle: String
    let messageText: String
    let thumbnailURL: String?
}

// MARK: - Profile Message
struct ProfileMessage: Codable, Identifiable, Sendable {
    let id: Int64
    let createdDate: Date?
    let profileId: Int64
    let messageId: Int64
    let isRead: Bool?
    let isArchived: Bool?
    let dateRead: Date?

    let message: Message?
}

// MARK: - Achievement
struct Achievement: Codable, Identifiable, Sendable {
    let id: Int64
    let createdDate: Date?
    let name: String
    let description: String?
    let iconName: String
    let criteriaType: String
    let criteriaValue: Int
}

// MARK: - Profile Achievement
struct ProfileAchievement: Codable, Identifiable, Sendable {
    let id: Int64
    let createdDate: Date?
    let profileId: Int64
    let achievementId: Int64
    let earnedDate: Date?

    let achievement: Achievement?
}

// MARK: - Park Request (suggest a new park)
struct ParkRequest: Codable, Identifiable, Sendable {
    let id: Int64
    let createdDate: Date?
    let profileId: Int64
    let name: String
    let city: String
    let state: String
    let zip: String?
    let latitude: String?
    let longitude: String?
    let website: String?
    let streetAddress: String?
    let phoneNumber: String?
    let email: String?
    let country: String?
    let sundayHours: String?
    let mondayHours: String?
    let tuesdayHours: String?
    let wednesdayHours: String?
    let thursdayHours: String?
    let fridayHours: String?
    let saturdayHours: String?
}

// MARK: - Ride Request (suggest a new coaster at an existing park)
struct RideRequest: Codable, Identifiable, Sendable {
    let id: Int64
    let createdDate: Date?
    let profileId: Int64
    let parkId: Int64
    let name: String
    let description: String?
    let manufacturer: String?
    let gForce: Float?
    let trackLength: Int16?
    let height: Int16?
    let speed: Int16?
    let inversions: Int16?
    let mainImageURL: String?
}

// MARK: - Ride Update Request
struct RideUpdateRequest: Codable, Identifiable, Sendable {
    let id: Int64
    let createdDate: Date?
    let profileId: Int64?
    let originalRideId: Int64
    let name: String?
    let description: String?
    let streetAddress: String?
    let city: String?
    let state: String?
    let zip: String?
    let country: String?
    let longitude: String?
    let latitude: String?
    let phoneNumber: String?
    let website: String?
    let email: String?
    let mainImageURL: String?
    let sundayHours: String?
    let mondayHours: String?
    let tuesdayHours: String?
    let wednesdayHours: String?
    let thursdayHours: String?
    let fridayHours: String?
    let saturdayHours: String?
}

// MARK: - Leaderboard Entry (computed)
struct LeaderboardEntry: Identifiable, Sendable {
    let id: Int64
    let profile: Profile
    let rideCount: Int
    let rank: Int
    let lastCheckIn: ProfileRide?
}

// MARK: - Profile Stats (computed)
struct ProfileStats: Sendable {
    let coasterCount: Int
    let maxGForce: Float
    let parksVisited: Int
    let globalRank: Int
}

// MARK: - Park Bucket List
struct ParkBucketList: Codable, Identifiable, Sendable {
    let id: Int64
    let createdDate: Date?
    let profileId: Int64
    let parkId: Int64
}

// MARK: - Park Visit Plan (ELITE)
struct ParkVisitPlan: Codable, Identifiable, Sendable {
    let id: Int64
    let createdDate: Date?
    let profileId: Int64
    let parkId: Int64
    let rideIds: [Int64]
    let plannedDate: Date?
    let name: String?
}

// MARK: - Map Park Pin (computed for profile map)
struct MapParkPin: Identifiable {
    let id: Int64
    let park: Park
    let rideCount: Int
    let latitude: Double
    let longitude: Double
    let isBucketList: Bool
}
