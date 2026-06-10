import Foundation

/// Phase 10 & 11: Airport Intelligence & Smart Alternate
class AirportIntelligenceEngine: ObservableObject {
    static let shared = AirportIntelligenceEngine()
    
    func analyzeAlternate(weather: AggregatedWeather, historicalDiversions: Int) -> AlternateRanking {
        // Smart Alternate Engine Logic
        var score = 100
        var reasons: [String] = []
        
        if weather.visibility < 1500 {
            score -= 40
            reasons.append("Marginal visibility")
        }
        
        if weather.windSpeed > 30 {
            score -= 30
            reasons.append("High crosswind probability")
        }
        
        if historicalDiversions > 5 {
            score -= 20
            reasons.append("Historically unreliable during front passage")
        }
        
        let rank: AlternateRank
        if score > 80 { rank = .best }
        else if score > 50 { rank = .good }
        else if score > 30 { rank = .marginal }
        else { rank = .avoid }
        
        return AlternateRanking(rank: rank, reasons: reasons)
    }
}

enum AlternateRank: String {
    case best = "Best"
    case good = "Good"
    case marginal = "Marginal"
    case avoid = "Avoid"
}

struct AlternateRanking {
    let rank: AlternateRank
    let reasons: [String]
}

/// Phase 13: AI Weather Copilot
class AICopilotEngine: ObservableObject {
    static let shared = AICopilotEngine()
    
    @Published var currentBriefing: String = "Awaiting intelligence..."
    
    func generateBriefing(weather: AggregatedWeather, hazards: [HazardEvent]) {
        var briefing = "Operational Weather Briefing:\n\n"
        
        if hazards.isEmpty {
            briefing += "Weather is nominal. No significant operational hazards detected on the route."
        } else {
            for hazard in hazards {
                switch hazard.type {
                case .thunderstorms:
                    briefing += "Expect deviation 20-40 NM around active convective cells.\n"
                case .icing:
                    briefing += "Icing risk detected. Ensure anti-ice systems are configured for climb.\n"
                case .crosswind:
                    briefing += "Strong crosswinds reported at arrival. Review limits.\n"
                default:
                    briefing += "\(hazard.recommendation)\n"
                }
            }
        }
        
        DispatchQueue.main.async {
            self.currentBriefing = briefing
        }
    }
}
