import Foundation
import SwiftUI

// MARK: - Saved City (ported from TakefiveInteractive/WeatherMap)
struct SavedCity: Codable, Identifiable, Equatable {
    let id: Int
    let name: String
    let latitude: Double
    let longitude: Double
    let country: String?
    let admin1: String?

    /// Country flag emoji from country code (ISO 3166-1 alpha-2)
    var flagEmoji: String {
        guard let code = country, code.count == 2 else { return "🌍" }
        let base: UInt32 = 127397
        var emoji = ""
        for scalar in code.uppercased().unicodeScalars {
            if let s = Unicode.Scalar(base + scalar.value) { emoji.append(Character(s)) }
        }
        return emoji.isEmpty ? "🌍" : emoji
    }

    init(from result: GeocodingResult) {
        self.id        = result.id
        self.name      = result.name
        self.latitude  = result.latitude
        self.longitude = result.longitude
        self.country   = result.country
        self.admin1    = result.admin1
    }
}

// MARK: - City Store
class CityStore: ObservableObject {
    static let shared = CityStore()
    private let key = "saved_cities_v1"

    @Published var cities: [SavedCity] = []

    private init() { load() }

    func add(_ city: SavedCity) {
        guard !cities.contains(where: { $0.id == city.id }) else { return }
        cities.append(city)
        persist()
    }

    func remove(at offsets: IndexSet) {
        cities.remove(atOffsets: offsets)
        persist()
    }

    func remove(id: Int) {
        cities.removeAll { $0.id == id }
        persist()
    }

    func contains(id: Int) -> Bool { cities.contains { $0.id == id } }

    private func persist() {
        if let data = try? JSONEncoder().encode(cities) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: key),
              let decoded = try? JSONDecoder().decode([SavedCity].self, from: data) else { return }
        cities = decoded
    }
}
