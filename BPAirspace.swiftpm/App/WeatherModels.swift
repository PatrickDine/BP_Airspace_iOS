import Foundation
import CoreLocation

struct FlightRoute: Identifiable {
    let id = UUID()
    var departure: String
    var arrival: String
    var coordinates: [CLLocationCoordinate2D]
}

struct WeatherMetric: Identifiable {
    let id = UUID()
    let title: String
    let value: String
    let isLive: Bool
}

class WeatherViewModel: ObservableObject {
    @Published var selectedLayer: WeatherLayer = .radar
    @Published var metrics: [WeatherMetric] = [
        WeatherMetric(title: "Wind Shear", value: "Moderate", isLive: true),
        WeatherMetric(title: "Turbulence", value: "Low", isLive: true),
        WeatherMetric(title: "Visibility", value: "10+ SM", isLive: true)
    ]
    
    enum WeatherLayer: String, CaseIterable, Identifiable {
        case radar = "Radar"
        case wind = "Wind"
        case clouds = "Clouds"
        
        var id: String { self.rawValue }
        
        var iconName: String {
            switch self {
            case .radar: return "cloud.rain.fill"
            case .wind: return "wind"
            case .clouds: return "cloud.fill"
            }
        }
    }
}
