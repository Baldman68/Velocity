import SwiftUI

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
    @Binding var isOnboardingComplete: Bool

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
                            onEnable: { advance() },
                            onSkip: { advance() }
                        )
                    case .notifications:
                        NotificationsPermissionView(
                            onBack: { retreat() },
                            onEnable: { advance() },
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
        }
        .animation(.easeInOut(duration: 0.35), value: currentStep)
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

    private func retreat() {
        let allCases = OnboardingStep.allCases
        guard let idx = allCases.firstIndex(of: currentStep),
              idx > allCases.startIndex else { return }
        isMovingForward = false
        currentStep = allCases[allCases.index(before: idx)]
    }
}
