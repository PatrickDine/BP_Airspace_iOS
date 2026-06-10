import Foundation
import CoreLocation

/// WIE is the single source of truth for all weather data in BP Airspace.
/// No UI or other engines should fetch weather directly.
actor WeatherIntelligenceEngine {
    static let shared = WeatherIntelligenceEngine()
    
    // Aggregated Data States
    private var cachedOpenMeteo: OpenMeteoResponse?
    private var cachedMETARs: [String: String] = [:] // Airport ICAO -> METAR string
    
    private init() {}
    
    /// Main fetch pipeline merging all providers
    func fetchAggregatedIntelligence(for coordinate: CLLocationCoordinate2D) async throws -> AggregatedWeather {
        // 1. Fetch OpenMeteo forecast (mimics Wetterdienst abstraction)
        let openMeteo = try await fetchOpenMeteo(lat: coordinate.latitude, lng: coordinate.longitude)
        self.cachedOpenMeteo = openMeteo
        
        // 2. Fetch nearest METAR/TAF (simulated for now)
        let metar = "METAR KLAX 102153Z 27010KT 10SM CLR 22/13 A2992"
        
        // 3. Normalize into BP Airspace standard format
        return normalize(openMeteo: openMeteo, metar: metar)
    }
    
    // Private fetching
    private func fetchOpenMeteo(lat: Double, lng: Double) async throws -> OpenMeteoResponse {
        let urlString = "https://api.open-meteo.com/v1/forecast?latitude=\(lat)&longitude=\(lng)&hourly=temperature_2m,wind_speed_10m,wind_direction_10m,wind_gusts_10m,cloud_cover,rain,snowfall,visibility,weather_code,relative_humidity_2m&forecast_days=3&timezone=auto"
        guard let url = URL(string: urlString) else { throw URLError(.badURL) }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        return try JSONDecoder().decode(OpenMeteoResponse.self, from: data)
    }
    
    // Normalization
    private func normalize(openMeteo: OpenMeteoResponse, metar: String?) -> AggregatedWeather {
        // Find current hour index
        let formatter = ISO8601DateFormatter()
        // Simplify for architecture demo
        let windSpeed = openMeteo.hourly.wind_speed_10m.first ?? 0
        let windDir = openMeteo.hourly.wind_direction_10m.first ?? 0
        let temp = openMeteo.hourly.temperature_2m.first ?? 0
        let visibility = openMeteo.hourly.visibility.first ?? 0
        
        return AggregatedWeather(
            windSpeed: windSpeed,
            windDirection: windDir,
            temperature: temp,
            visibility: visibility,
            rawMETAR: metar
        )
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
