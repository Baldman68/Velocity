import SwiftUI

// MARK: - Glass Card (Glassmorphic container)
struct GlassCard<Content: View>: View {
    let content: () -> Content

    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }

    var body: some View {
        content()
            .background(
                RoundedRectangle(cornerRadius: VelocityRadius.card)
                    .fill(Color.velocitySurfaceContainer)
                    .overlay(
                        RoundedRectangle(cornerRadius: VelocityRadius.card)
                            .stroke(Color.white.opacity(0.15), lineWidth: 1)
                    )
            )
    }
}

// MARK: - Star Rating
struct StarRating: View {
    let rating: Double
    let maxRating: Int
    let size: CGFloat

    init(rating: Double, maxRating: Int = 5, size: CGFloat = 14) {
        self.rating = rating
        self.maxRating = maxRating
        self.size = size
    }

    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<maxRating, id: \.self) { index in
                Image(systemName: starImageName(for: index))
                    .font(.system(size: size))
                    .foregroundStyle(index < Int(rating.rounded()) ? Color.pulseOrange : Color.velocityOutlineVariant)
            }
        }
    }

    private func starImageName(for index: Int) -> String {
        let threshold = Double(index) + 0.5
        if rating >= Double(index + 1) { return "star.fill" }
        if rating >= threshold { return "star.leadinghalf.filled" }
        return "star"
    }
}

// MARK: - Velocity Search Bar
struct VelocitySearchBar: View {
    @Binding var text: String
    var placeholder: String = "Search coasters..."
    var onSubmit: (() -> Void)?

    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: VelocitySpacing.xs) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(isFocused ? Color.nitroBlue : Color.velocityOutline)
                .font(.system(size: 16))

            TextField(placeholder, text: $text)
                .font(.bodyMedium())
                .foregroundStyle(Color.onSurface)
                .focused($isFocused)
                .onSubmit { onSubmit?() }

            if !text.isEmpty {
                Button { text = "" } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(Color.velocityOutline)
                        .font(.system(size: 16))
                }
            }
        }
        .padding(.horizontal, VelocitySpacing.md)
        .padding(.vertical, VelocitySpacing.sm)
        .background(
            RoundedRectangle(cornerRadius: VelocityRadius.component)
                .fill(Color.velocitySurfaceContainerLowest)
                .overlay(
                    RoundedRectangle(cornerRadius: VelocityRadius.component)
                        .stroke(isFocused ? Color.nitroBlue : Color.velocityOutline.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

// MARK: - Stat Card (for tech specs and profile stats)
struct StatCard: View {
    let label: String
    let value: String
    let icon: String?

    init(label: String, value: String, icon: String? = nil) {
        self.label = label
        self.value = value
        self.icon = icon
    }

    var body: some View {
        VStack(spacing: VelocitySpacing.xs) {
            if let icon {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundStyle(Color.nitroBlue)
            }

            Text(value)
                .font(.statValue())
                .foregroundStyle(Color.onSurface)

            Text(label.uppercased())
                .font(.labelCaps())
                .foregroundStyle(Color.onSurfaceVariant)
                .tracking(0.96) // 0.08em at 12px
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, VelocitySpacing.md)
        .background(
            RoundedRectangle(cornerRadius: VelocityRadius.component)
                .fill(Color.velocitySurfaceContainerHigh)
                .overlay(
                    RoundedRectangle(cornerRadius: VelocityRadius.component)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
        )
    }
}

// MARK: - Coaster Card (for horizontal scroll)
struct CoasterCard: View {
    let ride: Ride

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Image placeholder
            ZStack {
                Rectangle()
                    .fill(Color.velocitySurfaceContainerHighest)

                if let url = ride.mainImageURL, let imageURL = URL(string: url) {
                    AsyncImage(url: imageURL) { image in
                        image.resizable().scaledToFill()
                    } placeholder: {
                        Image(systemName: "photo")
                            .font(.system(size: 32))
                            .foregroundStyle(Color.velocityOutlineVariant)
                    }
                } else {
                    Image(systemName: "figure.roller.coaster")
                        .font(.system(size: 32))
                        .foregroundStyle(Color.nitroBlue.opacity(0.5))
                }
            }
            .frame(width: 200, height: 140)
            .clipped()

            VStack(alignment: .leading, spacing: VelocitySpacing.base) {
                if let parkName = ride.park?.name {
                    Text(parkName.uppercased())
                        .font(.labelCaps())
                        .foregroundStyle(Color.nitroBlue)
                        .tracking(0.96)
                        .lineLimit(1)
                }

                Text(ride.name)
                    .font(.headlineMedium())
                    .foregroundStyle(Color.onSurface)
                    .lineLimit(2)

                if ride.starRating > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(Color.pulseOrange)
                        Text(String(format: "%.1f", ride.starRating))
                            .font(.labelCaps())
                            .foregroundStyle(Color.onSurface)
                    }
                }
            }
            .padding(VelocitySpacing.sm)
        }
        .frame(width: 200)
        .background(Color.velocitySurfaceContainer)
        .clipShape(RoundedRectangle(cornerRadius: VelocityRadius.card))
        .overlay(
            RoundedRectangle(cornerRadius: VelocityRadius.card)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
}
