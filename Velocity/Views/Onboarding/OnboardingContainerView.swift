import SwiftUI
import CoreLocation
import UserNotifications

enum OnboardingStep: Int, CaseIterable {
    case welcome
    case location
    case notifications
    case profileSetup
    case allSet
}

struct OnboardingContainerView: View {
    @State private var currentStep: OnboardingStep = .welcome
    @State private var isMovingForward = true
    @State private var showPermissionSuccess = false
    @Binding var isOnboardingComplete: Bool

    // Persistent location manager — must survive beyond the request call
    @State private var locationManager = CLLocationManager()
    @State private var locationDelegate: LocationPermissionDelegate?

    var body: some View {
        ZStack {
            Color.velocityBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                // Progress indicator (hidden on welcome & allSet)
                if currentStep != .welcome && currentStep != .allSet {
                    progressIndicator
                        .padding(.top, VelocitySpacing.sm)
                        .padding(.horizontal, VelocitySpacing.edgeMargin)
                }

                // Current step view
                Group {
                    switch currentStep {
                    case .welcome:
                        WelcomeView(
                            onGetStarted: { advance() },
                            onLogin: { isOnboardingComplete = true }
                        )
                    case .location:
                        LocationAccessView(
                            onBack: { retreat() },
                            onEnable: { requestLocationPermission() },
                            onSkip: { advance() }
                        )
                    case .notifications:
                        NotificationsPermissionView(
                            onBack: { retreat() },
                            onEnable: { requestNotificationPermission() },
                            onSkip: { advance() }
                        )
                    case .profileSetup:
                        ProfileSetupView(
                            onBack: { retreat() },
                            onContinue: { advance() }
                        )
                    case .allSet:
                        AllSetView(onEnterPark: { isOnboardingComplete = true })
                    }
                }
                .transition(stepTransition)
            }

            // Success checkmark overlay
            if showPermissionSuccess {
                permissionSuccessOverlay
                    .transition(.opacity.combined(with: .scale))
            }
        }
        .animation(.easeInOut(duration: 0.35), value: currentStep)
        .animation(.spring(response: 0.4, dampingFraction: 0.65), value: showPermissionSuccess)
    }

    // MARK: - Permission Success Overlay
    private var permissionSuccessOverlay: some View {
        ZStack {
            Color.velocityBackground.opacity(0.7)
                .ignoresSafeArea()

            VStack(spacing: VelocitySpacing.md) {
                ZStack {
                    Circle()
                        .fill(Color.nitroBlue.opacity(0.15))
                        .frame(width: 120, height: 120)

                    Circle()
                        .fill(LinearGradient.nitroGradient)
                        .frame(width: 88, height: 88)
                        .shadow(color: Color.nitroBlue.opacity(0.5), radius: 20)

                    Image(systemName: "checkmark")
                        .font(.system(size: 40, weight: .bold))
                        .foregroundStyle(.white)
                }

                Text("ENABLED")
                    .font(.labelCaps())
                    .foregroundStyle(Color.nitroBlue)
                    .tracking(3)
            }
        }
    }

    // MARK: - Progress Dots
    private var progressIndicator: some View {
        HStack(spacing: VelocitySpacing.xs) {
            ForEach(OnboardingStep.allCases, id: \.rawValue) { step in
                Capsule()
                    .fill(step.rawValue <= currentStep.rawValue ? Color.nitroBlue : Color.velocityOutlineVariant)
                    .frame(width: step == currentStep ? 24 : 8, height: 4)
                    .animation(.easeInOut(duration: 0.25), value: currentStep)
            }
        }
    }

    private var stepTransition: AnyTransition {
        .asymmetric(
            insertion: .move(edge: isMovingForward ? .trailing : .leading).combined(with: .opacity),
            removal: .move(edge: isMovingForward ? .leading : .trailing).combined(with: .opacity)
        )
    }

    private func advance() {
        let allCases = OnboardingStep.allCases
        guard let idx = allCases.firstIndex(of: currentStep),
              allCases.index(after: idx) < allCases.endIndex else { return }
        isMovingForward = true
        currentStep = allCases[allCases.index(after: idx)]
    }

    /// Shows the checkmark overlay, then advances after a short delay
    private func showSuccessThenAdvance() {
        showPermissionSuccess = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            showPermissionSuccess = false
            advance()
        }
    }

    private func retreat() {
        let allCases = OnboardingStep.allCases
        guard let idx = allCases.firstIndex(of: currentStep),
              idx > allCases.startIndex else { return }
        isMovingForward = false
        currentStep = allCases[allCases.index(before: idx)]
    }

    // MARK: - Location Permission
    private func requestLocationPermission() {
        let status = locationManager.authorizationStatus

        guard status == .notDetermined else {
            showSuccessThenAdvance()
            return
        }

        let delegate = LocationPermissionDelegate { [self] in
            showSuccessThenAdvance()
        }
        self.locationDelegate = delegate
        locationManager.delegate = delegate
        locationManager.requestWhenInUseAuthorization()
    }

    // MARK: - Notification Permission
    private func requestNotificationPermission() {
        let center = UNUserNotificationCenter.current()

        center.getNotificationSettings { settings in
            DispatchQueue.main.async {
                switch settings.authorizationStatus {
                case .notDetermined:
                    center.requestAuthorization(options: [.alert, .badge, .sound]) { _, _ in
                        DispatchQueue.main.async { showSuccessThenAdvance() }
                    }
                default:
                    showSuccessThenAdvance()
                }
            }
        }
    }
}

// MARK: - Location Permission Delegate
/// Stored as @State to keep it alive while the system dialog is showing.
class LocationPermissionDelegate: NSObject, CLLocationManagerDelegate {
    private let onAuthorized: @MainActor () -> Void
    private var hasFired = false

    init(onAuthorized: @escaping @MainActor () -> Void) {
        self.onAuthorized = onAuthorized
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        guard manager.authorizationStatus != .notDetermined else { return }
        Task { @MainActor in
            guard !hasFired else { return }
            hasFired = true
            onAuthorized()
        }
    }
}
