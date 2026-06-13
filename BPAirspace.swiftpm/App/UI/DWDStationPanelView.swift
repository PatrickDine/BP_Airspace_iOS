import SwiftUI

// MARK: - DWD Station Panel  (earthobservations/wetterdienst port)
// Shows official DWD ground-truth observation from the nearest German weather station
struct DWDStationPanelView: View {
    @EnvironmentObject var viewModel: WeatherViewModel
    @State private var observation: DWDObservation?
    @State private var station: DWDStation?
    @State private var history: [DWDObservation] = []
    @State private var isLoading = false
    @State private var showHistory = false
    @AppStorage("unitSystem") var unitSystem: String = "metric"

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "antenna.radiowaves.left.and.right")
                        .foregroundColor(AppColors.accentGold)
                    VStack(alignment: .leading, spacing: 1) {
                        Text("DWD Station")
                            .font(.title3).fontWeight(.bold)
                        if let s = station {
                            Text(s.name + (s.state.map { " · \($0)" } ?? ""))
                                .font(.caption).foregroundColor(.secondary)
                        }
                    }
                }
                Spacer()
                if isLoading { ProgressView().scaleEffect(0.8) }
                Button {
                    fetchData()
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .foregroundColor(AppColors.accentGold)
                }
            }
            .padding()

            Divider()

            if let obs = observation {
                ScrollView {
                    VStack(spacing: 12) {
                        // Primary reading
                        HStack(alignment: .bottom, spacing: 6) {
                            if let t = obs.temperature {
                                Text(formatTemp(t))
                                    .font(.system(size: 52, weight: .bold, design: .rounded))
                            }
                            VStack(alignment: .leading, spacing: 2) {
                                if let dp = obs.dewpoint {
                                    Label(formatTemp(dp), systemImage: "drop.fill")
                                        .font(.caption).foregroundColor(.teal)
                                }
                                if let alt = station?.elevation {
                                    Label("\(alt) m AMSL", systemImage: "mountain.2")
                                        .font(.caption).foregroundColor(.secondary)
                                }
                            }
                            Spacer()
                        }
                        .padding(.horizontal)

                        // Stat grid
                        let cols = [GridItem(.flexible()), GridItem(.flexible())]
                        LazyVGrid(columns: cols, spacing: 8) {
                            if let ws = obs.windSpeedKmh {
                                StatCard(icon: "wind", label: "Wind", value: formatWind(ws))
                            }
                            if let wd = obs.windDirection {
                                StatCard(icon: "location.north.fill", label: "Dir", value: "\(wd)°")
                            }
                            if let wg = obs.windGustKmh {
                                StatCard(icon: "tornado", label: "Gusts", value: formatWind(wg))
                            }
                            if let p = obs.pressure {
                                StatCard(icon: "gauge.medium", label: "QNH", value: "\(Int(p)) hPa")
                            }
                            if let vis = obs.visibility {
                                StatCard(icon: "eye.fill", label: "Vis", value: formatVis(Double(vis)))
                            }
                    if let cc = obs.cloudCover {
                        StatCard(icon: "cloud.fill", label: "Cloud", value: String(format: "%.0f%%", Double(cc) * 12.5))
                    }
                            if let pr = obs.precipitation {
                                StatCard(icon: "drop.fill", label: "Rain", value: String(format: "%.1f mm", pr))
                            }
                        }
                        .padding(.horizontal)

                        // Data source badge
                        HStack {
                            Image(systemName: "building.columns")
                                .font(.caption2)
                            Text("Source: DWD Open Data via Bright Sky API")
                                .font(.caption2)
                            Spacer()
                            Text(obs.timestamp.formatted(.dateTime.hour().minute()))
                                .font(.caption2).monospacedDigit()
                        }
                        .foregroundColor(.secondary)
                        .padding(.horizontal)

                        // History toggle
                        Button {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                showHistory.toggle()
                                if showHistory && history.isEmpty { fetchHistory() }
                            }
                        } label: {
                            HStack {
                                Image(systemName: "chart.xyaxis.line")
                                    .foregroundColor(AppColors.accentGold)
                                Text("24h Station History")
                                    .font(.caption).foregroundColor(.secondary)
                                Spacer()
                                Image(systemName: showHistory ? "chevron.up" : "chevron.down")
                                    .font(.caption2).foregroundColor(.secondary)
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 4)
                        }

                        if showHistory {
                            DWDHistoryChart(history: history)
                                .frame(height: 120)
                                .padding(.horizontal)
                                .transition(.opacity.combined(with: .move(edge: .top)))
                        }
                    }
                    .padding(.top, 8)
                    .padding(.bottom, 16)
                }
            } else if !isLoading {
                dwdEmptyState
            }
        }
        .background(.ultraThinMaterial)
        .cornerRadius(18)
        .shadow(color: .black.opacity(0.12), radius: 10, x: 0, y: 5)
        .onAppear { fetchData() }
        .onChange(of: viewModel.selectedLocation?.latitude) { _, _ in fetchData() }
    }

    private var dwdEmptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "antenna.radiowaves.left.and.right.slash")
                .font(.system(size: 38))
                .foregroundColor(.secondary)
            Text("No DWD Station Data")
                .font(.headline).foregroundColor(.secondary)
            Text("DWD data is available for Europe.\nTap ↻ to reload or select a\nEuropean location.")
                .font(.subheadline).foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    private func fetchData() {
        let lat = viewModel.selectedLocation?.latitude  ?? 51.5
        let lng = viewModel.selectedLocation?.longitude ?? 10.0
        isLoading = true
        DWDWeatherEngine.shared.fetchNearestObservation(lat: lat, lng: lng) { obs, st in
            self.observation = obs
            self.station = st
            self.isLoading = false
        }
    }

    private func fetchHistory() {
        let lat = viewModel.selectedLocation?.latitude  ?? 51.5
        let lng = viewModel.selectedLocation?.longitude ?? 10.0
        DWDWeatherEngine.shared.fetchHistory(lat: lat, lng: lng) { obs in
            self.history = obs
        }
    }

    private func formatTemp(_ c: Double) -> String {
        unitSystem == "imperial"
            ? String(format: "%.0f°F", c * 9/5 + 32)
            : String(format: "%.0f°C", c)
    }
    private func formatWind(_ kmh: Double) -> String {
        unitSystem == "imperial"
            ? String(format: "%.0f kt", kmh * 0.539957)
            : String(format: "%.0f km/h", kmh)
    }
    private func formatVis(_ m: Double) -> String {
        m >= 1000 ? String(format: "%.1f km", m / 1000) : String(format: "%.0f m", m)
    }
}

// MARK: - Simple 24h temperature sparkline
struct DWDHistoryChart: View {
    let history: [DWDObservation]

    var temps: [Double] { history.compactMap { $0.temperature } }

    var body: some View {
        if temps.isEmpty {
            ProgressView()
        } else {
            GeometryReader { geo in
                let mn = temps.min()!
                let mx = temps.max()!
                let range = mx - mn == 0 ? 1 : mx - mn
                let pts = temps.enumerated().map { (i, t) -> CGPoint in
                    let x = geo.size.width * CGFloat(i) / CGFloat(temps.count - 1)
                    let y = geo.size.height * (1 - CGFloat((t - mn) / range))
                    return CGPoint(x: x, y: y)
                }
                ZStack {
                    // Gradient fill
                    Path { p in
                        guard !pts.isEmpty else { return }
                        p.move(to: CGPoint(x: pts.first!.x, y: geo.size.height))
                        for pt in pts { p.addLine(to: pt) }
                        p.addLine(to: CGPoint(x: pts.last!.x, y: geo.size.height))
                        p.closeSubpath()
                    }
                    .fill(LinearGradient(colors: [AppColors.accentGold.opacity(0.3), .clear],
                                        startPoint: .top, endPoint: .bottom))

                    // Line
                    Path { p in
                        guard !pts.isEmpty else { return }
                        p.move(to: pts[0])
                        for pt in pts.dropFirst() { p.addLine(to: pt) }
                    }
                    .stroke(AppColors.accentGold, lineWidth: 2)

                    // Min/Max labels
                    VStack {
                        HStack {
                            Text(String(format: "%.0f°", mx)).font(.caption2).foregroundColor(.secondary)
                            Spacer()
                        }
                        Spacer()
                        HStack {
                            Text(String(format: "%.0f°", mn)).font(.caption2).foregroundColor(.secondary)
                            Spacer()
                        }
                    }
                }
            }
        }
    }
}
