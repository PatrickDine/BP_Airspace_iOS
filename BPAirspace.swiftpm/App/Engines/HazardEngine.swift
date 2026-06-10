import Foundation
import Combine

/// Analyzes WIE feeds and issues Automated Hazard Alerts
class HazardEngine: ObservableObject {
    static let shared = HazardEngine()
    
    @Published var activeHazards: [HazardEvent] = []
    
    func analyze(weather: AggregatedWeather) {
        var detected: [HazardEvent] = []
        
        // 1. Wind Shear / Crosswind Hazard
        if weather.windSpeed > 30 {
            detected.append(HazardEvent(
                type: .crosswind,
                severity: weather.windSpeed > 45 ? .severe : .moderate,
                recommendation: "Review crosswind limits and anticipate turbulent approach."
            ))
        }
        
        // 2. Low Visibility Hazard
        if weather.visibility < 1000 { // Meters
            detected.append(HazardEvent(
                type: .lowVisibility,
                severity: .severe,
                recommendation: "LVP in force. Expect CAT II/III approach minimums."
            ))
        }
        
        // 3. Convective Activity (Mocked from missing radar for now)
        if weather.windDirection > 180 && weather.windSpeed > 25 && weather.temperature > 30 {
            detected.append(HazardEvent(
                type: .thunderstorms,
                severity: .moderate,
                recommendation: "Convective activity detected near route. Deviation likely."
            ))
        }
        
        DispatchQueue.main.async {
            self.activeHazards = detected
        }
    }
}

struct HazardEvent: Identifiable {
    let id = UUID()
    let type: HazardType
    let severity: HazardSeverity
    let recommendation: String
}

enum HazardType: String {
    case thunderstorms = "Thunderstorms"
    case windShear = "Wind Shear"
    case crosswind = "Strong Crosswinds"
    case lowVisibility = "Low Visibility"
    case icing = "Icing"
    case turbulence = "Turbulence"
}

enum HazardSeverity: String {
    case low = "Low"
    case moderate = "Moderate"
    case severe = "Severe"
    case extreme = "Extreme"
}
