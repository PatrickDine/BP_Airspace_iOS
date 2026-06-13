import SwiftUI
import MapKit

struct MapView: View {
    @EnvironmentObject var viewModel: WeatherViewModel
    @State private var position: MapCameraPosition = .automatic
    @State private var pulseScale: CGFloat = 1.0
    @State private var pulseOpacity: Double = 0.8
    @State private var activeOWMLayer: OWMTileLayer? = nil   // Weather-Map port
    @State private var mapRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 20, longitude: 0),
        span: MKCoordinateSpan(latitudeDelta: 60, longitudeDelta: 60)
    )

    var body: some View {
        MapReader { reader in
            Map(position: $position) {

                // ── Active route polyline + markers ──────────────────────
                if let route = viewModel.activeRoute {
                    // Draw segments coloured by waypoint safety
                    if route.coordinates.count >= 2 {
                        MapPolyline(coordinates: route.coordinates)
                            .stroke(.white.opacity(0.9), lineWidth: 3)
                    }

                    // Waypoint markers
                    ForEach(route.waypoints) { wp in
                        Annotation(wp.name, coordinate: wp.coordinate) {
                            ZStack {
                                Circle()
                                    .fill(wp.safetyLevel.color)
                                    .frame(width: 14, height: 14)
                                Circle()
                                    .stroke(.white, lineWidth: 2)
                                    .frame(width: 14, height: 14)
                            }
                        }
                    }
                }

                // ── Tapped / selected location pin ───────────────────────
                if let coord = viewModel.tappedCoordinate {
                    Annotation("", coordinate: coord) {
                        ZStack {
                            // Pulsing ring
                            Circle()
                                .stroke(viewModel.activeLayer.accentColor, lineWidth: 2)
                                .frame(width: 36 * pulseScale, height: 36 * pulseScale)
                                .opacity(pulseOpacity)

                            // Centre dot
                            Circle()
                                .fill(viewModel.activeLayer.accentColor)
                                .frame(width: 12, height: 12)

                            Circle()
                                .stroke(.white, lineWidth: 2)
                                .frame(width: 12, height: 12)
                        }
                        .onAppear { animatePulse() }
                    }
                }

                // ── Grid weather overlay (MapCircle per grid point) ───────
                ForEach(viewModel.gridDataPoints) { pt in
                    let coord = CLLocationCoordinate2D(latitude: pt.lat, longitude: pt.lng)
                    MapCircle(center: coord, radius: circleRadius)
                        .foregroundStyle(gridColor(pt).opacity(0.50))
                }

            } // Map
            .mapStyle(.standard(elevation: .realistic, emphasis: .muted))
            .mapControls {
                MapUserLocationButton()
                MapCompass()
                MapScaleView()
            }

            // ── Tap-to-inspect ───────────────────────────────────────────
            .onTapGesture { screenPt in
                guard let coord = reader.convert(screenPt, from: .local) else { return }
                HapticEngine.shared.mediumImpact()
                withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                    viewModel.tappedCoordinate = coord
                    viewModel.selectedLocation = GeocodingResult(
                        id: abs(coord.latitude.hashValue ^ coord.longitude.hashValue),
                        name: String(format: "%.3f°, %.3f°", coord.latitude, coord.longitude),
                        latitude: coord.latitude, longitude: coord.longitude,
                        country: nil, admin1: nil
                    )
                }
                viewModel.fetchWeather(lat: coord.latitude, lng: coord.longitude)
                pulseScale = 1.0; pulseOpacity = 0.8
                animatePulse()
            }

            // ── Grid refresh when user finishes panning ──────────────────
            .onMapCameraChange(frequency: .onEnd) { ctx in
                let c = ctx.region.center
                let span = ctx.region.span.latitudeDelta
                viewModel.mapSpanDelta = span
                viewModel.fetchGridWeather(centerLat: c.latitude,
                                            centerLng: c.longitude, span: span)
            }

            // ── Wind-particle overlay ─────────────────────────────────
            .overlay(alignment: .center) {
                if viewModel.activeLayer == .wind {
                    WindParticleView()
                        .environmentObject(viewModel)
                        .allowsHitTesting(false)
                        .ignoresSafeArea()
                }
            }

            // ── OWM tile overlay (Weather-Map port) ─────────────────
            .overlay(alignment: .center) {
                if let owmLayer = activeOWMLayer {
                    OWMMapOverlayView(layer: owmLayer, region: mapRegion)
                        .environmentObject(viewModel)
                        .allowsHitTesting(false)
                        .ignoresSafeArea()
                        .opacity(0.65)
                }
            }

            // ── OWM layer picker ───────────────────────────────────
            .overlay(alignment: .bottom) {
                OWMLayerPickerView(activeOWMLayer: $activeOWMLayer)
                    .padding(.bottom, 16)
            }

        } // MapReader

        // Initial camera + grid
        .onAppear {
            if let loc = viewModel.selectedLocation {
                let coord = CLLocationCoordinate2D(latitude: loc.latitude, longitude: loc.longitude)
                position = .camera(MapCamera(centerCoordinate: coord, distance: 1_500_000))
                viewModel.fetchGridWeather(centerLat: loc.latitude,
                                            centerLng: loc.longitude, span: 20.0)
            } else {
                // Default to world view
                position = .camera(MapCamera(
                    centerCoordinate: CLLocationCoordinate2D(latitude: 20, longitude: 0),
                    distance: 15_000_000))
                viewModel.fetchGridWeather(centerLat: 20, centerLng: 0, span: 60)
            }
        }

        // Re-center when selected location changes (e.g. home airport or search)
        .onChange(of: viewModel.selectedLocation?.id) { _, _ in
            if let loc = viewModel.selectedLocation {
                let coord = CLLocationCoordinate2D(latitude: loc.latitude, longitude: loc.longitude)
                withAnimation {
                    position = .camera(MapCamera(centerCoordinate: coord, distance: 800_000))
                }
            }
        }
    }

    // MARK: - Helpers

    /// Scale the overlay circle radius with the current zoom span
    private var circleRadius: CLLocationDistance {
        max(50_000, viewModel.mapSpanDelta * 40_000)
    }

    private func gridColor(_ pt: GridWeatherPoint) -> Color {
        switch viewModel.activeLayer {
        case .wind:        return WeatherColorMap.wind(pt.windSpeed)
        case .temperature: return WeatherColorMap.temperature(pt.temperature)
        case .rain:        return WeatherColorMap.rain(pt.rain)
        case .clouds:      return WeatherColorMap.cloud(pt.cloudCover)
        case .snow:        return WeatherColorMap.snow(pt.snowfall)
        case .visibility:  return WeatherColorMap.visibility(pt.visibility)
        case .humidity:    return WeatherColorMap.humidity(Double(pt.humidity))
        case .pressure:    return WeatherColorMap.pressure(pt.pressure)
        }
    }

    private func animatePulse() {
        withAnimation(.easeOut(duration: 1.4).repeatForever(autoreverses: false)) {
            pulseScale   = 2.2
            pulseOpacity = 0.0
        }
    }
}
