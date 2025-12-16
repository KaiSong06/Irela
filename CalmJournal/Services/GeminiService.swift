import Foundation

/// Service for generating AI insights via Supabase Edge Function
/// The Gemini API key is stored securely in Supabase secrets
final class GeminiService {
    static let shared = GeminiService()
    
    private init() {}
    
    /// Generate weekly recap insights from journal entries
    /// - Parameters:
    ///   - entries: Array of journal entries from the past week
    ///   - depth: Depth level for insights (light, reflect, deep)
    /// - Returns: Array of insight strings, or nil if generation fails
    func generateWeeklyInsights(from entries: [Entry], depth: DepthLevel) async -> [String]? {
        guard !entries.isEmpty else {
            return ["No check-ins yet this week.", "Come back after a few days."]
        }
        
        guard let url = URL(string: "\(SupabaseConfig.url)/functions/v1/generate-insights") else {
            print("✗ Invalid Edge Function URL")
            return nil
        }
        
        // Prepare entries for the edge function
        let entryData = entries.map { entry -> [String: Any] in
            var data: [String: Any] = [
                "date": entry.date,
                "choice": entry.choice
            ]
            if let secondary = entry.secondaryResponse {
                data["secondary_response"] = secondary
            }
            if let tertiary = entry.tertiaryResponse {
                data["tertiary_response"] = tertiary
            }
            return data
        }
        
        let depthString: String
        switch depth {
        case .light: depthString = "light"
        case .reflect: depthString = "reflect"
        case .deep: depthString = "deep"
        }
        
        let body: [String: Any] = [
            "entries": entryData,
            "depth": depthString
        ]
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: body) else {
            print("✗ Failed to serialize request body")
            return nil
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(SupabaseConfig.anonKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = jsonData
        request.timeoutInterval = 30 // 30 second timeout for AI generation
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("✗ Invalid response from Edge Function")
                return nil
            }
            
            guard httpResponse.statusCode == 200 else {
                print("✗ Edge Function returned status \(httpResponse.statusCode)")
                if let errorJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let error = errorJson["error"] as? String {
                    print("  Error: \(error)")
                }
                return nil
            }
            
            // Parse response
            guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                print("✗ Failed to parse Edge Function response")
                return nil
            }
            
            if let insights = json["insights"] as? [String], !insights.isEmpty {
                print("✓ Generated \(insights.count) insights via Edge Function")
                return insights
            }
            
            print("✗ No insights in Edge Function response")
            return nil
            
        } catch let error as URLError where error.code == .timedOut {
            print("✗ Edge Function request timed out")
            return nil
        } catch {
            print("✗ Edge Function error: \(error.localizedDescription)")
            return nil
        }
    }
}
