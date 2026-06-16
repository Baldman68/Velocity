import Foundation
import Observation
import Supabase

struct DayOfWeekWait: Identifiable {
    let id = UUID()
    let dayIndex: Int
    let dayAbbrev: String
    let avgWait: Int
    let reportCount: Int
}

struct MonthlyWait: Identifiable {
    let id = UUID()
    let month: Int
    let monthName: String
    let avgWait: Int
    let reportCount: Int
}

struct WaitTimeEntry: Sendable {
    let waitTime: Int16
    let createdDate: Date
}

@Observable
@MainActor
final class WaitTimeInsightsViewModel {
    var waitTimeEntries: [WaitTimeEntry] = []
    var isLoading = false
    var errorMessage: String?

    private let client = SupabaseManager.shared.client

    // MARK: - Computed

    var totalReports: Int { waitTimeEntries.count }

    var overallAverage: String {
        guard !waitTimeEntries.isEmpty else { return "—" }
        let avg = Double(waitTimeEntries.map { Int($0.waitTime) }.reduce(0, +)) / Double(waitTimeEntries.count)
        return "\(Int(avg.rounded()))"
    }

    var dayOfWeekData: [DayOfWeekWait] {
        let calendar = Calendar.current
        let dayNames = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
        var grouped: [Int: [Int]] = [:]

        for entry in waitTimeEntries {
            let weekday = calendar.component(.weekday, from: entry.createdDate) // 1=Sun ... 7=Sat
            grouped[weekday, default: []].append(Int(entry.waitTime))
        }

        return (1...7).map { day in
            let waits = grouped[day] ?? []
            let avg = waits.isEmpty ? 0 : waits.reduce(0, +) / waits.count
            return DayOfWeekWait(dayIndex: day, dayAbbrev: dayNames[day - 1], avgWait: avg, reportCount: waits.count)
        }
    }

    var monthlyData: [MonthlyWait] {
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        var grouped: [Int: [Int]] = [:]

        for entry in waitTimeEntries {
            let month = calendar.component(.month, from: entry.createdDate)
            grouped[month, default: []].append(Int(entry.waitTime))
        }

        return grouped.keys.sorted().map { month in
            let waits = grouped[month]!
            let avg = waits.reduce(0, +) / waits.count
            let date = calendar.date(from: DateComponents(month: month))!
            return MonthlyWait(month: month, monthName: formatter.string(from: date), avgWait: avg, reportCount: waits.count)
        }
    }

    var peakDay: String {
        dayOfWeekData.max(by: { $0.avgWait < $1.avgWait })?.dayAbbrev ?? "—"
    }

    var bestDay: String {
        let withData = dayOfWeekData.filter { $0.reportCount > 0 }
        return withData.min(by: { $0.avgWait < $1.avgWait })?.dayAbbrev ?? "—"
    }

    var peakInsight: String? {
        guard let peak = dayOfWeekData.filter({ $0.reportCount > 0 }).max(by: { $0.avgWait < $1.avgWait }),
              peak.avgWait > 0 else { return nil }
        return "Longest average wait is \(peak.avgWait) minutes on \(peak.dayAbbrev)s."
    }

    var bestInsight: String? {
        guard let best = dayOfWeekData.filter({ $0.reportCount > 0 }).min(by: { $0.avgWait < $1.avgWait }),
              best.avgWait > 0 else { return nil }
        return "Shortest average wait is \(best.avgWait) minutes on \(best.dayAbbrev)s."
    }

    // MARK: - Load

    func loadInsights(rideId: Int64) async {
        isLoading = true
        errorMessage = nil
        do {
            struct WaitRow: Decodable {
                let waitTime: Int16?
                let createdDate: Date?
            }

            let rows: [WaitRow] = try await client
                .from("profileRide")
                .select("waitTime, createdDate")
                .eq("rideId", value: String(rideId))
                .not("waitTime", operator: .is, value: "null")
                .order("createdDate", ascending: false)
                .execute()
                .value

            waitTimeEntries = rows.compactMap { row in
                guard let wait = row.waitTime, let date = row.createdDate else { return nil }
                return WaitTimeEntry(waitTime: wait, createdDate: date)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}
