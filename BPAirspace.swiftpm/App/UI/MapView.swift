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
                    LinearGradient(gradient: Gradient(colors: [.blue.opacity(0.3), .green.opacity(0.1)]), startPoint: .topLeading, endPoint: .bottomTrailing)
                        .ignoresSafeArea().allowsHitTesting(false)
                }
                if viewModel.activeLayers.contains(.clouds) {
                    LinearGradient(gradient: Gradient(colors: [.white.opacity(0.4), .gray.opacity(0.2)]), startPoint: .top, endPoint: .bottom)
                        .ignoresSafeArea().allowsHitTesting(false)
                }
                if viewModel.activeLayers.contains(.temperature) {
                    LinearGradient(gradient: Gradient(colors: [.red.opacity(0.25), .blue.opacity(0.15)]), startPoint: .top, endPoint: .bottom)
                        .ignoresSafeArea().allowsHitTesting(false)
                }
                if viewModel.activeLayers.contains(.wind) {
                    LinearGradient(gradient: Gradient(colors: [.cyan.opacity(0.3), .clear]), startPoint: .leading, endPoint: .trailing)
                        .ignoresSafeArea().allowsHitTesting(false)
                }
                if viewModel.activeLayers.contains(.rain) {
                    Color.blue.opacity(0.2).ignoresSafeArea().allowsHitTesting(false)
                }
                if viewModel.activeLayers.contains(.snow) {
                    Color.white.opacity(0.3).ignoresSafeArea().allowsHitTesting(false)
                }
                if viewModel.activeLayers.contains(.visibility) {
                    Color.yellow.opacity(0.15).ignoresSafeArea().allowsHitTesting(false)
                }
            }
            .animation(.easeInOut(duration: 0.5), value: viewModel.activeLayers)
        }
        .onAppear {
            if let loc = viewModel.selectedLocation {
                position = .camera(MapCamera(centerCoordinate: CLLocationCoordinate2D(latitude: loc.latitude, longitude: loc.longitude), distance: 500000))
            } else if let route = viewModel.activeRoute, let first = route.coordinates.first {
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
        .onChange(of: viewModel.selectedLocation?.id) { oldValue, newValue in
            if let loc = viewModel.selectedLocation {
                viewModel.fetchWeather(lat: loc.latitude, lng: loc.longitude)
                position = .camera(MapCamera(centerCoordinate: CLLocationCoordinate2D(latitude: loc.latitude, longitude: loc.longitude), distance: 500000))
            }
        }
    }
}
