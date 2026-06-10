import Foundation

/// Phase 8: Threat and Error Management (TEM) Integration
class TEMEngine: ObservableObject {
    static let shared = TEMEngine()
    
    @Published var activeTEMs: [TEMProfile] = []
    
    func generateTEM(from hazards: [HazardEvent]) {
        let profiles = hazards.map { hazard -> TEMProfile in
            switch hazard.type {
            case .thunderstorms:
                return TEMProfile(
                    threat: "Convective Activity on Route",
                    potentialError: "Late deviation request leading to airspace penetration.",
                    mitigation: "Pre-plan 20NM weather escape corridor. Coordinate with ATC early."
                )
            case .crosswind:
                return TEMProfile(
                    threat: "Strong Crosswind Landing",
                    potentialError: "Improper crab angle removal causing side-loading.",
                    mitigation: "Review crosswind limits. Brief go-around criteria."
                )
            case .lowVisibility:
                return TEMProfile(
                    threat: "Low Visibility Procedures (LVP)",
                    potentialError: "Loss of situational awareness during taxi.",
                    mitigation: "Brief airport surface movement diagram. Heads-up taxi."
                )
            default:
                return TEMProfile(
                    threat: hazard.type.rawValue,
                    potentialError: "Task saturation.",
                    mitigation: "Maintain strict PM monitoring."
                )
            }
        }
        
        DispatchQueue.main.async {
            self.activeTEMs = profiles
        }
    }
}

struct TEMProfile: Identifiable {
    let id = UUID()
    let threat: String
    let potentialError: String
    let mitigation: String
}

/// Phase 12: Fatigue Engine
class FatigueEngine: ObservableObject {
    static let shared = FatigueEngine()
    
    @Published var operationalStressIndex: Int = 0
    @Published var workloadStatus: WorkloadStatus = .low
    
    func calculateFatigue(hazards: [HazardEvent], flightDurationHours: Double) {
        var score = 0
        
        for hazard in hazards {
            switch hazard.severity {
            case .low: score += 1
            case .moderate: score += 3
            case .severe: score += 5
            case .extreme: score += 10
            }
        }
        
        // Base fatigue on time of day + flight duration
        score += Int(flightDurationHours * 2)
        
        DispatchQueue.main.async {
            self.operationalStressIndex = score
            if score < 10 {
                self.workloadStatus = .low
            } else if score < 20 {
                self.workloadStatus = .moderate
            } else {
                self.workloadStatus = .high
            }
        }
    }
}

enum WorkloadStatus: String {
    case low = "Low Workload"
    case moderate = "Moderate Workload"
    case high = "High Workload (Brief PM Support)"
}
