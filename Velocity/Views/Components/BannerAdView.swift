import SwiftUI
import GoogleMobileAds
#if canImport(AppTrackingTransparency)
import AppTrackingTransparency
#endif
import UIKit

/// AdMob banner ad unit ID
#if DEBUG
private let adUnitID = "ca-app-pub-3940256099942544/2435281174"
#else
private let adUnitID = "ca-app-pub-8245053297432454/2177963005"
#endif

// MARK: - UIKit Banner Wrapper
struct AdBannerRepresentable: UIViewRepresentable {
    func makeUIView(context: Context) -> BannerView {
        let banner = BannerView(adSize: AdSizeBanner)
        banner.adUnitID = adUnitID
        if let windowScene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first(where: { $0.activationState == .foregroundActive }),
           let rootVC = windowScene.keyWindow?.rootViewController {
            banner.rootViewController = rootVC
        }
        banner.load(Request())
        return banner
    }

    func updateUIView(_ uiView: BannerView, context: Context) {}
}

// MARK: - SwiftUI Banner View (subscription-aware)
struct BannerAdView: View {
    @State private var subscriptionService = SubscriptionService()

    var body: some View {
        Group {
            if !subscriptionService.currentTier.isPaid {
                VStack(spacing: 0) {
                    // Subtle upgrade nudge
                    HStack(spacing: VelocitySpacing.xs) {
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 9))
                        Text("UPGRADE TO PRO TO REMOVE ADS")
                            .font(.system(size: 9, weight: .bold))
                            .tracking(0.5)
                    }
                    .foregroundStyle(Color.nitroBlue.opacity(0.6))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 3)
                    .background(Color.velocitySurfaceContainerLowest)

                    // Ad banner
                    AdBannerRepresentable()
                        .frame(height: 50)
                        .background(Color.velocitySurfaceContainerLowest)
                }
            }
        }
        .task {
            await subscriptionService.refreshCurrentTier()
        }
    }
}

// MARK: - VelocityTier extension for ad check
extension VelocityTier {
    var isPaid: Bool {
        tierLevel > 0
    }
}

// MARK: - AdMob Initialization
enum AdMobManager {
    static func configure() {
        Task { @MainActor in
            // Small delay to let the app UI settle
            try? await Task.sleep(for: .seconds(1))

            #if canImport(AppTrackingTransparency)
            if #available(iOS 14, *) {
                _ = await ATTrackingManager.requestTrackingAuthorization()
            }
            #endif

            await MobileAds.shared.start()
        }
    }
}
