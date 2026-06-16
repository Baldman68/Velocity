import SwiftUI
import Charts

struct WaitTimeInsightsView: View {
    let rideId: Int64
    let rideName: String
    @State private var viewModel = WaitTimeInsightsViewModel()
    @State private var subscriptionService = SubscriptionService()
    @State private var showSubscription = false
    @Environment(\.dismiss) private var dismiss

    private var isElite: Bool { subscriptionService.currentTier.tierLevel >= 2 }

    var body: some View {
        ScrollView {
            VStack(spacing: VelocitySpacing.xl) {
                header
                overviewStats

                if viewModel.isLoading {
                    ProgressView().tint(Color.nitroBlue)
                        .frame(maxWidth: .infinity, minHeight: 200)
                } else if viewModel.waitTimeEntries.isEmpty {
                    emptyState
                } else {
                    dayOfWeekChart
                    monthlyBreakdown
                    peakTimesSection
                }
            }
            .padding(.bottom, 100)
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
            await subscriptionService.refreshCurrentTier()
            await viewModel.loadInsights(rideId: rideId)
        }
        .navigationDestination(isPresented: $showSubscription) {
            SubscriptionView()
        }
    }

    // MARK: - Header
    private var header: some View {
        VStack(spacing: VelocitySpacing.xs) {
            Text("WAIT TIME INSIGHTS")
                .font(.headlineHero())
                .foregroundStyle(Color.nitroBlue)
                .italic()
            Text(rideName.uppercased())
                .font(.labelCaps())
                .foregroundStyle(Color.onSurfaceVariant)
                .tracking(1.5)
                .lineLimit(1)
        }
        .padding(.horizontal, VelocitySpacing.edgeMargin)
        .padding(.top, VelocitySpacing.md)
    }

    // MARK: - Overview Stats
    private var overviewStats: some View {
        HStack(spacing: VelocitySpacing.sm) {
            insightStat(label: "AVG WAIT", value: viewModel.overallAverage, unit: "MIN", icon: "clock")
            insightStat(label: "REPORTS", value: "\(viewModel.totalReports)", unit: "", icon: "doc.text")
            insightStat(label: "BEST DAY", value: viewModel.bestDay, unit: "", icon: "star")
        }
        .padding(.horizontal, VelocitySpacing.edgeMargin)
    }

    private func insightStat(label: String, value: String, unit: String, icon: String) -> some View {
        VStack(spacing: VelocitySpacing.xs) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(Color.nitroBlue)
            HStack(spacing: 2) {
                Text(value)
                    .font(.statValueLarge())
                    .foregroundStyle(Color.onSurface)
                if !unit.isEmpty {
                    Text(unit)
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(Color.onSurfaceVariant)
                }
            }
            Text(label)
                .font(.system(size: 8, weight: .bold))
                .foregroundStyle(Color.onSurfaceVariant)
                .tracking(0.96)
        }
        .frame(maxWidth: .infinity, minHeight: 90)
        .background(glassCard)
    }

    // MARK: - Day of Week Chart
    private var dayOfWeekChart: some View {
        VStack(alignment: .leading, spacing: VelocitySpacing.md) {
            sectionHeader(title: "WAIT BY DAY OF WEEK", icon: "chart.bar")

            ZStack {
                Chart(viewModel.dayOfWeekData) { entry in
                    BarMark(
                        x: .value("Day", entry.dayAbbrev),
                        y: .value("Minutes", entry.avgWait)
                    )
                    .foregroundStyle(
                        entry.dayAbbrev == viewModel.peakDay
                            ? Color.pulseOrange
                            : Color.nitroBlue
                    )
                    .cornerRadius(4)
                }
                .chartYAxisLabel("Minutes")
                .chartXAxis {
                    AxisMarks { _ in
                        AxisValueLabel()
                            .foregroundStyle(Color.onSurfaceVariant)
                    }
                }
                .chartYAxis {
                    AxisMarks { _ in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                            .foregroundStyle(Color.white.opacity(0.1))
                        AxisValueLabel()
                            .foregroundStyle(Color.onSurfaceVariant)
                    }
                }
                .frame(height: 220)

                // ELITE gate overlay
                if !isElite {
                    eliteGateOverlay
                }
            }
            .padding(VelocitySpacing.lg)
            .background(glassCard)
        }
        .padding(.horizontal, VelocitySpacing.edgeMargin)
    }

    // MARK: - Monthly Breakdown
    private var monthlyBreakdown: some View {
        VStack(alignment: .leading, spacing: VelocitySpacing.md) {
            sectionHeader(title: "MONTHLY AVERAGES", icon: "calendar")

            ZStack {
                VStack(spacing: 0) {
                    ForEach(Array(viewModel.monthlyData.enumerated()), id: \.element.id) { index, entry in
                        HStack {
                            Text(entry.monthName)
                                .font(.bodyMedium())
                                .foregroundStyle(Color.onSurface)
                                .frame(width: 80, alignment: .leading)

                            // Bar
                            GeometryReader { geo in
                                let maxWait = viewModel.monthlyData.map(\.avgWait).max() ?? 1
                                let barWidth = maxWait > 0 ? (CGFloat(entry.avgWait) / CGFloat(maxWait)) * geo.size.width : 0
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(Color.nitroBlue)
                                    .frame(width: max(barWidth, 4), height: 20)
                            }
                            .frame(height: 20)

                            Text("\(entry.avgWait) min")
                                .font(.labelCaps())
                                .foregroundStyle(Color.onSurfaceVariant)
                                .frame(width: 55, alignment: .trailing)
                        }
                        .padding(.vertical, VelocitySpacing.xs)
                        .padding(.horizontal, VelocitySpacing.md)

                        if index < viewModel.monthlyData.count - 1 {
                            Rectangle()
                                .fill(Color.white.opacity(0.05))
                                .frame(height: 1)
                                .padding(.horizontal, VelocitySpacing.md)
                        }
                    }
                }

                if !isElite {
                    eliteGateOverlay
                }
            }
            .background(glassCard)
        }
        .padding(.horizontal, VelocitySpacing.edgeMargin)
    }

    // MARK: - Peak Times
    private var peakTimesSection: some View {
        VStack(alignment: .leading, spacing: VelocitySpacing.md) {
            sectionHeader(title: "PEAK INSIGHTS", icon: "bolt.fill")

            ZStack {
                VStack(alignment: .leading, spacing: VelocitySpacing.md) {
                    if let peak = viewModel.peakInsight {
                        insightRow(icon: "exclamationmark.triangle", color: .pulseOrange,
                                   text: peak)
                    }
                    if let best = viewModel.bestInsight {
                        insightRow(icon: "checkmark.circle", color: .nitroBlue,
                                   text: best)
                    }
                }
                .padding(VelocitySpacing.lg)

                if !isElite {
                    eliteGateOverlay
                }
            }
            .background(glassCard)
        }
        .padding(.horizontal, VelocitySpacing.edgeMargin)
    }

    private func insightRow(icon: String, color: Color, text: String) -> some View {
        HStack(alignment: .top, spacing: VelocitySpacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(color)
                .frame(width: 24)
            Text(text)
                .font(.bodyMedium())
                .foregroundStyle(Color.onSurface)
                .lineSpacing(2)
        }
    }

    // MARK: - Empty State
    private var emptyState: some View {
        VStack(spacing: VelocitySpacing.md) {
            Image(systemName: "clock.badge.questionmark")
                .font(.system(size: 48))
                .foregroundStyle(Color.onSurfaceVariant.opacity(0.3))
            Text("No wait time data yet")
                .font(.headlineMedium())
                .foregroundStyle(Color.onSurfaceVariant)
            Text("Check in and report wait times to unlock insights for this coaster.")
                .font(.bodySmall())
                .foregroundStyle(Color.onSurfaceVariant.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .padding(VelocitySpacing.xl)
    }

    // MARK: - ELITE Gate Overlay
    private var eliteGateOverlay: some View {
        ZStack {
            Rectangle()
                .fill(.ultraThinMaterial)
                .environment(\.colorScheme, .dark)

            VStack(spacing: VelocitySpacing.sm) {
                Image(systemName: "lock.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(Color.pulseOrange)

                Text("ELITE EXCLUSIVE")
                    .font(.labelCaps())
                    .foregroundStyle(Color.pulseOrange)
                    .tracking(1.5)

                Button {
                    showSubscription = true
                } label: {
                    Text("UPGRADE TO ELITE")
                        .font(.labelCaps())
                        .tracking(0.96)
                        .foregroundStyle(.white)
                        .padding(.horizontal, VelocitySpacing.lg)
                        .padding(.vertical, VelocitySpacing.sm)
                        .background(
                            Capsule().fill(Color.pulseOrange)
                        )
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: VelocityRadius.xl))
    }

    // MARK: - Helpers
    private func sectionHeader(title: String, icon: String) -> some View {
        HStack(spacing: VelocitySpacing.xs) {
            Image(systemName: icon)
                .foregroundStyle(Color.nitroBlue)
            Text(title)
                .font(.headlineMedium())
                .foregroundStyle(Color.onSurface)
            Spacer()
        }
    }

    private var glassCard: some View {
        RoundedRectangle(cornerRadius: VelocityRadius.xl)
            .fill(Color.velocitySurfaceContainerLow.opacity(0.6))
            .background(
                RoundedRectangle(cornerRadius: VelocityRadius.xl)
                    .fill(.ultraThinMaterial)
                    .environment(\.colorScheme, .dark)
            )
            .overlay(
                RoundedRectangle(cornerRadius: VelocityRadius.xl)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
    }
}
