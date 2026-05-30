# Velocity — Agent Context

This file provides context for AI coding agents working on this codebase.

## App Summary

Velocity is an iOS SwiftUI app for tracking roller coaster check-ins. Users discover rides, check in at parks, write reviews, earn achievements, and compete on leaderboards. The backend is Supabase (Postgres + Auth).

## Architecture

**Pattern: MVVM + Service Layer**

```
View  →  ViewModel (@Observable)  →  Service (@MainActor)  →  SupabaseManager (client)
```

- **Views** — SwiftUI, purely presentational, hold `@State private var viewModel = ...`
- **ViewModels** — `@Observable @MainActor final class`, own state, call services via `async/await`
- **Services** — `@MainActor final class`, each owns one domain, directly call `SupabaseManager.shared.client`
- **Models** — `Codable & Sendable` structs, no business logic, used as DTOs straight from Supabase

## Key Files

| File | Purpose |
|---|---|
| `Models/Models.swift` | All model types — never split into multiple files |
| `Services/SupabaseManager.swift` | Singleton `SupabaseClient`, URL + key |
| `Theme/VelocityTheme.swift` | All design tokens: colors, fonts, spacing, radii |
| `VelocityApp.swift` | Entry point; routes to onboarding or `MainTabView` based on `@AppStorage("hasCompletedOnboarding")` |

## Coding Conventions

### Models
- All in `Models/Models.swift` — do not create separate model files
- Conform to `Codable, Identifiable, Sendable`
- Use `Int64` for all Supabase `bigint` IDs
- Use `Int16` for small numeric columns (speed, height, inversions, score, waitTime)
- Use `Float` for decimal stats (gForce)
- All fields that can be null in the DB must be `Optional`
- Joined relations are included as optional properties (e.g. `let park: Park?` on `Ride`)

### Services
- One service per domain (`RideService`, `ProfileService`, `CheckInService`, `LeaderboardService`)
- `AuthService` lives at the bottom of `LeaderboardService.swift`
- All methods are `async throws`; callers handle errors
- Use `SupabaseManager.shared.client` — never create a new `SupabaseClient`
- For inserts, define a local `struct NewX: Encodable` inside the method

### ViewModels
- `@Observable @MainActor final class`; one per screen
- Instantiate services directly as `private let service = XService()`
- Loading state: `var isLoading = false` toggled around async work
- Errors: `var errorMessage: String?` set from `catch { errorMessage = error.localizedDescription }`
- Never call `DispatchQueue.main.async` — everything is already `@MainActor`

### Views
- Instantiate ViewModel as `@State private var viewModel = XViewModel()`
- Trigger data loading with `.task { await viewModel.loadX() }`
- Use `NavigationStack` + `NavigationLink(destination:)` for navigation
- Always use design tokens from `VelocityTheme.swift` — no hardcoded hex values or magic numbers

## Design System

All tokens are in `Theme/VelocityTheme.swift`. Always use them.

**Colors (most common)**
- `Color.velocityBackground` — screen background
- `Color.velocitySurfaceContainerLow / High / Highest` — card/surface fills
- `Color.nitroBlue` — primary accent (highlights, stats, CTAs)
- `Color.pulseOrange` — hot/urgent badges, secondary CTAs
- `Color.onSurface` — primary text
- `Color.onSurfaceVariant` — secondary/muted text
- `Color.velocityOutlineVariant` — borders, dividers

**Typography** — always use `Font` extensions, never `.system(size:)`
- `Font.headlineHero()` / `.headlineLarge()` / `.headlineMedium()` — Archivo Narrow Bold
- `Font.bodyLarge()` / `.bodyMedium()` / `.bodySmall()` — Inter
- `Font.labelCaps()` — Space Grotesk Bold 12pt (use with `.tracking(…)`)
- `Font.statValue()` / `.statValueLarge()` — Space Grotesk SemiBold

**Spacing** — `VelocitySpacing.xs/sm/md/lg/xl/edgeMargin/gutter`

**Corner radii** — `VelocityRadius.sm/component/card/lg/xl/full`

**Gradients** — `LinearGradient.nitroGradient`, `.heroOverlay`

## Supabase Query Patterns

```swift
// Fetch with joined relation
let rides: [Ride] = try await client
    .from("ride")
    .select("*, park(*)")
    .order("speed", ascending: false)
    .limit(10)
    .execute()
    .value

// Insert and return
let result: ProfileRide = try await client
    .from("profileRide")
    .insert(payload)
    .select("*, ride(*, park(*))")
    .single()
    .execute()
    .value

// Upsert
try await client
    .from("profileRideNote")
    .upsert(payload)
    .execute()
```

Column names in queries use the **Supabase column name** (camelCase as stored in Postgres — e.g. `"parkId"`, `"createdDate"`). The Swift client decodes them to matching Swift property names automatically.

## Supabase Tables → Swift Models

| Table | Swift Model |
|---|---|
| `profile` | `Profile` |
| `park` | `Park` |
| `ride` | `Ride` |
| `profileRide` | `ProfileRide` |
| `profileRideReview` | `ProfileRideReview` |
| `profileRideReviewRating` | `ProfileRideReviewRating` |
| `profileRideNote` | `ProfileRideNote` |
| `profileRideImage` | `ProfileRideImage` |
| `achievement` | `Achievement` |
| `profileAchievement` | `ProfileAchievement` |
| `message` | `Message` |
| `profileMessage` | `ProfileMessage` |
| `subscriptionType` | `SubscriptionType` |

## Auth

`AuthService` (in `LeaderboardService.swift`) wraps `client.auth`. Current user ID is accessed via:

```swift
client.auth.currentUser?.id.uuidString
```

The app does not use SwiftData or local persistence — all data is fetched from Supabase on demand.

## Dark Mode

The app is **dark-only** (`.preferredColorScheme(.dark)` set at the root). Do not add light mode support unless explicitly requested.

## Tab Structure

`MainTabView` has three tabs: **Discover** (`.discover`), **Ranks** (`.leaderboard`), **Profile** (`.profile`). Tab bar is tinted `nitroBlue`.

## Onboarding Flow

`OnboardingContainerView` steps: `.welcome → .location → .notifications → .profileSetup → .allSet`

Completion is persisted in `@AppStorage("hasCompletedOnboarding")`.

## Things to Avoid

- Don't use `DispatchQueue.main.async` — use `Task { @MainActor in … }` or rely on `@MainActor` context
- Don't hardcode colors, fonts, or spacing — always use `VelocityTheme` tokens
- Don't create new `SupabaseClient` instances
- Don't add SwiftData `@Model` classes — this project uses plain `Codable` structs
- Don't split `Models.swift` into multiple files
- Don't use `@StateObject` / `@ObservedObject` — use `@State` with `@Observable` ViewModels
