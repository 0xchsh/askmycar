import Foundation

enum VehicleAPIError: LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(Int)
    case decodingError
    case noData

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid URL"
        case .invalidResponse: return "Invalid response from server"
        case .httpError(let code): return "HTTP error: \(code)"
        case .decodingError: return "Failed to decode response"
        case .noData: return "No data received"
        }
    }
}

struct VINDecodeResponse: Codable {
    let make: String?
    let model: String?
    let year: Int?
    let trim: String?
}

actor VehicleAPIService {
    private let baseURL = "https://api.vehicledatabases.com/v1"
    private let apiKey = "YOUR_VEHICLE_API_KEY_HERE"
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func decodeVIN(_ vin: String) async throws -> VINDecodeResponse {
        let url = try buildURL(path: "/vin/\(vin)")
        return try await performRequest(url: url)
    }

    func getOwnerManual(vin: String) async throws -> [String: Any] {
        let url = try buildURL(path: "/owner-manual/\(vin)")
        return try await performRawRequest(url: url)
    }

    func getMaintenanceSchedule(vin: String) async throws -> [String: Any] {
        let url = try buildURL(path: "/maintenance-schedule/\(vin)")
        return try await performRawRequest(url: url)
    }

    func getRecalls(vin: String) async throws -> [String: Any] {
        let url = try buildURL(path: "/recalls/\(vin)")
        return try await performRawRequest(url: url)
    }

    func getWarranty(vin: String) async throws -> [String: Any] {
        let url = try buildURL(path: "/warranty/\(vin)")
        return try await performRawRequest(url: url)
    }

    private func buildURL(path: String) throws -> URL {
        guard let url = URL(string: baseURL + path) else {
            throw VehicleAPIError.invalidURL
        }
        return url
    }

    private func performRequest<T: Decodable>(url: URL) async throws -> T {
        var request = URLRequest(url: url)
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw VehicleAPIError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw VehicleAPIError.httpError(httpResponse.statusCode)
        }

        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            throw VehicleAPIError.decodingError
        }
    }

    private func performRawRequest(url: URL) async throws -> [String: Any] {
        var request = URLRequest(url: url)
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw VehicleAPIError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw VehicleAPIError.httpError(httpResponse.statusCode)
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw VehicleAPIError.decodingError
        }

        return json
    }
}
