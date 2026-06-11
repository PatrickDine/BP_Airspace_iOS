# BP Airspace

**Aviation Operational Intelligence Platform**

BP Airspace has been radically upgraded from a simple geospatial map into a fully native iOS Operational Intelligence Engine. This repository contains the complete Swift 6 / SwiftUI implementation of the massive Intelligence Engine Matrix, natively rendering critical meteorological data using Apple MapKit and Metal.

### 🛑 Standalone Architecture
**Notice**: BP Airspace is a 100% independent, standalone aviation application. It does not depend on, nor does it reference, Briefing Point GO or any external proprietary modules. It relies strictly on its own internal `CoreEngines` matrix.

## The Engine Matrix (17-Phase Re-Architecture)

1. **AirspaceEngine**: GeoJSON bounds parsing and Class B/C/D visualization.
2. **WeatherEngine**: Single-source-of-truth atmospheric pipeline (Wetterdienst design emulation).
3. **RadarEngine**: Native Swift translation of PyART / pycwr volumetric radar algorithms.
4. **TrafficEngine**: Local ADS-B parsing and trailing visualizations.
5. **HazardEngine**: Automated detection of Microbursts, Wind Shear, and Severe Convection.
6. **AirportEngine**: Weather reliability scoring, crosswind limits, and LVP detection.
7. **RouteIntelligenceEngine**: 4D Waypoint weather timeline generation.
8. **LayerEngine**: Dynamic toggle control for Weather, Radar, Jet Streams, and Turbulence.
9. **PlaybackEngine**: 60fps historical radar timeline animation (Weather Radar Card logic).
10. **OfflineEngine**: SwiftData-powered caching for routes, airspace, and weather tiles.
11. **SynchronizationEngine**: Background incremental data fetching.
12. **AnalyticsEngine**: Internal telemetry and TEM (Threat and Error Management) profiling.
13. **AICopilotEngine**: Aviation-focused NLP briefing generation.
14. **MapRenderingEngine**: Apple Metal-backed high-performance OpenGL translations from Supercell-WX.

## Technology Stack
- **Language**: Swift 6
- **UI Framework**: SwiftUI
- **Map & Geo**: MapKit, CoreLocation
- **Graphics**: Metal (Shaders)
- **Data Persistence**: SwiftData / FileManager
- **Concurrency**: `actor` and `async/await` Structured Concurrency

## Build Instructions
1. Open `BPAirspace.swiftpm` in Xcode 15+ or Swift Playgrounds.
2. Select target iOS 17.0+.
3. Run `Cmd+R`. No external dependency managers (CocoaPods/Carthage) are required. All logic is contained within the Swift Package Manager format.
