import SwiftUI
import MapKit

struct MapView: View {
    @ObservedObject var weatherVM: WeatherViewModel
    
    // Default region: Continental US
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 39.8283, longitude: -98.5795),
        span: MKCoordinateSpan(latitudeDelta: 20.0, longitudeDelta: 20.0)
    )
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            Map(coordinateRegion: $region, interactionModes: .all, showsUserLocation: false, userTrackingMode: nil)
                .ignoresSafeArea()
            
            // Weather Layer Controls
            VStack(spacing: 8) {
                ForEach(WeatherViewModel.WeatherLayer.allCases) { layer in
                    Button(action: {
                        withAnimation { weatherVM.selectedLayer = layer }
                    }) {
                        Image(systemName: layer.iconName)
                            .font(.system(size: 20))
                            .frame(width: 48, height: 48)
                            .background(.ultraThinMaterial)
                            .cornerRadius(8)
                            .foregroundColor(weatherVM.selectedLayer == layer ? AppColors.accentGold : AppColors.textSecondary)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(weatherVM.selectedLayer == layer ? AppColors.accentGold : AppColors.textSecondary.opacity(0.2), lineWidth: 1)
                            )
                            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                    }
                }
            }
            .padding()
            
            // Live Info Panel
            VStack(alignment: .trailing) {
                InfoPanel(weatherVM: weatherVM)
            }
            .frame(maxWidth: .infinity, alignment: .topTrailing)
            .padding()
        }
    }
}

struct InfoPanel: View {
    @ObservedObject var weatherVM: WeatherViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Live Metrics")
                    .font(.headline)
                    .foregroundColor(AppColors.textPrimary)
                Spacer()
                Text("LIVE")
                    .font(.caption2).bold()
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(AppColors.safe.opacity(0.2))
                    .foregroundColor(AppColors.safe)
                    .cornerRadius(10)
            }
            
            ForEach(weatherVM.metrics) { metric in
                HStack {
                    Text(metric.title)
                        .font(.subheadline)
                        .foregroundColor(AppColors.textSecondary)
                    Spacer()
                    Text(metric.value)
                        .font(.subheadline).bold()
                        .foregroundColor(AppColors.textPrimary)
                }
                if metric.id != weatherVM.metrics.last?.id {
                    Divider()
                        .background(AppColors.accentGold.opacity(0.2))
                }
            }
        }
        .padding()
        .frame(width: 250)
        .background(.ultraThinMaterial)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(AppColors.accentGold.opacity(0.3), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
    }
}
