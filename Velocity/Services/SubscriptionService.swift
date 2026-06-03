import Foundation
import StoreKit
import Observation

/// Maps App Store Connect product IDs to subscription tiers
enum VelocityTier: String, CaseIterable, Comparable {
    case free = "free"
    case proMonthly = "vel_pro_month499"
    case proAnnual = "vel_pro_year2999"
    case eliteMonthly = "vel_elite_month999"
    case eliteAnnual = "vel_elite_year5999"

    var displayName: String {
        switch self {
        case .free: "Free"
        case .proMonthly, .proAnnual: "Velocity PRO"
        case .eliteMonthly, .eliteAnnual: "Velocity ELITE"
        }
    }

    var tierLevel: Int {
        switch self {
        case .free: 0
        case .proMonthly, .proAnnual: 1
        case .eliteMonthly, .eliteAnnual: 2
        }
    }

    var isAnnual: Bool {
        self == .proAnnual || self == .eliteAnnual
    }

    /// The subscription name to match in the subscriptionType table
    var dbSubscriptionName: String {
        switch self {
        case .free: ""
        case .proMonthly: "vel_pro_month499"
        case .proAnnual: "vel_pro_year2999"
        case .eliteMonthly: "vel_elite_month999"
        case .eliteAnnual: "vel_elite_year5999"
        }
    }

    static func from(productId: String) -> VelocityTier? {
        allCases.first { $0.rawValue == productId }
    }

    static func < (lhs: VelocityTier, rhs: VelocityTier) -> Bool {
        lhs.tierLevel < rhs.tierLevel
    }

    static let allProductIds = [
        proMonthly.rawValue,
        proAnnual.rawValue,
        eliteMonthly.rawValue,
        eliteAnnual.rawValue,
    ]
}

@Observable
@MainActor
final class SubscriptionService {
    var products: [Product] = []
    var currentTier: VelocityTier = .free
    var isLoading = false
    var purchaseError: String?

    private var transactionListener: Task<Void, Never>?
    private let profileService = ProfileService()

    init() {
        transactionListener = listenForTransactions()
    }

    func cancel() {
        transactionListener?.cancel()
    }

    // MARK: - Load Products

    func loadProducts() async {
        isLoading = true
        do {
            let storeProducts = try await Product.products(for: Set(VelocityTier.allProductIds))
            // Sort: PRO monthly, PRO annual, ELITE monthly, ELITE annual
            products = storeProducts.sorted { a, b in
                let tierA = VelocityTier.from(productId: a.id)?.tierLevel ?? 0
                let tierB = VelocityTier.from(productId: b.id)?.tierLevel ?? 0
                if tierA != tierB { return tierA < tierB }
                return a.price < b.price
            }
        } catch {
            purchaseError = "Failed to load products: \(error.localizedDescription)"
        }
        isLoading = false
    }

    // MARK: - Check Current Entitlement

    func refreshCurrentTier() async {
        var highestTier: VelocityTier = .free

        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result {
                if let tier = VelocityTier.from(productId: transaction.productID), tier > highestTier {
                    highestTier = tier
                }
            }
        }

        currentTier = highestTier
    }

    // MARK: - Purchase

    func purchase(_ product: Product) async -> Bool {
        purchaseError = nil
        do {
            let result = try await product.purchase()

            switch result {
            case .success(let verification):
                if case .verified(let transaction) = verification {
                    await transaction.finish()

                    if let tier = VelocityTier.from(productId: transaction.productID) {
                        currentTier = tier
                        await syncSubscriptionToProfile(tier: tier)
                    }
                    return true
                } else {
                    purchaseError = "Purchase could not be verified."
                    return false
                }

            case .userCancelled:
                return false

            case .pending:
                purchaseError = "Purchase is pending approval."
                return false

            @unknown default:
                purchaseError = "Unknown purchase result."
                return false
            }
        } catch {
            purchaseError = error.localizedDescription
            return false
        }
    }

    // MARK: - Sync to Supabase

    func syncSubscriptionToProfile(tier: VelocityTier) async {
        do {
            guard let profile = try await profileService.fetchCurrentProfile() else { return }

            // Fetch all subscription types and find the matching one
            let allTypes = try await profileService.fetchAllSubscriptionTypes()
            if let matchingType = allTypes.first(where: { $0.subscriptionName == tier.dbSubscriptionName }) {
                try await profileService.updateSubscriptionType(
                    profileId: profile.id,
                    subscriptionTypeId: matchingType.id
                )
            }
        } catch {
            // Sync failure is non-critical — the entitlement is still valid via StoreKit
            debugPrint("Failed to sync subscription to profile: \(error)")
        }
    }

    // MARK: - Transaction Listener

    private func listenForTransactions() -> Task<Void, Never> {
        Task.detached { [weak self] in
            for await result in Transaction.updates {
                if case .verified(let transaction) = result {
                    await transaction.finish()
                    await self?.refreshCurrentTier()

                    let productID = transaction.productID
                    if let tier = await VelocityTier.from(productId: productID) {
                        await self?.syncSubscriptionToProfile(tier: tier)
                    }
                }
            }
        }
    }

    // MARK: - Helpers

    func product(for tier: VelocityTier) -> Product? {
        products.first { $0.id == tier.rawValue }
    }

    var proProducts: [Product] {
        products.filter { id in
            id.id == VelocityTier.proMonthly.rawValue || id.id == VelocityTier.proAnnual.rawValue
        }
    }

    var eliteProducts: [Product] {
        products.filter { id in
            id.id == VelocityTier.eliteMonthly.rawValue || id.id == VelocityTier.eliteAnnual.rawValue
        }
    }
}
