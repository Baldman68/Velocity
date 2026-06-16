import Foundation
import Observation
import Supabase
import SwiftUI

@Observable
@MainActor
final class ParkPlannerViewModel {
    var rides: [Ride] = []
    var selectedRideIds: [Int64] = []
    var planName: String = ""
    var plannedDate: Date = Date()
    var existingPlan: ParkVisitPlan?
    var isLoading = false
    var isSaving = false
    var errorMessage: String?
    var saveSuccess = false

    private let client = SupabaseManager.shared.client

    var selectedRides: [Ride] {
        selectedRideIds.compactMap { id in rides.first(where: { $0.id == id }) }
    }

    var unselectedRides: [Ride] {
        rides.filter { !selectedRideIds.contains($0.id) }
    }

    func loadPark(parkId: Int64, profileId: Int64) async {
        isLoading = true
        errorMessage = nil
        do {
            // Load rides for this park
            rides = try await client
                .from("ride")
                .select("*, park(*)")
                .eq("parkId", value: String(parkId))
                .order("name", ascending: true)
                .execute()
                .value

            // Load existing plan if any
            let plans: [ParkVisitPlan] = try await client
                .from("parkVisitPlan")
                .select()
                .eq("profileId", value: String(profileId))
                .eq("parkId", value: String(parkId))
                .order("createdDate", ascending: false)
                .limit(1)
                .execute()
                .value

            if let plan = plans.first {
                existingPlan = plan
                selectedRideIds = plan.rideIds
                planName = plan.name ?? ""
                if let date = plan.plannedDate {
                    plannedDate = date
                }
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func toggleRide(_ rideId: Int64) {
        if let index = selectedRideIds.firstIndex(of: rideId) {
            selectedRideIds.remove(at: index)
        } else {
            selectedRideIds.append(rideId)
        }
    }

    func moveRide(from source: IndexSet, to destination: Int) {
        selectedRideIds.move(fromOffsets: source, toOffset: destination)
    }

    func savePlan(profileId: Int64, parkId: Int64) async {
        isSaving = true
        errorMessage = nil
        do {
            if let existing = existingPlan {
                // Update existing plan
                struct PlanUpdate: Encodable {
                    let rideIds: [Int64]
                    let name: String?
                    let plannedDate: Date?
                }
                try await client
                    .from("parkVisitPlan")
                    .update(PlanUpdate(
                        rideIds: selectedRideIds,
                        name: planName.isEmpty ? nil : planName,
                        plannedDate: plannedDate
                    ))
                    .eq("id", value: String(existing.id))
                    .execute()
            } else {
                // Create new plan
                struct NewPlan: Encodable {
                    let profileId: Int64
                    let parkId: Int64
                    let rideIds: [Int64]
                    let name: String?
                    let plannedDate: Date?
                }
                try await client
                    .from("parkVisitPlan")
                    .insert(NewPlan(
                        profileId: profileId,
                        parkId: parkId,
                        rideIds: selectedRideIds,
                        name: planName.isEmpty ? nil : planName,
                        plannedDate: plannedDate
                    ))
                    .execute()
            }
            saveSuccess = true
        } catch {
            errorMessage = error.localizedDescription
        }
        isSaving = false
    }

    func deletePlan() async {
        guard let existing = existingPlan else { return }
        isSaving = true
        do {
            try await client
                .from("parkVisitPlan")
                .delete()
                .eq("id", value: String(existing.id))
                .execute()
            existingPlan = nil
            selectedRideIds = []
            planName = ""
            saveSuccess = false
        } catch {
            errorMessage = error.localizedDescription
        }
        isSaving = false
    }
}
