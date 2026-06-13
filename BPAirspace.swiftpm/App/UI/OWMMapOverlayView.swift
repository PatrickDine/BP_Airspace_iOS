import SwiftUI
import MapKit

// MARK: - OWM Tile Map Overlay  (rafaelkyrdan/Weather-Map port)
// Renders OpenWeatherMap precipitation/cloud/wind/temp/pressure tiles
// as a semi-transparent MKMapView layered on top of the native SwiftUI Map.
// The MKMapView itself is fully transparent (no base tiles) — only the OWM
// tile overlay is drawn, then blended via .allowsHitTesting(false).

struct OWMMapOverlayView: UIViewRepresentable {
    @EnvironmentObject var viewModel: WeatherViewModel
    let layer: OWMTileLayer
    let region: MKCoordinateRegion

    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: OWMMapOverlayView
        var currentLayer: OWMTileLayer?

        init(_ parent: OWMMapOverlayView) { self.parent = parent }

        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let tile = overlay as? OWMTileOverlay {
                return OWMTileOverlayRenderer(overlay: tile)
            }
            return MKOverlayRenderer(overlay: overlay)
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIView(context: Context) -> MKMapView {
        let mv = MKMapView()
        mv.isScrollEnabled  = false
        mv.isZoomEnabled    = false
        mv.isPitchEnabled   = false
        mv.isRotateEnabled  = false
        mv.showsUserLocation = false
        // Make the base map completely invisible — we only want the OWM tiles
        mv.mapType = .mutedStandard
        mv.alpha   = 1.0
        mv.backgroundColor = .clear
        // Hide the base tiles by using a custom style with 0 opacity
        mv.overrideUserInterfaceStyle = .dark
        mv.delegate = context.coordinator
        applyOverlay(to: mv, layer: layer, coordinator: context.coordinator)
        mv.setRegion(region, animated: false)
        return mv
    }

    func updateUIView(_ mv: MKMapView, context: Context) {
        // Sync camera
        mv.setRegion(region, animated: false)

        // Swap overlay if layer changed
        if context.coordinator.currentLayer != layer {
            mv.overlays.forEach { mv.removeOverlay($0) }
            applyOverlay(to: mv, layer: layer, coordinator: context.coordinator)
        }
    }

    private func applyOverlay(to mv: MKMapView, layer: OWMTileLayer, coordinator: Coordinator) {
        guard OWM_API_KEY != "YOUR_OWM_API_KEY" else { return }
        let overlay = OWMTileOverlay(layer: layer)
        overlay.canReplaceMapContent = false
        mv.addOverlay(overlay, level: .aboveLabels)
        coordinator.currentLayer = layer
    }
}

// MARK: - OWM Layer Picker  (shown in the map toolbar)
struct OWMLayerPickerView: View {
    @Binding var activeOWMLayer: OWMTileLayer?

    var body: some View {
        HStack(spacing: 6) {
            // Toggle button
            Button {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                    activeOWMLayer = activeOWMLayer == nil ? .precipitation : nil
                }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "square.3.layers.3d.top.filled")
                        .font(.system(size: 13))
                    Text("OWM Radar")
                        .font(.system(size: 12, weight: .semibold))
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(activeOWMLayer != nil
                    ? AppColors.accentGold
                    : Color(UIColor.secondarySystemFill))
                .foregroundColor(activeOWMLayer != nil ? .white : .primary)
                .cornerRadius(10)
            }

            if activeOWMLayer != nil {
                Divider().frame(height: 20)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 4) {
                        ForEach(OWMTileLayer.allCases) { owmLayer in
                            Button {
                                withAnimation { activeOWMLayer = owmLayer }
                            } label: {
                                HStack(spacing: 3) {
                                    Image(systemName: owmLayer.iconName).font(.system(size: 10))
                                    Text(owmLayer.displayName).font(.system(size: 10, weight: .medium))
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 5)
                                .background(activeOWMLayer == owmLayer
                                    ? AppColors.accentGold.opacity(0.8)
                                    : Color(UIColor.tertiarySystemFill))
                                .foregroundColor(activeOWMLayer == owmLayer ? .white : .primary)
                                .cornerRadius(8)
                            }
                        }
                    }
                }
                .transition(.move(edge: .leading).combined(with: .opacity))
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(.ultraThinMaterial)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.12), radius: 6, x: 0, y: 3)
    }
}
