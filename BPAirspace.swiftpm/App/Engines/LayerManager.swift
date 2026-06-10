import Foundation
import Combine

/// Phase 15: Advanced Map Experience
class LayerManager: ObservableObject {
    static let shared = LayerManager()
    
    @Published var weatherOpacity: Double = 0.8
    @Published var activeCategories: Set<LayerCategory> = [.weather, .radar]
    
    enum LayerCategory: String, CaseIterable, Identifiable {
        case weather = "Weather Intelligence"
        case radar = "Radar Volumes"
        case airport = "Airport Analytics"
        case notam = "NOTAMs & Hazards"
        case traffic = "ADS-B Traffic"
        case terrain = "Terrain Profiling"
        
        var id: String { self.rawValue }
    }
    
    func toggleCategory(_ category: LayerCategory) {
        if activeCategories.contains(category) {
            activeCategories.remove(category)
        } else {
            activeCategories.insert(category)
        }
    }
}
