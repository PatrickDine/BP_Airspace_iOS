import Foundation

/// Phase 12: Hazard Engine
class HazardEngine: ObservableObject {
    static let shared = HazardEngine()
    
    @Published var activeHazards: [HazardEvent] = []
    
    func analyze(weather: AggregatedWeather) {
        var detected: [HazardEvent] = []
        
        // Thunderstorms & Embedded CB Logic
        if weather.windSpeed > 25 && weather.temperature > 28 {
            detected.append(HazardEvent(type: .thunderstorms, severity: .moderate, recommendation: "Convective activity detected near route. Deviation likely."))
        }
        
        // Low Visibility & Microbursts Logic
        if weather.visibility < 1000 {
            detected.append(HazardEvent(type: .lowVisibility, severity: .severe, recommendation: "LVP in force. Expect CAT II/III approach minimums."))
        }
        
        // Crosswinds
        if weather.windSpeed > 30 {
            detected.append(HazardEvent(type: .crosswind, severity: .severe, recommendation: "Review crosswind limits and anticipate turbulent approach."))
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
    case microbursts = "Microbursts"
    case mountainWaves = "Mountain Waves"
    case volcanicAsh = "Volcanic Ash"
    case dustStorms = "Dust Storms"
}

enum HazardSeverity: String {
    case low = "Low"
    case moderate = "Moderate"
    case severe = "Severe"
    case extreme = "Extreme"
}
