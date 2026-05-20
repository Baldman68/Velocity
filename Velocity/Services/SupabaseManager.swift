import Foundation
import Supabase

@MainActor
final class SupabaseManager {
    static let shared = SupabaseManager()

    let client: SupabaseClient

    private init() {
        client = SupabaseClient(
            supabaseURL: URL(string: "https://npxcgmihvsttunpntupa.supabase.co")!,
            supabaseKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5weGNnbWlodnN0dHVucG50dXBhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzg1NjM5ODEsImV4cCI6MjA5NDEzOTk4MX0.22xkUweO--Jn_IUicFEzncmfCTSe0l_bCrCRPpY4XOg"
        )
    }
}
