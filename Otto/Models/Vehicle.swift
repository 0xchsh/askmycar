import Foundation
import SwiftData

@Model
final class Vehicle {
    var id: UUID
    var vin: String?
    var make: String
    var model: String
    var year: Int
    var trim: String?
    var nickname: String?
    var exteriorColor: String?
    var isActive: Bool
    var createdAt: Date

    // Cached vehicle images (Vehicle Imagery API — signed URLs expire in 7 days)
    // JSON dict keyed by view name, e.g. {"right":"https://...","front":"https://..."}
    var cachedImageURLs: String?
    var imageURLExpiry: Date?
    var resolvedVariant: String?
    var resolvedTrim: String?

    // Cached API data (persisted so we don't re-fetch)
    var cachedOwnerManualURL: String?
    var cachedMaintenanceJSON: String?
    var cachedRecallsJSON: String?
    var cachedWarrantyJSON: String?
    var vehicleDataLastFetched: Date?

    /// Complete vehicle profile document fed to the LLM as context.
    /// Generated once from vehicle details + API data, then cached.
    var cachedProfileDocument: String?

    @Relationship(deleteRule: .cascade, inverse: \ChatSession.vehicle)
    var sessions: [ChatSession]

    var imagesExpired: Bool {
        (imageURLExpiry ?? .distantPast) <= Date()
    }

    func cachedImageURL(for view: String) -> String? {
        guard !imagesExpired,
              let json = cachedImageURLs,
              let data = json.data(using: .utf8),
              let dict = try? JSONSerialization.jsonObject(with: data) as? [String: String] else {
            return nil
        }
        return dict[view]
    }

    func setCachedImageURL(_ url: String, for view: String) {
        var dict: [String: String] = [:]
        if let json = cachedImageURLs,
           let data = json.data(using: .utf8),
           let existing = try? JSONSerialization.jsonObject(with: data) as? [String: String] {
            dict = existing
        }
        dict[view] = url
        if let data = try? JSONSerialization.data(withJSONObject: dict),
           let json = String(data: data, encoding: .utf8) {
            cachedImageURLs = json
        }
    }

    func clearCachedImageURLs() {
        cachedImageURLs = nil
        imageURLExpiry = nil
    }

    var topBarName: String {
        if let nickname, !nickname.isEmpty { return nickname }
        if !make.isEmpty { return make }
        return "My Vehicle"
    }

    var displayName: String {
        let parts = [String(year), make, model].filter { !$0.isEmpty }
        return parts.joined(separator: " ")
    }

    var fullDisplayName: String {
        if let trim {
            return "\(year) \(make) \(model) \(trim)"
        }
        return displayName
    }

    init(make: String, model: String, year: Int, vin: String? = nil, trim: String? = nil, nickname: String? = nil, exteriorColor: String? = nil) {
        self.id = UUID()
        self.make = make
        self.model = model
        self.year = year
        self.vin = vin
        self.trim = trim
        self.nickname = nickname
        self.exteriorColor = exteriorColor
        self.isActive = true
        self.createdAt = Date()
        self.sessions = []
    }
}
