import Foundation
import Observation

struct RideBreakdownEntry: Identifiable {
    let id = UUID()
    let name: String
    let count: Int
}

struct PersonalRecord: Identifiable {
    let id = UUID()
    let label: String
    let value: String
    let rideName: String
    let icon: String
}

enum JournalSortOption: String, CaseIterable {
    case dateNewest = "Newest"
    case dateOldest = "Oldest"
    case rideName = "Name"
    case parkName = "Park"
}

@Observable
@MainActor
final class RideJournalViewModel {
    var allCheckIns: [ProfileRide] = []
    var searchText = ""
    var sortOption: JournalSortOption = .dateNewest
    var isLoading = false
    var errorMessage: String?

    private let profileService = ProfileService()

    // MARK: - Filtered & Sorted

    var filteredCheckIns: [ProfileRide] {
        var results = allCheckIns

        if !searchText.trimmingCharacters(in: .whitespaces).isEmpty {
            let query = searchText.lowercased()
            results = results.filter {
                ($0.ride?.name.lowercased().contains(query) ?? false) ||
                ($0.ride?.park?.name?.lowercased().contains(query) ?? false) ||
                ($0.ride?.manufacturer?.lowercased().contains(query) ?? false)
            }
        }

        switch sortOption {
        case .dateNewest:
            results.sort { ($0.createdDate ?? .distantPast) > ($1.createdDate ?? .distantPast) }
        case .dateOldest:
            results.sort { ($0.createdDate ?? .distantPast) < ($1.createdDate ?? .distantPast) }
        case .rideName:
            results.sort { ($0.ride?.name ?? "") < ($1.ride?.name ?? "") }
        case .parkName:
            results.sort { ($0.ride?.park?.name ?? "") < ($1.ride?.park?.name ?? "") }
        }

        return results
    }

    // MARK: - Header Stats

    var totalRides: Int { allCheckIns.count }

    var uniqueCoasters: Int {
        Set(allCheckIns.compactMap { $0.rideId }).count
    }

    var uniqueParks: Int {
        Set(allCheckIns.compactMap { $0.ride?.parkId }).count
    }

    // MARK: - Breakdowns

    var byManufacturer: [RideBreakdownEntry] {
        var counts: [String: Int] = [:]
        for checkIn in allCheckIns {
            let manufacturer = checkIn.ride?.manufacturer ?? "Unknown"
            if !manufacturer.isEmpty && manufacturer != "null" {
                counts[manufacturer, default: 0] += 1
            }
        }
        return counts.map { RideBreakdownEntry(name: $0.key, count: $0.value) }
            .sorted { $0.count > $1.count }
    }

    var byPark: [RideBreakdownEntry] {
        var counts: [String: Int] = [:]
        for checkIn in allCheckIns {
            let park = checkIn.ride?.park?.name ?? "Unknown Park"
            counts[park, default: 0] += 1
        }
        return counts.map { RideBreakdownEntry(name: $0.key, count: $0.value) }
            .sorted { $0.count > $1.count }
    }

    var byYear: [RideBreakdownEntry] {
        let calendar = Calendar.current
        var counts: [Int: Int] = [:]
        for checkIn in allCheckIns {
            if let date = checkIn.createdDate {
                let year = calendar.component(.year, from: date)
                counts[year, default: 0] += 1
            }
        }
        return counts.map { RideBreakdownEntry(name: String($0.key), count: $0.value) }
            .sorted { $0.name > $1.name }
    }

    // MARK: - Personal Records

    var personalRecords: [PersonalRecord] {
        var records: [PersonalRecord] = []

        // Fastest ridden
        if let fastest = allCheckIns.compactMap({ ci -> (String, Int16)? in
            guard let speed = ci.ride?.speed else { return nil }
            return (ci.ride?.name ?? "Unknown", speed)
        }).max(by: { $0.1 < $1.1 }) {
            records.append(PersonalRecord(label: "FASTEST RIDDEN", value: "\(fastest.1) MPH", rideName: fastest.0, icon: "gauge.with.needle"))
        }

        // Tallest ridden
        if let tallest = allCheckIns.compactMap({ ci -> (String, Int16)? in
            guard let height = ci.ride?.height else { return nil }
            return (ci.ride?.name ?? "Unknown", height)
        }).max(by: { $0.1 < $1.1 }) {
            records.append(PersonalRecord(label: "TALLEST RIDDEN", value: "\(tallest.1) FT", rideName: tallest.0, icon: "arrow.up"))
        }

        // Highest G-Force
        if let maxG = allCheckIns.compactMap({ ci -> (String, Float)? in
            guard let g = ci.ride?.gForce else { return nil }
            return (ci.ride?.name ?? "Unknown", g)
        }).max(by: { $0.1 < $1.1 }) {
            records.append(PersonalRecord(label: "MAX G-FORCE", value: String(format: "%.1f G", maxG.1), rideName: maxG.0, icon: "scalemass"))
        }

        // Most inversions
        if let maxInv = allCheckIns.compactMap({ ci -> (String, Int16)? in
            guard let inv = ci.ride?.inversions, inv > 0 else { return nil }
            return (ci.ride?.name ?? "Unknown", inv)
        }).max(by: { $0.1 < $1.1 }) {
            records.append(PersonalRecord(label: "MOST INVERSIONS", value: "\(maxInv.1)", rideName: maxInv.0, icon: "arrow.triangle.2.circlepath"))
        }

        return records
    }

    // MARK: - Load

    func loadJournal(profileId: Int64) async {
        isLoading = true
        errorMessage = nil
        do {
            allCheckIns = try await profileService.fetchAllCheckIns(profileId: profileId)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}
