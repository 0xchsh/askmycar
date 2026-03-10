import Foundation

actor SupabaseService {
    private let baseURL: String
    private let apiKey: String
    private let session: URLSession
    private let tableName = "vehicle_cache"

    /// Recalls can change; re-fetch after 30 days.
    private let recallCacheDuration: TimeInterval = 30 * 24 * 60 * 60

    init(session: URLSession = .shared) {
        let secrets = Bundle.main.path(forResource: "Secrets", ofType: "plist")
            .flatMap { NSDictionary(contentsOfFile: $0) as? [String: Any] }

        self.baseURL = (secrets?["SUPABASE_URL"] as? String) ?? ""
        self.apiKey = (secrets?["SUPABASE_ANON_KEY"] as? String) ?? ""
        self.session = session
    }

    var isConfigured: Bool {
        !baseURL.isEmpty && !apiKey.isEmpty
    }

    // MARK: - Fetch cached data

    /// Returns the cached JSON `Data` for the given key+endpoint, or `nil` on miss / expiry / error.
    func fetchCachedVehicleData(cacheKey: String, endpoint: String) async -> Data? {
        guard isConfigured else { return nil }

        let encodedKey = cacheKey.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? cacheKey
        let encodedEndpoint = endpoint.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? endpoint

        guard let url = URL(string: "\(baseURL)/rest/v1/\(tableName)?cache_key=eq.\(encodedKey)&endpoint=eq.\(encodedEndpoint)&select=response_json,updated_at") else {
            return nil
        }

        var request = URLRequest(url: url)
        request.setValue(apiKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        guard let (data, response) = try? await session.data(for: request),
              let http = response as? HTTPURLResponse,
              (200...299).contains(http.statusCode) else {
            return nil
        }

        // Supabase returns an array of rows
        guard let rows = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]],
              let row = rows.first else {
            return nil
        }

        // For recalls, check if cache is stale (>30 days)
        if endpoint == "recalls", let updatedStr = row["updated_at"] as? String {
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let updatedAt = formatter.date(from: updatedStr),
               Date().timeIntervalSince(updatedAt) > recallCacheDuration {
                return nil // stale
            }
        }

        // Extract response_json and re-serialize to Data
        guard let responseJSON = row["response_json"] else { return nil }
        return try? JSONSerialization.data(withJSONObject: responseJSON)
    }

    // MARK: - Store cached data

    /// Upserts a cache row. Fires-and-forgets on error.
    func storeCachedVehicleData(cacheKey: String, endpoint: String, json: Data) async {
        guard isConfigured else { return }

        guard let url = URL(string: "\(baseURL)/rest/v1/\(tableName)") else { return }

        // Parse the raw JSON so we can embed it in the upsert payload
        guard let jsonObject = try? JSONSerialization.jsonObject(with: json) else { return }

        let now = ISO8601DateFormatter().string(from: Date())
        let payload: [String: Any] = [
            "cache_key": cacheKey,
            "endpoint": endpoint,
            "response_json": jsonObject,
            "created_at": now,
            "updated_at": now
        ]

        guard let body = try? JSONSerialization.data(withJSONObject: payload) else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        // Upsert: on conflict with (cache_key, endpoint), update response_json + updated_at
        request.setValue("resolution=merge-duplicates", forHTTPHeaderField: "Prefer")
        request.httpBody = body

        _ = try? await session.data(for: request)
    }

    // MARK: - Question tracking

    /// Log a user question anonymously, keyed by make/model/year.
    func logQuestion(make: String, model: String, year: Int, question: String) async {
        guard isConfigured else { return }
        guard let url = URL(string: "\(baseURL)/rest/v1/chat_questions") else { return }

        let payload: [String: Any] = [
            "make": make,
            "model": model,
            "year": year,
            "question": question
        ]

        guard let body = try? JSONSerialization.data(withJSONObject: payload) else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = body

        _ = try? await session.data(for: request)
    }

    /// Fetch the most common questions for a given make/model.
    func fetchPopularQuestions(make: String, model: String, limit: Int = 5) async -> [String] {
        guard isConfigured else { return [] }

        let encodedMake = make.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? make
        let encodedModel = model.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? model

        // Use PostgREST RPC — we'll call a database function
        guard let url = URL(string: "\(baseURL)/rest/v1/rpc/popular_questions") else { return [] }

        let payload: [String: Any] = [
            "p_make": encodedMake,
            "p_model": encodedModel,
            "p_limit": limit
        ]

        guard let body = try? JSONSerialization.data(withJSONObject: payload) else { return [] }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = body

        guard let (data, response) = try? await session.data(for: request),
              let http = response as? HTTPURLResponse,
              (200...299).contains(http.statusCode) else {
            return []
        }

        guard let rows = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
            return []
        }

        return rows.compactMap { $0["question"] as? String }
    }
}
