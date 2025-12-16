import Foundation
import Supabase

/// Handles cloud sync with Supabase
/// Uses anonymous device-based identification
final class SupabaseService {
    static let shared = SupabaseService()
    
    private let client: SupabaseClient
    private let deviceId: String
    
    private init() {
        // Initialize Supabase client
        self.client = SupabaseClient(
            supabaseURL: URL(string: SupabaseConfig.url)!,
            supabaseKey: SupabaseConfig.anonKey
        )
        
        // Get or create persistent device ID
        self.deviceId = SupabaseService.getOrCreateDeviceId()
    }
    
    // MARK: - Device ID Management
    
    private static func getOrCreateDeviceId() -> String {
        let key = "device_id"
        
        // Check UserDefaults first (simpler than Keychain for MVP)
        if let existingId = UserDefaults.standard.string(forKey: key) {
            return existingId
        }
        
        // Create new device ID
        let newId = UUID().uuidString
        UserDefaults.standard.set(newId, forKey: key)
        return newId
    }
    
    // MARK: - Entry Operations
    
    /// Upload a single entry to Supabase (upsert based on device_id + date)
    func uploadEntry(_ entry: Entry) async {
        do {
            let cloudEntry = CloudEntry(from: entry, deviceId: deviceId)
            
            try await client
                .from("entries")
                .upsert(cloudEntry, onConflict: "device_id,date")
                .execute()
            
            print("✓ Entry synced to cloud: \(entry.date)")
        } catch {
            print("✗ Cloud sync failed: \(error.localizedDescription)")
            // Fail silently - local data is still saved
        }
    }
    
    /// Fetch all entries for this device from Supabase
    func fetchEntries() async -> [Entry] {
        do {
            let response: [CloudEntry] = try await client
                .from("entries")
                .select()
                .eq("device_id", value: deviceId)
                .order("timestamp", ascending: true)
                .execute()
                .value
            
            print("✓ Fetched \(response.count) entries from cloud")
            return response.map { $0.toEntry() }
        } catch {
            print("✗ Cloud fetch failed: \(error.localizedDescription)")
            return []
        }
    }
    
    /// Sync local entries with cloud (bidirectional)
    func syncAll(localEntries: [Entry]) async -> [Entry] {
        // Fetch cloud entries
        let cloudEntries = await fetchEntries()
        
        // Upload any local entries not in cloud (or newer)
        for local in localEntries {
            let cloudVersion = cloudEntries.first { $0.date == local.date }
            if cloudVersion == nil || local.timestamp > cloudVersion!.timestamp {
                await uploadEntry(local)
            }
        }
        
        // Merge: prefer cloud version if newer, otherwise keep local
        var merged: [String: Entry] = [:]
        
        for entry in localEntries {
            merged[entry.date] = entry
        }
        
        for entry in cloudEntries {
            if let existing = merged[entry.date] {
                if entry.timestamp > existing.timestamp {
                    merged[entry.date] = entry
                }
            } else {
                merged[entry.date] = entry
            }
        }
        
        return Array(merged.values).sorted { $0.timestamp < $1.timestamp }
    }
}

// MARK: - Cloud Entry Model (Supabase schema)

/// Matches the Supabase table structure with snake_case columns
private struct CloudEntry: Codable {
    let id: UUID
    let device_id: String
    let date: String
    let prompt_id: String
    let choice: String
    let secondary_prompt_id: String?
    let secondary_response: String?
    let tertiary_prompt_id: String?
    let tertiary_response: String?
    let timestamp: Int64
    
    init(from entry: Entry, deviceId: String) {
        self.id = entry.id
        self.device_id = deviceId
        self.date = entry.date
        self.prompt_id = entry.promptId
        self.choice = entry.choice
        self.secondary_prompt_id = entry.secondaryPromptId
        self.secondary_response = entry.secondaryResponse
        self.tertiary_prompt_id = entry.tertiaryPromptId
        self.tertiary_response = entry.tertiaryResponse
        self.timestamp = Int64(entry.timestamp)
    }
    
    func toEntry() -> Entry {
        Entry(
            id: id,
            date: date,
            promptId: prompt_id,
            choice: choice,
            secondaryPromptId: secondary_prompt_id,
            secondaryResponse: secondary_response,
            tertiaryPromptId: tertiary_prompt_id,
            tertiaryResponse: tertiary_response,
            timestamp: TimeInterval(timestamp)
        )
    }
}

