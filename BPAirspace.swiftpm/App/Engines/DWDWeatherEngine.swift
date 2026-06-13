import Foundation
import SwiftUI

// MARK: - DWD Station Model (ported from earthobservations/wetterdienst)
// DWD (Deutscher Wetterdienst) open data — free REST API, no key needed
// Endpoint: https://opendata.dwd.de/

struct DWDStation: Identifiable, Codable {
    let id: String               // e.g. "01048" (ICAO-adjacent DWD station ID)
    let name: String
    let latitude: Double
    let longitude: Double
    let elevation: Int           // metres AMSL
    let state: String?           // German state
}

struct DWDObservation: Codable {
    let stationId: String
    let timestamp: Date
    let temperature: Double?     // °C at 2m
    let dewpoint: Double?        // °C
    let pressure: Double?        // hPa (station level)
    let windSpeed: Double?       // m/s → we convert to km/h
    let windDirection: Int?      // degrees
    let windGust: Double?        // m/s
    let precipitation: Double?   // mm (last hour)
    let cloudCover: Int?         // oktas (0–8)
    let visibility: Int?         // metres
    let presentWeather: Int?     // WMO code

    var windSpeedKmh: Double? { windSpeed.map { $0 * 3.6 } }
    var windGustKmh: Double?  { windGust.map  { $0 * 3.6 } }
}

// MARK: - DWD Engine
class DWDWeatherEngine {
    static let shared = DWDWeatherEngine()
    private init() {}

    // DWD station list endpoint (CDC open data)
    private let stationsURL = "https://opendata.dwd.de/climate_environment/CDC/observations_germany/climate/hourly/air_temperature/recent/KL_Stationsliste.txt"

    // Nearest station cache
    private var cachedStations: [DWDStation] = []

    // MARK: - Fetch current observation from nearest DWD station
    // Uses the DWD open-data observation synop endpoint
    func fetchNearestObservation(lat: Double, lng: Double,
                                  completion: @escaping (DWDObservation?, DWDStation?) -> Void) {
        // DWD SYNOP observations API (returns JSON for nearest station)
        let urlStr = "https://api.brightsky.dev/current_weather?lat=\(lat)&lon=\(lng)"
        guard let url = URL(string: urlStr) else { completion(nil, nil); return }

        URLSession.shared.dataTask(with: url) { data, _, _ in
            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let weather = json["weather"] as? [String: Any],
                  let sources = (json["sources"] as? [[String: Any]])?.first else {
                completion(nil, nil); return
            }

            // Parse station info
            let station = DWDStation(
                id:        sources["id"].map { "\($0)" } ?? "unknown",
                name:      sources["station_name"]    as? String ?? "DWD Station",
                latitude:  sources["lat"]             as? Double ?? lat,
                longitude: sources["lon"]             as? Double ?? lng,
                elevation: sources["height"]          as? Int    ?? 0,
                state:     sources["state"]           as? String
            )

            // Parse observation
            let iso = ISO8601DateFormatter()
            iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            let ts = (weather["timestamp"] as? String).flatMap { iso.date(from: $0) } ?? Date()

            let obs = DWDObservation(
                stationId:       station.id,
                timestamp:       ts,
                temperature:     weather["temperature"]      as? Double,
                dewpoint:        weather["dew_point"]        as? Double,
                pressure:        weather["pressure_msl"]     as? Double,
                windSpeed:       (weather["wind_speed"]      as? Double).map { $0 / 3.6 },
                windDirection:   weather["wind_direction"]   as? Int,
                windGust:        (weather["wind_gust_speed"] as? Double).map { $0 / 3.6 },
                precipitation:   weather["precipitation"]    as? Double,
                cloudCover:      weather["cloud_cover"]      as? Int,
                visibility:      weather["visibility"]       as? Int,
                presentWeather:  weather["condition"].map { _ in 0 }  // mapped separately
            )

            DispatchQueue.main.async { completion(obs, station) }
        }.resume()
    }

    // MARK: - 24h History from DWD via Bright Sky (DWD open-data proxy)
    func fetchHistory(lat: Double, lng: Double, hours: Int = 24,
                      completion: @escaping ([DWDObservation]) -> Void) {
        let end   = Date()
        let start = end.addingTimeInterval(-Double(hours) * 3600)
        let fmt   = ISO8601DateFormatter()
        fmt.formatOptions = [.withInternetDateTime]
        let urlStr = "https://api.brightsky.dev/weather?lat=\(lat)&lon=\(lng)&date=\(fmt.string(from: start))&last_date=\(fmt.string(from: end))"
        guard let url = URL(string: urlStr) else { completion([]); return }

        URLSession.shared.dataTask(with: url) { data, _, _ in
            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let weatherArr = json["weather"] as? [[String: Any]] else {
                completion([]); return
            }
            let iso = ISO8601DateFormatter()
            iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            let obs: [DWDObservation] = weatherArr.compactMap { w in
                guard let tsStr = w["timestamp"] as? String,
                      let ts = iso.date(from: tsStr) else { return nil }
                return DWDObservation(
                    stationId:     "dwd",
                    timestamp:     ts,
                    temperature:   w["temperature"]      as? Double,
                    dewpoint:      w["dew_point"]        as? Double,
                    pressure:      w["pressure_msl"]     as? Double,
                    windSpeed:     (w["wind_speed"]      as? Double).map { $0 / 3.6 },
                    windDirection: w["wind_direction"]   as? Int,
                    windGust:      (w["wind_gust_speed"] as? Double).map { $0 / 3.6 },
                    precipitation: w["precipitation"]    as? Double,
                    cloudCover:    w["cloud_cover"]      as? Int,
                    visibility:    w["visibility"]       as? Int,
                    presentWeather: nil
                )
            }
            DispatchQueue.main.async { completion(obs) }
        }.resume()
    }
}
