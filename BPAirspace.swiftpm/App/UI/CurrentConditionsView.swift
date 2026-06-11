import SwiftUI

struct CurrentConditionsView: View {
    @EnvironmentObject var viewModel: WeatherViewModel
    @AppStorage("unitSystem") var unitSystem: String = "metric"
    @State private var showChart = false

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {

            // ── Header ──────────────────────────────────────────────────
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(viewModel.selectedLocation?.name ?? "Tap map to inspect")
                        .font(.headline).fontWeight(.bold)
                        .lineLimit(2)
                    if let region = viewModel.selectedLocation?.admin1 ?? viewModel.selectedLocation?.country {
                        Text(region)
                            .font(.caption).foregroundColor(.secondary)
                    }
                }
                Spacer()
                LiveBadge(isLoading: viewModel.isLoading)
            }

            Divider()

            if let pt = viewModel.currentDataPoint {

                // ── Condition + wind compass ─────────────────────────────
                HStack(alignment: .top, spacing: 16) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(wmoEmoji(pt.weatherCode))
                            .font(.system(size: 40))
                        Text(wmoDescription(pt.weatherCode))
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(formatTemp(pt.temperature))
                            .font(.system(size: 28, weight: .bold))
                            .monospacedDigit()
                    }
                    Spacer()
                    WindCompassView(
                        speed: pt.windSpeed,
                        direction: pt.windDirection,
                        unitSystem: unitSystem
                    )
                }

                // ── 6-stat grid ──────────────────────────────────────────
                let cols = [GridItem(.flexible()), GridItem(.flexible())]
                LazyVGrid(columns: cols, spacing: 8) {
                    StatCard(icon: "drop.fill",         label: "Rain",     value: formatPrecip(pt.rain))
                    StatCard(icon: "cloud.fill",         label: "Cloud",    value: "\(pt.cloudCover)%")
                    StatCard(icon: "eye.fill",           label: "Vis",      value: formatVis(pt.visibility))
                    StatCard(icon: "humidity.fill",      label: "Humidity", value: "\(pt.humidity)%")
                    StatCard(icon: "gauge.medium",       label: "QNH",      value: "\(Int(pt.pressure)) hPa")
                    StatCard(icon: "snowflake",          label: "Snow",     value: formatSnow(pt.snowfall))
                }

                // ── Gusts warning ─────────────────────────────────────────
                if pt.windGusts > pt.windSpeed + 10 {
                    HStack(spacing: 5) {
                        Image(systemName: "wind").font(.caption).foregroundColor(.orange)
                        Text("Gusts to \(formatWind(pt.windGusts))")
                            .font(.caption).foregroundColor(.orange)
                    }
                    .padding(6)
                    .background(Color.orange.opacity(0.10))
                    .cornerRadius(8)
                }

                // ── 24hr chart toggle ─────────────────────────────────────
                Button {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        showChart.toggle()
                    }
                } label: {
                    HStack {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .foregroundColor(viewModel.activeLayer.accentColor)
                        Text("24 hr forecast chart")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Image(systemName: showChart ? "chevron.up" : "chevron.down")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                }

                if showChart {
                    WeatherChartView()
                        .environmentObject(viewModel)
                        .frame(height: 130)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }

            } else {
                // Empty state
                VStack(spacing: 12) {
                    Image(systemName: "hand.tap.fill")
                        .font(.system(size: 36))
                        .foregroundColor(.secondary)
                    Text("Tap anywhere on the map\nto inspect live weather")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(18)
        .shadow(color: .black.opacity(0.10), radius: 10, x: 0, y: 5)
    }

    // MARK: - Formatters
    private func formatTemp(_ c: Double) -> String {
        unitSystem == "imperial"
            ? String(format: "%.1f°F", c * 9/5 + 32)
            : String(format: "%.1f°C", c)
    }
    private func formatWind(_ k: Double) -> String {
        unitSystem == "imperial"
            ? String(format: "%.0f kts", k * 0.539957)
            : String(format: "%.0f km/h", k)
    }
    private func formatVis(_ m: Double) -> String {
        if unitSystem == "imperial" {
            return String(format: "%.1f sm", (m / 1000) * 0.621371)
        }
        return m >= 1000 ? String(format: "%.0f km", m / 1000) : String(format: "%.0f m", m)
    }
    private func formatPrecip(_ mm: Double) -> String {
        unitSystem == "imperial"
            ? String(format: "%.2f\"", mm * 0.0393701)
            : String(format: "%.1f mm", mm)
    }
    private func formatSnow(_ cm: Double) -> String {
        unitSystem == "imperial"
            ? String(format: "%.1f in", cm * 0.393701)
            : String(format: "%.1f cm", cm)
    }

    // MARK: - WMO Code Mapping
    private func wmoEmoji(_ code: Int) -> String {
        switch code {
        case 0:        return "☀️"
        case 1, 2:     return "🌤️"
        case 3:        return "☁️"
        case 45, 48:   return "🌫️"
        case 51...55:  return "🌦️"
        case 61...65:  return "🌧️"
        case 71...75:  return "🌨️"
        case 80...82:  return "🌦️"
        case 95:       return "⛈️"
        case 96, 99:   return "⛈️"
        default:       return "🌡️"
        }
    }

    private func wmoDescription(_ code: Int) -> String {
        switch code {
        case 0:       return "Clear Sky"
        case 1:       return "Mainly Clear"
        case 2:       return "Partly Cloudy"
        case 3:       return "Overcast"
        case 45:      return "Fog"
        case 48:      return "Icy Fog"
        case 51:      return "Light Drizzle"
        case 53:      return "Moderate Drizzle"
        case 55:      return "Dense Drizzle"
        case 61:      return "Light Rain"
        case 63:      return "Moderate Rain"
        case 65:      return "Heavy Rain"
        case 71:      return "Light Snow"
        case 73:      return "Moderate Snow"
        case 75:      return "Heavy Snow"
        case 80:      return "Light Showers"
        case 81:      return "Moderate Showers"
        case 82:      return "Violent Showers"
        case 95:      return "Thunderstorm"
        case 96, 99:  return "Severe T-Storm"
        default:      return "Code \(code)"
        }
    }
}

// MARK: - Supporting Views

struct LiveBadge: View {
    let isLoading: Bool
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(isLoading ? Color.orange : Color.green)
                .frame(width: 7, height: 7)
            Text(isLoading ? "UPDATING" : "LIVE")
                .font(.system(size: 9, weight: .bold))
                .foregroundColor(isLoading ? .orange : .green)
        }
    }
}

struct StatCard: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 13))
                .foregroundColor(.secondary)
                .frame(width: 18)
            VStack(alignment: .leading, spacing: 1) {
                Text(label)
                    .font(.system(size: 9))
                    .foregroundColor(.secondary)
                Text(value)
                    .font(.system(size: 13, weight: .semibold))
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(9)
        .background(Color(UIColor.secondarySystemFill))
        .cornerRadius(10)
    }
}

// ConditionRow kept for any remaining call-sites
struct ConditionRow: View {
    let title: String
    let value: String
    var body: some View {
        HStack {
            Text(title).foregroundColor(.secondary).font(.subheadline)
            Spacer()
            Text(value).fontWeight(.medium).font(.subheadline)
        }
    }
}
