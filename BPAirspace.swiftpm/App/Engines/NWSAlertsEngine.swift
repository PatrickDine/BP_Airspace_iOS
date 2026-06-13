import Foundation
import SwiftUI

// MARK: - NWS Alert Model  (ported from vbguyny/ws4kp WeatherStar 4000)
// Pulls live SIGMETs, AIRMETs, TFRs, and Active Alerts from api.weather.gov
// All endpoints are FREE with no API key required.

struct NWSAlert: Identifiable, Codable {
    let id: String
    let event: String          // "SIGMET", "AIRMET", "Special Weather Statement", etc.
    let headline: String?
    let description: String?
    let severity: String       // "Extreme" | "Severe" | "Moderate" | "Minor" | "Unknown"
    let urgency: String        // "Immediate" | "Expected" | "Future" | "Past"
    let onset: Date?
    let expires: Date?
    let areaDesc: String?

    var severityColor: Color {
        switch severity {
        case "Extreme":  return .red
        case "Severe":   return .orange
        case "Moderate": return Color(hue: 0.13, saturation: 0.9, brightness: 0.95)
        case "Minor":    return .yellow
        default:         return .gray
        }
    }

    var isAviationRelevant: Bool {
        let keywords = ["SIGMET", "AIRMET", "TFR", "Temporary Flight", "Wind Advisory",
                        "Thunderstorm", "Winter Storm", "Blizzard", "Ice", "Turbulence",
                        "Icing", "Fog", "Low Visibility", "Tornado", "Hurricane"]
        let combined = (event + (headline ?? "") + (description ?? "")).lowercased()
        return keywords.contains { combined.contains($0.lowercased()) }
    }

    enum CodingKeys: String, CodingKey {
        case id, event, headline, description, severity, urgency, onset, expires, areaDesc
    }
}

// MARK: - Raw NWS API Response
private struct NWSResponse: Codable {
    let features: [NWSFeature]
}
private struct NWSFeature: Codable {
    let id: String?
    let properties: NWSProperties
}
private struct NWSProperties: Codable {
    let id: String?
    let event: String?
    let headline: String?
    let description: String?
    let severity: String?
    let urgency: String?
    let onset: String?
    let expires: String?
    let areaDesc: String?
}

// MARK: - Aviation Weather (aviationweather.gov) SIGMET
struct AVWXAlert: Identifiable {
    let id = UUID()
    let type: String            // "SIGMET" | "AIRMET" | "PIREP"
    let rawText: String
    let validFrom: Date?
    let validTo: Date?
    let hazard: String?         // "ICE" | "TURB" | "TS" | "IFR" | "MTN OBSCN"
    let severity: String?       // "SEV" | "MOD" | "LGT"
}

// MARK: - Engine
class NWSAlertsEngine: ObservableObject {
    static let shared = NWSAlertsEngine()
    private init() {}

    @Published var alerts: [NWSAlert] = []
    @Published var avwxAlerts: [AVWXAlert] = []
    @Published var isLoading = false

    private let iso = ISO8601DateFormatter()

    // MARK: - Fetch NWS active alerts for a lat/lon point
    func fetchAlerts(lat: Double, lng: Double) {
        isLoading = true
        let urlStr = "https://api.weather.gov/alerts/active?point=\(lat),\(lng)&status=actual&limit=50"
        guard let url = URL(string: urlStr) else { return }

        var req = URLRequest(url: url)
        req.setValue("BPAirspace-iOS/1.0 (aviation weather app)", forHTTPHeaderField: "User-Agent")

        URLSession.shared.dataTask(with: req) { [weak self] data, _, _ in
            guard let self = self, let data = data else {
                DispatchQueue.main.async { self?.isLoading = false }
                return
            }
            if let resp = try? JSONDecoder().decode(NWSResponse.self, from: data) {
                let mapped: [NWSAlert] = resp.features.compactMap { f in
                    let p = f.properties
                    guard let event = p.event else { return nil }
                    return NWSAlert(
                        id:          p.id ?? f.id ?? UUID().uuidString,
                        event:       event,
                        headline:    p.headline,
                        description: p.description,
                        severity:    p.severity ?? "Unknown",
                        urgency:     p.urgency  ?? "Unknown",
                        onset:       p.onset.flatMap { self.iso.date(from: $0) },
                        expires:     p.expires.flatMap { self.iso.date(from: $0) },
                        areaDesc:    p.areaDesc
                    )
                }
                DispatchQueue.main.async {
                    self.alerts = mapped
                    self.isLoading = false
                }
            } else {
                DispatchQueue.main.async { self.isLoading = false }
            }
        }.resume()
    }

    // MARK: - Fetch SIGMETs / AIRMETs from aviationweather.gov  (ws4kp data concept)
    func fetchAviationAlerts() {
        // SIGMET endpoint – NOAA Aviation Weather Center, free, no key
        let urls: [(String, String)] = [
            ("https://aviationweather.gov/api/data/isigmet?format=json", "SIGMET"),
            ("https://aviationweather.gov/api/data/airmet?format=json",  "AIRMET")
        ]

        for (urlStr, type) in urls {
            guard let url = URL(string: urlStr) else { continue }
            URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
                guard let self = self, let data = data else { return }
                // Response is a JSON array of raw text objects
                if let arr = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
                    let parsed: [AVWXAlert] = arr.compactMap { item in
                        guard let raw = item["rawAirSigmet"] as? String
                                     ?? item["airsigmetText"] as? String
                                     ?? item["rawAirmet"] as? String else { return nil }
                        let hazard   = item["hazard"] as? String
                        let severity = item["severity"] as? String
                        var from: Date? = nil
                        var to:   Date? = nil
                        if let vs = item["validTimeFrom"] as? String { from = self.iso.date(from: vs) }
                        if let ve = item["validTimeTo"]   as? String { to   = self.iso.date(from: ve) }
                        return AVWXAlert(type: type, rawText: raw,
                                         validFrom: from, validTo: to,
                                         hazard: hazard, severity: severity)
                    }
                    DispatchQueue.main.async {
                        if type == "SIGMET" {
                            self.avwxAlerts.removeAll { $0.type == "SIGMET" }
                        } else {
                            self.avwxAlerts.removeAll { $0.type == "AIRMET" }
                        }
                        self.avwxAlerts.append(contentsOf: parsed)
                    }
                }
            }.resume()
        }
    }

    var alertCount: Int { alerts.count + avwxAlerts.count }
    var aviationAlertCount: Int { avwxAlerts.count + alerts.filter { $0.isAviationRelevant }.count }
}
