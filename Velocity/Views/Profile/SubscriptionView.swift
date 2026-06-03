import SwiftUI
import StoreKit

struct SubscriptionView: View {
    @State private var subscriptionService = SubscriptionService()
    @State private var billingAnnual = true
    @State private var isPurchasing = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(spacing: VelocitySpacing.lg) {
                // Header
                VStack(spacing: VelocitySpacing.xs) {
                    Text("UPGRADE PROTOCOL")
                        .font(.labelCaps())
                        .foregroundStyle(Color.onSurfaceVariant)
                        .tracking(1.5)
                    Text("CHOOSE YOUR TIER")
                        .font(.headlineHero())
                        .foregroundStyle(Color.nitroBlue)
                        .italic()
                }
                .frame(maxWidth: .infinity)
                .padding(.top, VelocitySpacing.sm)

                // Current plan indicator
                currentPlanBadge

                // Billing toggle
                billingToggle

                // Plan cards
                if subscriptionService.isLoading {
                    ProgressView().tint(Color.nitroBlue)
                        .frame(maxWidth: .infinity, minHeight: 200)
                } else {
                    // PRO card
                    planCard(
                        tier: "PRO",
                        color: Color.nitroBlue,
                        monthlyProduct: subscriptionService.product(for: .proMonthly),
                        annualProduct: subscriptionService.product(for: .proAnnual),
                        features: [
                            "Unlimited check-ins",
                            "Advanced ride stats & journal",
                            "Photo uploads on check-ins",
                            "Interactive coaster map",
                            "Unlimited friends",
                            "Priority data submissions",
                        ],
                        isCurrent: subscriptionService.currentTier == .proMonthly || subscriptionService.currentTier == .proAnnual
                    )

                    // ELITE card
                    planCard(
                        tier: "ELITE",
                        color: Color.pulseOrange,
                        monthlyProduct: subscriptionService.product(for: .eliteMonthly),
                        annualProduct: subscriptionService.product(for: .eliteAnnual),
                        features: [
                            "Everything in PRO",
                            "Park visit planner",
                            "Wait time insights & trends",
                            "Ad-free experience",
                            "Exclusive achievements",
                            "Early access to new features",
                        ],
                        isCurrent: subscriptionService.currentTier == .eliteMonthly || subscriptionService.currentTier == .eliteAnnual
                    )
                }

                // Error
                if let error = subscriptionService.purchaseError {
                    Text(error)
                        .font(.bodySmall())
                        .foregroundStyle(Color.velocityError)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                // Manage subscription link
                manageSubscriptionLink

                // Restore purchases
                Button {
                    Task { await subscriptionService.refreshCurrentTier() }
                } label: {
                    Text("RESTORE PURCHASES")
                        .font(.labelCaps())
                        .foregroundStyle(Color.onSurfaceVariant)
                        .tracking(0.96)
                }

                // Fine print
                Text("Subscriptions auto-renew unless cancelled at least 24 hours before the end of the current period. Manage or cancel in your device's Settings > Subscriptions.")
                    .font(.system(size: 10))
                    .foregroundStyle(Color.onSurfaceVariant.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, VelocitySpacing.md)
            }
            .padding(.horizontal, VelocitySpacing.edgeMargin)
            .padding(.bottom, VelocitySpacing.xl)
        }
        .background(Color.velocityBackground)
        .scrollIndicators(.hidden)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button { dismiss() } label: {
                    HStack(spacing: VelocitySpacing.xs) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 14, weight: .bold))
                        Text("VELOCITY")
                            .font(.custom("ArchivoNarrow-Bold", size: 18))
                            .italic()
                    }
                    .foregroundStyle(Color.nitroBlue)
                }
            }
        }
        .toolbarBackground(Color.velocitySurface.opacity(0.8), for: .navigationBar)
        .task {
            await subscriptionService.loadProducts()
            await subscriptionService.refreshCurrentTier()
        }
    }

    // MARK: - Current Plan Badge
    private var currentPlanBadge: some View {
        HStack(spacing: VelocitySpacing.sm) {
            Image(systemName: currentTierIcon)
                .font(.system(size: 16))
                .foregroundStyle(currentTierColor)
            VStack(alignment: .leading, spacing: 2) {
                Text("CURRENT PLAN")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(Color.onSurfaceVariant)
                    .tracking(0.96)
                Text(subscriptionService.currentTier.displayName.uppercased())
                    .font(.statValue())
                    .foregroundStyle(currentTierColor)
            }
            Spacer()
        }
        .padding(VelocitySpacing.md)
        .background(
            RoundedRectangle(cornerRadius: VelocityRadius.card)
                .fill(currentTierColor.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: VelocityRadius.card)
                        .stroke(currentTierColor.opacity(0.2), lineWidth: 1)
                )
        )
    }

    private var currentTierColor: Color {
        switch subscriptionService.currentTier {
        case .eliteMonthly, .eliteAnnual: Color.pulseOrange
        case .proMonthly, .proAnnual: Color.nitroBlue
        case .free: Color.onSurfaceVariant
        }
    }

    private var currentTierIcon: String {
        switch subscriptionService.currentTier {
        case .eliteMonthly, .eliteAnnual: "bolt.shield.fill"
        case .proMonthly, .proAnnual: "star.circle.fill"
        case .free: "person.circle"
        }
    }

    // MARK: - Billing Toggle
    private var billingToggle: some View {
        HStack(spacing: 0) {
            toggleButton(label: "MONTHLY", selected: !billingAnnual) {
                billingAnnual = false
            }
            toggleButton(label: "ANNUAL · SAVE ~50%", selected: billingAnnual) {
                billingAnnual = true
            }
        }
        .padding(3)
        .background(
            Capsule().fill(Color.velocitySurfaceContainerHigh)
        )
    }

    private func toggleButton(label: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.labelCaps())
                .tracking(0.96)
                .foregroundStyle(selected ? .white : Color.onSurfaceVariant)
                .frame(maxWidth: .infinity)
                .padding(.vertical, VelocitySpacing.sm)
                .background(
                    selected
                        ? AnyShapeStyle(LinearGradient.nitroGradient)
                        : AnyShapeStyle(Color.clear)
                )
                .clipShape(Capsule())
        }
    }

    // MARK: - Plan Card
    private func planCard(
        tier: String,
        color: Color,
        monthlyProduct: Product?,
        annualProduct: Product?,
        features: [String],
        isCurrent: Bool
    ) -> some View {
        let activeProduct = billingAnnual ? annualProduct : monthlyProduct

        return VStack(alignment: .leading, spacing: VelocitySpacing.md) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("VELOCITY")
                        .font(.labelCaps())
                        .foregroundStyle(Color.onSurfaceVariant)
                        .tracking(0.96)
                    Text(tier)
                        .font(.headlineLarge())
                        .foregroundStyle(color)
                        .italic()
                }
                Spacer()
                if isCurrent {
                    Text("ACTIVE")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(color)
                        .tracking(1)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(color.opacity(0.15))
                                .overlay(Capsule().stroke(color.opacity(0.3), lineWidth: 1))
                        )
                }
            }

            // Price
            if let product = activeProduct {
                HStack(alignment: .lastTextBaseline, spacing: 4) {
                    Text(product.displayPrice)
                        .font(.statValueLarge())
                        .foregroundStyle(Color.onSurface)
                    Text("/ \(billingAnnual ? "year" : "month")")
                        .font(.bodySmall())
                        .foregroundStyle(Color.onSurfaceVariant)
                }
            }

            // Divider
            Rectangle()
                .fill(color.opacity(0.2))
                .frame(height: 1)

            // Features
            VStack(alignment: .leading, spacing: VelocitySpacing.sm) {
                ForEach(features, id: \.self) { feature in
                    HStack(spacing: VelocitySpacing.xs) {
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(color)
                        Text(feature)
                            .font(.bodySmall())
                            .foregroundStyle(Color.onSurface)
                    }
                }
            }

            // CTA Button
            if isCurrent {
                HStack(spacing: VelocitySpacing.xs) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 16))
                    Text("CURRENT PLAN")
                        .font(.labelCaps())
                        .tracking(0.96)
                }
                .foregroundStyle(Color.onSurfaceVariant)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(
                    RoundedRectangle(cornerRadius: VelocityRadius.xl)
                        .fill(Color.velocitySurfaceContainerHighest)
                )
            } else if let product = activeProduct {
                Button {
                    isPurchasing = true
                    Task {
                        _ = await subscriptionService.purchase(product)
                        isPurchasing = false
                    }
                } label: {
                    HStack(spacing: VelocitySpacing.xs) {
                        if isPurchasing {
                            ProgressView().tint(tier == "ELITE" ? Color.onPulseOrange : Color.onNitroBlueContainer)
                        } else {
                            Image(systemName: "bolt.fill")
                                .font(.system(size: 14))
                        }
                        Text(subscriptionService.currentTier.tierLevel > 0 ? "SWITCH PLAN" : "UPGRADE NOW")
                            .font(.labelCaps())
                            .tracking(0.96)
                    }
                    .foregroundStyle(tier == "ELITE" ? Color.onPulseOrange : Color.onNitroBlueContainer)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(
                        RoundedRectangle(cornerRadius: VelocityRadius.xl)
                            .fill(
                                tier == "ELITE"
                                    ? LinearGradient(colors: [Color.pulseOrange, Color(hex: "#cc4a00")], startPoint: .topLeading, endPoint: .bottomTrailing)
                                    : LinearGradient.nitroGradient
                            )
                    )
                    .shadow(color: color.opacity(0.3), radius: 12, y: 4)
                }
                .disabled(isPurchasing)
            }
        }
        .padding(VelocitySpacing.lg)
        .background(
            RoundedRectangle(cornerRadius: VelocityRadius.xl)
                .fill(Color.velocitySurfaceContainerLow.opacity(0.7))
                .background(
                    RoundedRectangle(cornerRadius: VelocityRadius.xl)
                        .fill(.ultraThinMaterial)
                        .environment(\.colorScheme, .dark)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: VelocityRadius.xl)
                        .stroke(isCurrent ? color.opacity(0.4) : Color.white.opacity(0.1), lineWidth: isCurrent ? 2 : 1)
                )
        )
    }

    // MARK: - Manage Subscription (cancellation only)
    private var manageSubscriptionLink: some View {
        VStack(spacing: VelocitySpacing.xs) {
            Button {
                if let url = URL(string: "https://apps.apple.com/account/subscriptions") {
                    UIApplication.shared.open(url)
                }
            } label: {
                HStack(spacing: VelocitySpacing.xs) {
                    Image(systemName: "xmark.circle")
                        .font(.system(size: 14))
                    Text("CANCEL SUBSCRIPTION")
                        .font(.labelCaps())
                        .tracking(0.96)
                }
                .foregroundStyle(Color.onSurfaceVariant)
                .frame(maxWidth: .infinity)
                .padding(.vertical, VelocitySpacing.md)
                .background(
                    RoundedRectangle(cornerRadius: VelocityRadius.xl)
                        .stroke(Color.velocityOutlineVariant, lineWidth: 1)
                )
            }
            Text("Cancellation must be done through your device's subscription settings.")
                .font(.system(size: 10))
                .foregroundStyle(Color.onSurfaceVariant.opacity(0.5))
        }
    }
}
