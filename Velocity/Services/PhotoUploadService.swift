import Foundation
import UIKit
import Supabase

@MainActor
final class PhotoUploadService {
    private let client = SupabaseManager.shared.client
    private let bucketName = "ride-photos"

    /// Upload a photo for a check-in and create the profileRideImage row
    func uploadCheckInPhoto(profileRideId: Int64, profileId: Int64, image: UIImage) async throws -> String {
        // Compress image
        guard let imageData = image.jpegData(compressionQuality: 0.7) else {
            throw PhotoUploadError.compressionFailed
        }

        // Build storage path: ride-photos/{profileId}/{profileRideId}/{timestamp}.jpg
        let fileName = "\(Int(Date().timeIntervalSince1970)).jpg"
        let path = "\(profileId)/\(profileRideId)/\(fileName)"

        // Upload to Supabase Storage
        try await client.storage
            .from(bucketName)
            .upload(
                path,
                data: imageData,
                options: FileOptions(contentType: "image/jpeg")
            )

        // Get public URL
        let publicURL = try client.storage
            .from(bucketName)
            .getPublicURL(path: path)
            .absoluteString

        // Insert profileRideImage row
        struct NewImage: Encodable {
            let profileRideId: Int64
            let imageURL: String
            let makePublic: Bool
        }

        try await client
            .from("profileRideImage")
            .insert(NewImage(profileRideId: profileRideId, imageURL: publicURL, makePublic: true))
            .execute()

        return publicURL
    }

    /// Fetch images for a specific check-in
    func fetchImages(profileRideId: Int64) async throws -> [ProfileRideImage] {
        try await client
            .from("profileRideImage")
            .select()
            .eq("profileRideId", value: String(profileRideId))
            .execute()
            .value
    }
}

enum PhotoUploadError: LocalizedError {
    case compressionFailed
    var errorDescription: String? { "Failed to compress image" }
}
