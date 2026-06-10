import SwiftUI
import MapKit

struct MapView: View {
    @EnvironmentObject var viewModel: WeatherViewModel
    
    // Map Camera Position
    @State private var position: MapCameraPosition = .automatic
    
    var body: some View {
        Map(position: $position) {
            // Draw active route if available
            if let route = viewModel.activeRoute {
                MapPolyline(coordinates: route.coordinates)
                    .stroke(.green, lineWidth: 4)
                
                // Start Marker (Green)
                if let first = route.coordinates.first {
                    Marker(route.departure, systemImage: "airplane.departure", coordinate: first)
                        .tint(.green)
                }
                
                // End Marker (Red)
                if let last = route.coordinates.last {
                    Marker(route.arrival, systemImage: "airplane.arrival", coordinate: last)
                        .tint(.red)
                }
            }
            
            // Draw Geocoded Search Result
            if let searchLocation = viewModel.selectedLocation {
                Marker(searchLocation.name, systemImage: "mappin.circle.fill", coordinate: CLLocationCoordinate2D(latitude: searchLocation.latitude, longitude: searchLocation.longitude))
                    .tint(.blue)
            }
        }
        .mapStyle(.standard(elevation: .realistic))
        .mapControls {
            MapUserLocationButton()
            MapCompass()
            MapScaleView()
        }
        .overlay {
            // Overlay visual weather layers based on active layers
            // Note: True weather map tiles require MapKit JS or custom MKTileOverlay
            // For native MapKit, we simulate global overlay effects.
            ZStack {
                if viewModel.activeLayers.contains(.radar) {
                    Color.blue.opacity(0.1).ignoresSafeArea().allowsHitTesting(false)
                }
                if viewModel.activeLayers.contains(.clouds) {
                    Color.gray.opacity(0.2).ignoresSafeArea().allowsHitTesting(false)
                }
                if viewModel.activeLayers.contains(.temperature) {
                    Color.red.opacity(0.05).ignoresSafeArea().allowsHitTesting(false)
                }
            }
        }
        .onAppear {
            if let route = viewModel.activeRoute, let first = route.coordinates.first {
                // Initial weather fetch for departure
                viewModel.fetchWeather(lat: first.latitude, lng: first.longitude)
                
                // Auto position map to route
                let rect = MKMapRect(
                    origin: MKMapPoint(first),
                    size: MKMapSize(width: MKMapPoint(route.coordinates.last!).x - MKMapPoint(first).x,
                                    height: MKMapPoint(route.coordinates.last!).y - MKMapPoint(first).y)
                )
                position = .rect(rect)
            }
        }
        .onChange(of: viewModel.selectedLocation?.id) { _ in
            if let loc = viewModel.selectedLocation {
                viewModel.fetchWeather(lat: loc.latitude, lng: loc.longitude)
                position = .camera(MapCamera(centerCoordinate: CLLocationCoordinate2D(latitude: loc.latitude, longitude: loc.longitude), distance: 500000))
            }
        }
    }
}
