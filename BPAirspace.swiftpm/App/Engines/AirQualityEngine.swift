import Foundation
import SwiftUI

// MARK: - Air Quality Data Model (ported from darkmoonight/Rain)
struct AirQualityData: Codable {
    let time: Date
    let pm25: Double         // μg/m³
    let pm10: Double         // μg/m³
    let no2: Double          // μg/m³
    let ozone: Double        // μg/m³
    let co: Double           // μg/m³
    let europeanAQI: Int     // 0-5 (1=Good … 5=Very Poor)
    let usAQI: Int           // 0-500

    /// Descriptive label for the European AQI
    var aqiLabel: String {
        switch europeanAQI {
        case 1: return "Good"
        case 2: return "Fair"
        case 3: return "Moderate"
        case 4: return "Poor"
        case 5: return "Very Poor"
        default: return "N/A"
        }
    }

    /// SwiftUI colour for the AQI badge
    var aqiColor: Color {
        switch europeanAQI {
        case 1: return Color(hue: 0.33, saturation: 0.80, brightness: 0.75)   // green
        case 2: return Color(hue: 0.19, saturation: 0.90, brightness: 0.90)   // yellow-green
        case 3: return Color(hue: 0.09, saturation: 0.90, brightness: 0.95)   // orange
        case 4: return Color(hue: 0.00, saturation: 0.80, brightness: 0.85)   // red
        case 5: return Color(hue: 0.78, saturation: 0.75, brightness: 0.70)   // purple
        default: return .gray
        }
    }
}

// MARK: - Raw API Response (Open-Meteo AQ)
private struct AQResponse: Codable {
    let hourly: AQHourly
}
private struct AQHourly: Codable {
    let time: [String]
    let pm2_5: [Double?]
    let pm10: [Double?]
    let nitrogen_dioxide: [Double?]
    let ozone: [Double?]
    let carbon_monoxide: [Double?]
    let european_aqi: [Int?]
    let us_aqi: [Int?]
}

// MARK: - Engine
class AirQualityEngine {
    static let shared = AirQualityEngine()
    private init() {}

    private let isoFull: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withFullDate, .withTime, .withColonSeparatorInTime]
        return f
    }()

    private let isoBasic: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withFullDate, .withTime, .withDashSeparatorInDate,
                           .withColonSeparatorInTime]
        return f
    }()

    /// Fetch current air-quality for a location. Calls back on main thread.
    func fetch(lat: Double, lng: Double, completion: @escaping (AirQualityData?) -> Void) {
        let fields = "pm2_5,pm10,nitrogen_dioxide,ozone,carbon_monoxide,european_aqi,us_aqi"
        let urlStr = "https://air-quality-api.open-meteo.com/v1/air-quality"
            + "?latitude=\(lat)&longitude=\(lng)"
            + "&hourly=\(fields)&forecast_days=1&timezone=auto"
        guard let url = URL(string: urlStr) else { completion(nil); return }

        URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
            guard let self = self,
                  let data = data,
                  let decoded = try? JSONDecoder().decode(AQResponse.self, from: data),
                  let firstIndex = decoded.hourly.time.indices.first else {
                DispatchQueue.main.async { completion(nil) }
                return
            }

            let h = decoded.hourly
            let timeStr = h.time[firstIndex]
            let date = self.isoFull.date(from: timeStr + ":00")
                    ?? self.isoBasic.date(from: timeStr)
                    ?? Date()

            let aq = AirQualityData(
                time: date,
                pm25:       h.pm2_5[firstIndex]             ?? 0,
                pm10:       h.pm10[firstIndex]              ?? 0,
                no2:        h.nitrogen_dioxide[firstIndex]  ?? 0,
                ozone:      h.ozone[firstIndex]             ?? 0,
                co:         h.carbon_monoxide[firstIndex]   ?? 0,
                europeanAQI: h.european_aqi[firstIndex]    ?? 0,
                usAQI:      h.us_aqi[firstIndex]            ?? 0
            )
            DispatchQueue.main.async { completion(aq) }
        }.resume()
    }
}
