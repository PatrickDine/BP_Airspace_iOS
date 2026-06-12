import Foundation
import CoreLocation
import SwiftUI

// MARK: - Offline Cache Manager
class OfflineCacheManager {
    static let shared = OfflineCacheManager()
    private let fileManager = FileManager.default

    private var cacheDirectory: URL {
        let paths = fileManager.urls(for: .documentDirectory, in: .userDomainMask)
        let dir = paths[0].appendingPathComponent("WeatherCache")
        if !fileManager.fileExists(atPath: dir.path) {
            try? fileManager.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }

    func save<T: Encodable>(_ object: T, for key: String) {
        let url = cacheDirectory.appendingPathComponent("\(key).json")
        if let data = try? JSONEncoder().encode(object) { try? data.write(to: url) }
    }

    func load<T: Decodable>(for key: String, type: T.Type) -> T? {
        let url = cacheDirectory.appendingPathComponent("\(key).json")
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }
}

// MARK: - Open-Meteo Response Models
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
    let surface_pressure: [Double?]?
    let apparent_temperature: [Double?]?   // Feels Like (Rain port)
    let uv_index: [Double?]?               // UV Index   (Rain port)
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

// MARK: - Processed Hourly Data Point
struct WeatherDataPoint: Identifiable {
    let id = UUID()
    let time: Date
    let temperature: Double      // °C
    let windSpeed: Double        // km/h
    let windDirection: Int       // degrees FROM
    let windGusts: Double        // km/h
    let cloudCover: Int          // %
    let rain: Double             // mm/h
    let snowfall: Double         // cm/h
    let visibility: Double       // metres
    let humidity: Int            // %
    let weatherCode: Int         // WMO
    let pressure: Double         // hPa
    let apparentTemp: Double     // Feels Like °C  (Rain port)
    let uvIndex: Double          // UV Index       (Rain port)
}

// MARK: - Grid Point for Map Overlay
struct GridWeatherPoint: Identifiable {
    let id = UUID()
    var lat: Double
    var lng: Double
    var temperature: Double = 0
    var windSpeed: Double = 0
    var windDirection: Int = 0
    var rain: Double = 0
    var cloudCover: Int = 0
    var snowfall: Double = 0
    var visibility: Double = 10000
    var humidity: Int = 50
    var pressure: Double = 1013
}

// MARK: - Waypoint Safety
enum WaypointSafetyLevel {
    case safe, caution, danger, unknown
    var color: Color {
        switch self {
        case .safe: return .green
        case .caution: return .yellow
        case .danger: return .red
        case .unknown: return .gray
        }
    }
}

// MARK: - Waypoint Condition
struct WaypointCondition: Identifiable {
    let id = UUID()
    let name: String
    let coordinate: CLLocationCoordinate2D
    var weather: WeatherDataPoint?
    var safetyLevel: WaypointSafetyLevel = .unknown
}

// MARK: - Flight Route
struct FlightRoute: Identifiable {
    let id = UUID()
    var departure: String
    var arrival: String
    var coordinates: [CLLocationCoordinate2D]
    var waypoints: [WaypointCondition] = []
}

// MARK: - Altitude Level
enum AltitudeLevel: String, CaseIterable {
    case surface = "SFC"
    case fl050   = "FL050"
    case fl100   = "FL100"
    case fl180   = "FL180"
    case fl300   = "FL300"
}

// MARK: - Weather Layer
enum WeatherLayer: String, CaseIterable, Identifiable {
    case wind        = "Wind"
    case temperature = "Temp"
    case rain        = "Rain"
    case clouds      = "Clouds"
    case snow        = "Snow"
    case visibility  = "Visibility"
    case humidity    = "Humidity"
    case pressure    = "Pressure"

    var id: String { rawValue }

    var iconName: String {
        switch self {
        case .wind:        return "wind"
        case .temperature: return "thermometer.medium"
        case .rain:        return "cloud.rain.fill"
        case .clouds:      return "cloud.fill"
        case .snow:        return "snowflake"
        case .visibility:  return "eye.fill"
        case .humidity:    return "humidity.fill"
        case .pressure:    return "gauge.medium"
        }
    }

    var accentColor: Color {
        switch self {
        case .wind:        return Color(hue: 0.55, saturation: 0.75, brightness: 0.95)
        case .temperature: return .orange
        case .rain:        return Color(hue: 0.60, saturation: 0.80, brightness: 0.90)
        case .clouds:      return .gray
        case .snow:        return Color(hue: 0.57, saturation: 0.30, brightness: 1.00)
        case .visibility:  return .yellow
        case .humidity:    return .teal
        case .pressure:    return .purple
        }
    }

    var unit: String {
        switch self {
        case .wind:        return "km/h"
        case .temperature: return "°C"
        case .rain:        return "mm"
        case .clouds:      return "%"
        case .snow:        return "cm"
        case .visibility:  return "km"
        case .humidity:    return "%"
        case .pressure:    return "hPa"
        }
    }
}

// MARK: - View Model
class WeatherViewModel: ObservableObject {
    // Single active layer (Windy radio-button style)
    @Published var activeLayer: WeatherLayer = .wind

    // Full 14-day response
    @Published var weatherData: OpenMeteoResponse?

    // Processed per-hour data
    @Published var hourlyDataPoints: [WeatherDataPoint] = []

    // 3×3 grid for map colour overlay
    @Published var gridDataPoints: [GridWeatherPoint] = []

    // Air Quality (Rain port)
    @Published var airQuality: AirQualityData?

    // State
    @Published var isLoading: Bool = false
    @Published var forecastIndex: Int = 0
    @Published var selectedLocation: GeocodingResult?
    @Published var tappedCoordinate: CLLocationCoordinate2D?
    @Published var activeRoute: FlightRoute?
    @Published var isAnimatingForecast: Bool = false
    @Published var selectedAltitude: AltitudeLevel = .surface
    @Published var mapSpanDelta: Double = 20.0   // degrees, updated live by MapView

    private var animationTimer: Timer?
    private var gridWorkItem: DispatchWorkItem?

    // Convenience: the weather at the currently selected forecast step
    var currentDataPoint: WeatherDataPoint? {
        guard !hourlyDataPoints.isEmpty else { return nil }
        return hourlyDataPoints[min(forecastIndex, hourlyDataPoints.count - 1)]
    }

    // MARK: - Init
    init() {
        let defaults = UserDefaults.standard
        let homeName = defaults.string(forKey: "homeAirportName") ?? ""
        let homeLat  = defaults.double(forKey: "homeAirportLat")
        let homeLng  = defaults.double(forKey: "homeAirportLng")

        if !homeName.isEmpty && homeLat != 0.0 {
            self.selectedLocation = GeocodingResult(
                id: 0, name: homeName,
                latitude: homeLat, longitude: homeLng,
                country: nil, admin1: "Home"
            )
            fetchWeather(lat: homeLat, lng: homeLng)
            fetchGridWeather(centerLat: homeLat, centerLng: homeLng, span: 20.0)
        }
    }

    // MARK: - Fetch Full 7-Day Weather
    func fetchWeather(lat: Double, lng: Double) {
        let key = "weather_\(String(format: "%.2f", lat))_\(String(format: "%.2f", lng))"

        if let cached = OfflineCacheManager.shared.load(for: key, type: OpenMeteoResponse.self) {
            weatherData = cached
            hourlyDataPoints = processHourlyData(cached)
        }

        isLoading = true
        let fields = "temperature_2m,wind_speed_10m,wind_direction_10m,wind_gusts_10m,cloud_cover,rain,snowfall,visibility,weather_code,relative_humidity_2m,surface_pressure,apparent_temperature,uv_index"
        let urlStr = "https://api.open-meteo.com/v1/forecast?latitude=\(lat)&longitude=\(lng)&hourly=\(fields)&forecast_days=14&timezone=auto"
        guard let url = URL(string: urlStr) else { return }

        URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
            guard let self = self, let data = data,
                  let decoded = try? JSONDecoder().decode(OpenMeteoResponse.self, from: data) else {
                DispatchQueue.main.async { self?.isLoading = false }
                return
            }
            DispatchQueue.main.async {
                self.isLoading = false
                self.weatherData = decoded
                self.hourlyDataPoints = self.processHourlyData(decoded)
                OfflineCacheManager.shared.save(decoded, for: key)

                // Fire engine hooks
                if let pt = self.hourlyDataPoints.first {
                    let agg = AggregatedWeather(windSpeed: pt.windSpeed, windDirection: pt.windDirection,
                                                temperature: pt.temperature, visibility: pt.visibility, rawMETAR: nil)
                    HazardEngine.shared.analyze(weather: agg)
                    TEMEngine.shared.generateTEM(from: HazardEngine.shared.activeHazards)
                    FatigueEngine.shared.calculateFatigue(hazards: HazardEngine.shared.activeHazards, flightDurationHours: 4.5)
                    AICopilotEngine.shared.generateBriefing(weather: agg, hazards: HazardEngine.shared.activeHazards)
                }

                // Fetch Air Quality (Rain port)
                AirQualityEngine.shared.fetch(lat: lat, lng: lng) { [weak self] aq in
                    self?.airQuality = aq
                }
            }
        }.resume()
    }

    // MARK: - Process Raw API → [WeatherDataPoint]
    func processHourlyData(_ r: OpenMeteoResponse) -> [WeatherDataPoint] {
        guard let times = r.hourly.time else { return [] }
        let fmt = ISO8601DateFormatter()
        return times.enumerated().compactMap { (i, ts) in
            let clean = ts.count == 16 ? ts + ":00Z" : ts
            guard let date = fmt.date(from: clean) else { return nil }
            return WeatherDataPoint(
                time:        date,
                temperature: safeDouble(r.hourly.temperature_2m,       at: i),
                windSpeed:   safeDouble(r.hourly.wind_speed_10m,        at: i),
                windDirection: safeInt(r.hourly.wind_direction_10m,     at: i),
                windGusts:   safeDouble(r.hourly.wind_gusts_10m,        at: i),
                cloudCover:  safeInt(r.hourly.cloud_cover,              at: i),
                rain:        safeDouble(r.hourly.rain,                  at: i),
                snowfall:    safeDouble(r.hourly.snowfall,              at: i),
                visibility:  safeDouble(r.hourly.visibility,            at: i, default: 10000),
                humidity:    safeInt(r.hourly.relative_humidity_2m,     at: i),
                weatherCode: safeInt(r.hourly.weather_code,             at: i),
                pressure:    safeDouble(r.hourly.surface_pressure,      at: i, default: 1013),
                apparentTemp: safeDouble(r.hourly.apparent_temperature, at: i),
                uvIndex:     safeDouble(r.hourly.uv_index,              at: i)
            )
        }
    }

    private func safeDouble(_ arr: [Double?]?, at i: Int, default def: Double = 0) -> Double {
        guard let arr = arr, i < arr.count else { return def }
        return arr[i] ?? def
    }
    private func safeInt(_ arr: [Int?]?, at i: Int, default def: Int = 0) -> Int {
        guard let arr = arr, i < arr.count else { return def }
        return arr[i] ?? def
    }

    // MARK: - Grid Weather Fetch (3×3 around viewport)
    func fetchGridWeather(centerLat: Double, centerLng: Double, span: Double) {
        gridWorkItem?.cancel()
        let work = DispatchWorkItem { [weak self] in
            self?.performGridFetch(centerLat: centerLat, centerLng: centerLng, span: span)
        }
        gridWorkItem = work
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.6, execute: work)
    }

    private func performGridFetch(centerLat: Double, centerLng: Double, span: Double) {
        let step = span / 3.0
        let offsets: [(Double, Double)] = [
            (-step, -step), (-step, 0), (-step, step),
            (0,     -step), (0,     0), (0,     step),
            (step,  -step), (step,  0), (step,  step)
        ]
        let group = DispatchGroup()
        var results: [GridWeatherPoint] = []
        let lock = NSLock()

        for (dLat, dLng) in offsets {
            let lat = max(-89.9, min(89.9, centerLat + dLat))
            let lng = centerLng + dLng
            group.enter()
            let fields = "temperature_2m,wind_speed_10m,wind_direction_10m,rain,cloud_cover,snowfall,visibility,relative_humidity_2m,surface_pressure"
            let urlStr = "https://api.open-meteo.com/v1/forecast?latitude=\(lat)&longitude=\(lng)&hourly=\(fields)&forecast_days=1&timezone=UTC"
            guard let url = URL(string: urlStr) else { group.leave(); continue }

            URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
                defer { group.leave() }
                guard let self = self, let data = data,
                      let decoded = try? JSONDecoder().decode(OpenMeteoResponse.self, from: data) else { return }
                let h = decoded.hourly
                var pt = GridWeatherPoint(lat: lat, lng: lng)
                pt.temperature   = self.safeDouble(h.temperature_2m,        at: self.forecastIndex)
                pt.windSpeed     = self.safeDouble(h.wind_speed_10m,         at: self.forecastIndex)
                pt.windDirection = self.safeInt(h.wind_direction_10m,        at: self.forecastIndex)
                pt.rain          = self.safeDouble(h.rain,                   at: self.forecastIndex)
                pt.cloudCover    = self.safeInt(h.cloud_cover,               at: self.forecastIndex)
                pt.snowfall      = self.safeDouble(h.snowfall,               at: self.forecastIndex)
                pt.visibility    = self.safeDouble(h.visibility,             at: self.forecastIndex, default: 10000)
                pt.humidity      = self.safeInt(h.relative_humidity_2m,      at: self.forecastIndex)
                pt.pressure      = self.safeDouble(h.surface_pressure,       at: self.forecastIndex, default: 1013)
                lock.lock(); results.append(pt); lock.unlock()
            }.resume()
        }

        group.notify(queue: .main) { [weak self] in
            self?.gridDataPoints = results
        }
    }

    // MARK: - Forecast Animation
    func startForecastAnimation() {
        isAnimatingForecast = true
        animationTimer = Timer.scheduledTimer(withTimeInterval: 0.35, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            let max = max(self.hourlyDataPoints.count - 1, 71)
            self.forecastIndex = self.forecastIndex >= max ? 0 : self.forecastIndex + 1
        }
    }

    func stopForecastAnimation() {
        isAnimatingForecast = false
        animationTimer?.invalidate()
        animationTimer = nil
    }

    // MARK: - Route Planning
    func planRoute(departure: String, arrival: String) {
        let group = DispatchGroup()
        var depResult: GeocodingResult?
        var arrResult: GeocodingResult?

        group.enter()
        geocode(query: departure) { r in depResult = r; group.leave() }

        group.enter()
        geocode(query: arrival) { r in arrResult = r; group.leave() }

        group.notify(queue: .main) { [weak self] in
            guard let self = self, let dep = depResult, let arr = arrResult else { return }
            let depC = CLLocationCoordinate2D(latitude: dep.latitude,  longitude: dep.longitude)
            let arrC = CLLocationCoordinate2D(latitude: arr.latitude,  longitude: arr.longitude)
            let steps = 6
            var coords: [CLLocationCoordinate2D] = []
            var waypoints: [WaypointCondition] = []
            for i in 0...steps {
                let t = Double(i) / Double(steps)
                let lat = depC.latitude  + (arrC.latitude  - depC.latitude)  * t
                let lng = depC.longitude + (arrC.longitude - depC.longitude) * t
                let coord = CLLocationCoordinate2D(latitude: lat, longitude: lng)
                coords.append(coord)
                let name = i == 0 ? dep.name : (i == steps ? arr.name : "WPT\(i)")
                waypoints.append(WaypointCondition(name: name, coordinate: coord))
            }
            self.activeRoute = FlightRoute(departure: dep.name, arrival: arr.name,
                                           coordinates: coords, waypoints: waypoints)
            self.fetchWaypointWeather()
        }
    }

    private func fetchWaypointWeather() {
        guard let route = activeRoute else { return }
        let group = DispatchGroup()
        var weatherMap: [Int: WeatherDataPoint] = [:]
        let lock = NSLock()
        let fields = "temperature_2m,wind_speed_10m,wind_direction_10m,wind_gusts_10m,cloud_cover,rain,snowfall,visibility,weather_code,relative_humidity_2m,surface_pressure"

        for i in route.waypoints.indices {
            let lat = route.waypoints[i].coordinate.latitude
            let lng = route.waypoints[i].coordinate.longitude
            let urlStr = "https://api.open-meteo.com/v1/forecast?latitude=\(lat)&longitude=\(lng)&hourly=\(fields)&forecast_days=1&timezone=UTC"
            guard let url = URL(string: urlStr) else { continue }
            group.enter()
            URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
                defer { group.leave() }
                guard let self = self, let data = data,
                      let decoded = try? JSONDecoder().decode(OpenMeteoResponse.self, from: data),
                      let pt = self.processHourlyData(decoded).first else { return }
                lock.lock(); weatherMap[i] = pt; lock.unlock()
            }.resume()
        }

        group.notify(queue: .main) { [weak self] in
            guard var updated = self?.activeRoute else { return }
            for i in updated.waypoints.indices {
                if let w = weatherMap[i] {
                    updated.waypoints[i].weather = w
                    updated.waypoints[i].safetyLevel = w.visibility < 3000 || w.windSpeed > 80 || w.rain > 10
                        ? .danger
                        : w.visibility < 5000 || w.windSpeed > 50 || w.rain > 5
                        ? .caution
                        : .safe
                }
            }
            self?.activeRoute = updated
        }
    }

    private func geocode(query: String, completion: @escaping (GeocodingResult?) -> Void) {
        let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let urlStr = "https://geocoding-api.open-meteo.com/v1/search?name=\(encoded)&count=1&language=en&format=json"
        guard let url = URL(string: urlStr) else { completion(nil); return }
        URLSession.shared.dataTask(with: url) { data, _, _ in
            DispatchQueue.main.async {
                guard let data = data,
                      let r = try? JSONDecoder().decode(GeocodingResponse.self, from: data) else {
                    completion(nil); return
                }
                completion(r.results?.first)
            }
        }.resume()
    }

    // Legacy toggle kept for any remaining call sites
    func toggleLayer(_ layer: WeatherLayer) { activeLayer = layer }
}
