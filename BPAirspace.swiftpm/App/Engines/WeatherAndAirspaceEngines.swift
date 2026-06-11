import Foundation
import CoreLocation

/// Phase 5: Weather Engine (Single source of atmospheric truth)
actor WeatherEngine {
    static let shared = WeatherEngine()
    
    // Abstracted Wetterdienst/OpenMeteo Models
    private var cachedForecasts: [String: OpenMeteoResponse] = [:]
    
    private init() {}
    
    func fetchAggregatedWeather(for coordinate: CLLocationCoordinate2D) async throws -> AggregatedWeather {
        let openMeteo = try await fetchOpenMeteo(lat: coordinate.latitude, lng: coordinate.longitude)
        
        let windSpeed = openMeteo.hourly.wind_speed_10m?.compactMap { $0 }.first ?? 0
        let windDir = openMeteo.hourly.wind_direction_10m?.compactMap { $0 }.first ?? 0
        let temp = openMeteo.hourly.temperature_2m?.compactMap { $0 }.first ?? 0
        let visibility = openMeteo.hourly.visibility?.compactMap { $0 }.first ?? 0
        
        return AggregatedWeather(
            windSpeed: windSpeed,
            windDirection: windDir,
            temperature: temp,
            visibility: visibility,
            rawMETAR: nil
        )
    }
    
    private func fetchOpenMeteo(lat: Double, lng: Double) async throws -> OpenMeteoResponse {
        let urlString = "https://api.open-meteo.com/v1/forecast?latitude=\(lat)&longitude=\(lng)&hourly=temperature_2m,wind_speed_10m,wind_direction_10m,wind_gusts_10m,cloud_cover,rain,snowfall,visibility,weather_code,relative_humidity_2m&forecast_days=3&timezone=auto"
        guard let url = URL(string: urlString) else { throw URLError(.badURL) }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }
        return try JSONDecoder().decode(OpenMeteoResponse.self, from: data)
    }
}

// Normalized output structure
struct AggregatedWeather {
    let windSpeed: Double
    let windDirection: Int
    let temperature: Double
    let visibility: Double
    let rawMETAR: String?
}

/// Phase 3: Airspace Engine
class AirspaceEngine: ObservableObject {
    static let shared = AirspaceEngine()
    
    @Published var activeFIRs: [String] = []
    
    func loadFIRBoundaries() {
        // Loads GeoJSON airspace bounds
    }
}
