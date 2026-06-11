import SwiftUI

// MARK: - Route Planning Panel
struct RoutePanelView: View {
    @EnvironmentObject var viewModel: WeatherViewModel
    @State private var departure = ""
    @State private var arrival   = ""
    @State private var isPlanning = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {

            // Header
            HStack {
                Image(systemName: "map.fill").foregroundColor(.blue)
                Text("Route Planning").font(.title3).fontWeight(.bold)
            }

            // Input fields
            VStack(spacing: 10) {
                airportField(label: "Departure", icon: "airplane.departure",
                             color: .green,  text: $departure)
                airportField(label: "Arrival",   icon: "airplane.arrival",
                             color: .red,    text: $arrival)
            }

            // Plan button
            Button(action: planRoute) {
                HStack {
                    if isPlanning {
                        ProgressView().scaleEffect(0.75).tint(.white)
                    } else {
                        Image(systemName: "map.fill")
                    }
                    Text(isPlanning ? "Fetching route weather…" : "Plan Route & Get Weather")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding(13)
                .background(canPlan
                    ? LinearGradient(colors: [.blue, Color(hue: 0.58, saturation: 0.9, brightness: 0.95)],
                                     startPoint: .leading, endPoint: .trailing)
                    : LinearGradient(colors: [.gray.opacity(0.4), .gray.opacity(0.4)],
                                     startPoint: .leading, endPoint: .trailing))
                .foregroundColor(.white)
                .cornerRadius(13)
                .shadow(color: canPlan ? .blue.opacity(0.35) : .clear,
                        radius: 8, x: 0, y: 4)
            }
            .disabled(!canPlan || isPlanning)
            .animation(.easeInOut(duration: 0.2), value: canPlan)

            // Waypoint list
            if let route = viewModel.activeRoute, !route.waypoints.isEmpty {
                Divider()
                Text("En-Route Conditions")
                    .font(.subheadline).fontWeight(.semibold)

                VStack(spacing: 6) {
                    ForEach(route.waypoints) { wp in
                        WaypointRow(waypoint: wp)
                    }
                }

                // Safety summary
                safetySummary(waypoints: route.waypoints)
            }

            Spacer(minLength: 0)
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(18)
        .shadow(color: .black.opacity(0.12), radius: 10, x: 0, y: 5)
    }

    // MARK: - Helpers
    private var canPlan: Bool { !departure.trimmingCharacters(in: .whitespaces).isEmpty
                             && !arrival.trimmingCharacters(in: .whitespaces).isEmpty }

    private func planRoute() {
        HapticEngine.shared.mediumImpact()
        isPlanning = true
        viewModel.planRoute(departure: departure, arrival: arrival)
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) { isPlanning = false }
    }

    @ViewBuilder
    private func airportField(label: String, icon: String, color: Color,
                              text: Binding<String>) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 22)
            TextField(label + " (ICAO or city)", text: text)
                .autocapitalization(.allCharacters)
                .disableAutocorrection(true)
        }
        .padding(11)
        .background(Color(UIColor.secondarySystemFill))
        .cornerRadius(11)
    }

    @ViewBuilder
    private func safetySummary(waypoints: [WaypointCondition]) -> some View {
        let dangerCount  = waypoints.filter { $0.safetyLevel == .danger  }.count
        let cautionCount = waypoints.filter { $0.safetyLevel == .caution }.count
        let summaryColor: Color = dangerCount > 0 ? .red : cautionCount > 0 ? .orange : .green
        let summaryText = dangerCount > 0
            ? "⚠️ \(dangerCount) dangerous segment(s) — consider re-routing"
            : cautionCount > 0
            ? "⚡ \(cautionCount) caution segment(s) — exercise care"
            : "✅ Route looks safe at current forecast time"

        Text(summaryText)
            .font(.caption)
            .foregroundColor(summaryColor)
            .padding(8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(summaryColor.opacity(0.10))
            .cornerRadius(8)
    }
}

// MARK: - Waypoint Row
struct WaypointRow: View {
    let waypoint: WaypointCondition

    var body: some View {
        HStack(spacing: 10) {
            // Safety dot
            Circle()
                .fill(waypoint.safetyLevel.color)
                .frame(width: 11, height: 11)
                .overlay(Circle().stroke(.white.opacity(0.6), lineWidth: 1))

            Text(waypoint.name)
                .font(.subheadline).fontWeight(.medium)
                .lineLimit(1)

            Spacer()

            if let w = waypoint.weather {
                VStack(alignment: .trailing, spacing: 1) {
                    Text(String(format: "%.0f°C", w.temperature))
                        .font(.caption2).foregroundColor(.secondary)
                    Text(String(format: "%.0f km/h", w.windSpeed))
                        .font(.caption2).foregroundColor(.secondary)
                    if w.rain > 0.5 {
                        Text(String(format: "%.1f mm", w.rain))
                            .font(.caption2).foregroundColor(.blue)
                    }
                }
            } else {
                ProgressView().scaleEffect(0.6)
            }
        }
        .padding(9)
        .background(Color(UIColor.secondarySystemFill))
        .cornerRadius(10)
    }
}

// MARK: - Fuel Panel (unchanged)
struct FuelPanelView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Image(systemName: "fuelpump.fill").foregroundColor(.orange)
                Text("Fuel Analytics").font(.title3).fontWeight(.bold)
            }
            Text("Active route fuel burn is being modelled based on real-time headwind vectors.")
                .foregroundColor(.secondary).font(.subheadline)
            HStack {
                Text("Est. Burn Rate:").font(.caption).foregroundColor(.secondary)
                Spacer()
                Text("2,400 kg/hr").font(.headline).monospacedDigit()
            }
            .padding()
            .background(Color(UIColor.secondarySystemFill))
            .cornerRadius(10)
            Spacer()
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(18)
        .shadow(color: .black.opacity(0.12), radius: 10, x: 0, y: 5)
    }
}
