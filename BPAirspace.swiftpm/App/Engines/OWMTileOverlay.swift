import Foundation
import MapKit

// MARK: - OpenWeatherMap Tile Overlay  (ported from rafaelkyrdan/Weather-Map)
// Uses OWM tile server: https://tile.openweathermap.org/map/{layer}/{z}/{x}/{y}.png
// Free tier: 60 calls/min, 1 million calls/month
// Register at: https://openweathermap.org/api
// Replace the placeholder below with your free OWM API key.
let OWM_API_KEY = "YOUR_OWM_API_KEY"

// MARK: - Layer definitions
enum OWMTileLayer: String, CaseIterable, Identifiable {
    case precipitation   = "precipitation_new"
    case clouds          = "clouds_new"
    case pressure        = "pressure_new"
    case wind            = "wind_new"
    case temperature     = "temp_new"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .precipitation: return "Radar"
        case .clouds:        return "Clouds"
        case .pressure:      return "Pressure"
        case .wind:          return "Wind"
        case .temperature:   return "Temp"
        }
    }

    var iconName: String {
        switch self {
        case .precipitation: return "cloud.rain.fill"
        case .clouds:        return "cloud.fill"
        case .pressure:      return "gauge.medium"
        case .wind:          return "wind"
        case .temperature:   return "thermometer.medium"
        }
    }
}

// MARK: - MKTileOverlay subclass
class OWMTileOverlay: MKTileOverlay {
    let layer: OWMTileLayer

    init(layer: OWMTileLayer) {
        self.layer = layer
        let template = "https://tile.openweathermap.org/map/\(layer.rawValue)/{z}/{x}/{y}.png?appid=\(OWM_API_KEY)"
        super.init(urlTemplate: template)
        self.canReplaceMapContent = false
        self.minimumZ = 0
        self.maximumZ = 18
    }

    override func url(forTilePath path: MKTileOverlayPath) -> URL {
        let str = "https://tile.openweathermap.org/map/\(layer.rawValue)/\(path.z)/\(path.x)/\(path.y).png?appid=\(OWM_API_KEY)"
        return URL(string: str)!
    }
}

// MARK: - Tile Overlay Renderer
class OWMTileOverlayRenderer: MKTileOverlayRenderer {
    override func draw(_ mapRect: MKMapRect, zoomScale: MKZoomScale, in context: CGContext) {
        context.setAlpha(0.60)   // semi-transparent so MapKit base shows through
        super.draw(mapRect, zoomScale: zoomScale, in: context)
    }
}
