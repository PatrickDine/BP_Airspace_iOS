import Foundation
import CoreLocation

// MARK: - Offline Cache Manager
class OfflineCacheManager {
    static let shared = OfflineCacheManager()
    private let fileManager = FileManager.default
    
    private var cacheDirectory: URL {
        let paths = fileManager.urls(for: .documentDirectory, in: .userDomainMask)
        let cacheDir = paths[0].appendingPathComponent("WeatherCache")
        if !fileManager.fileExists(atPath: cacheDir.path) {
            try? fileManager.createDirectory(at: cacheDir, withIntermediateDirectories: true)
        }
        return cacheDir
    }
    
    func save<T: Encodable>(_ object: T, for key: String) {
        let url = cacheDirectory.appendingPathComponent("\(key).json")
        do {
            let data = try JSONEncoder().encode(object)
            try data.write(to: url)
            print("Saved offline cache for \(key)")
        } catch {
            print("Failed to save cache for \(key): \(error)")
        }
    }
    
    func load<T: Decodable>(for key: String, type: T.Type) -> T? {
        let url = cacheDirectory.appendingPathComponent("\(key).json")
        guard let data = try? Data(contentsOf: url) else { return nil }
        do {
            let object = try JSONDecoder().decode(type, from: data)
            print("Loaded offline cache for \(key)")
            return object
        } catch {
            print("Failed to load cache for \(key): \(error)")
            return nil
        }
    }
}

// MARK: - Open-Meteo Models
struct OpenMeteoResponse: Codable {
    let latitude: Double
    let longitude: Double
    let hourly: HourlyData
}

struct HourlyData: Codable {
    let time: [String]?
    let temperature_2m: [Double?]?
    let wind_speed_10m: [Double?]?
    let wind_direction_10m: [Int?]?
    let wind_gusts_10m: [Double?]?
    let cloud_cover: [Int?]?
    let rain: [Double?]?
    let snowfall: [Double?]?
    let visibility: [Double?]?
    let weather_code: [Int?]?
    let relative_humidity_2m: [Int?]?
}

// MARK: - Geocoding Models
struct GeocodingResponse: Codable {
    let results: [GeocodingResult]?
}

struct GeocodingResult: Codable, Identifiable {
    let id: Int
    let name: String
    let latitude: Double
    let longitude: Double
    let country: String?
    let admin1: String?
}

// MARK: - App State Models
struct FlightRoute: Identifiable {
    let id = UUID()
    var departure: String
    var arrival: String
    var coordinates: [CLLocationCoordinate2D]
}

enum WeatherLayer: String, CaseIterable, Identifiable {
    case radar = "Radar"
    case wind = "Wind"
    case clouds = "Clouds"
    case temperature = "Temp"
    case rain = "Rain"
    case snow = "Snow"
    case visibility = "Visibility"
    case condition = "Condition"
    
    var id: String { self.rawValue }
    
    var iconName: String {
        switch self {
        case .radar: return "cloud.rain.fill"
        case .wind: return "wind"
        case .clouds: return "cloud.fill"
        case .temperature: return "thermometer"
        case .rain: return "drop.fill"
        case .snow: return "snowflake"
        case .visibility: return "eye.fill"
        case .condition: return "sun.max.fill"
        }
    }
}

// MARK: - View Model
class WeatherViewModel: ObservableObject {
    @Published var activeLayers: Set<WeatherLayer> = []
    @Published var weatherData: OpenMeteoResponse?
    @Published var isLoading: Bool = false
    @Published var forecastIndex: Int = 0 // For the bottom slider
    @Published var selectedLocation: GeocodingResult?
    
    // Cached route mimicking original app
    @Published var activeRoute: FlightRoute? = FlightRoute(
        departure: "Banjul, The Gambia",
        arrival: "Algiers, Algeria",
        coordinates: [
            CLLocationCoordinate2D(latitude: 13.33, longitude: -16.66), // Banjul
            CLLocationCoordinate2D(latitude: 36.75, longitude: 3.05)    // Algiers
        ]
    )
    
    func fetchWeather(lat: Double, lng: Double) {
        let cacheKey = "weather_\(String(format: "%.2f", lat))_\(String(format: "%.2f", lng))"
        
        // Load from cache first for fast offline capability
        if let cached = OfflineCacheManager.shared.load(for: cacheKey, type: OpenMeteoResponse.self) {
            self.weatherData = cached
        }
        
        isLoading = true
        let urlString = "https://api.open-meteo.com/v1/forecast?latitude=\(lat)&longitude=\(lng)&hourly=temperature_2m,wind_speed_10m,wind_direction_10m,wind_gusts_10m,cloud_cover,rain,snowfall,visibility,weather_code,relative_humidity_2m&forecast_days=3&timezone=auto"
        
        guard let url = URL(string: urlString) else { return }
        
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if let httpResponse = response as? HTTPURLResponse, !(200...299).contains(httpResponse.statusCode) {
                    print("HTTP Error \(httpResponse.statusCode)")
                    HapticEngine.shared.error()
                    return
                }
                
                guard let data = data else {
                    print("Network failed. Continuing with offline data if available.")
                    HapticEngine.shared.error()
                    return
                }
                do {
                    let decoded = try JSONDecoder().decode(OpenMeteoResponse.self, from: data)
                    self?.weatherData = decoded
                    OfflineCacheManager.shared.save(decoded, for: cacheKey)
                    
                    // Hook into BP Airspace Engines
                    if let firstWind = decoded.hourly.wind_speed_10m?.compactMap({ $0 }).first,
                       let firstTemp = decoded.hourly.temperature_2m?.compactMap({ $0 }).first,
                       let firstVis = decoded.hourly.visibility?.compactMap({ $0 }).first,
                       let firstDir = decoded.hourly.wind_direction_10m?.compactMap({ $0 }).first {
                        
                        let agg = AggregatedWeather(
                            windSpeed: firstWind,
                            windDirection: firstDir,
                            temperature: firstTemp,
                            visibility: firstVis,
                            rawMETAR: nil
                        )
                        
                        HazardEngine.shared.analyze(weather: agg)
                        TEMEngine.shared.generateTEM(from: HazardEngine.shared.activeHazards)
                        FatigueEngine.shared.calculateFatigue(hazards: HazardEngine.shared.activeHazards, flightDurationHours: 4.5)
                        AICopilotEngine.shared.generateBriefing(weather: agg, hazards: HazardEngine.shared.activeHazards)
                    }
                    
                } catch {
                    print("Failed to decode weather data: \(error)")
                }
            }
        }.resume()
    }
    
    func toggleLayer(_ layer: WeatherLayer) {
        if activeLayers.contains(layer) {
            activeLayers.remove(layer)
        } else {
            activeLayers.insert(layer)
        }
    }
}
