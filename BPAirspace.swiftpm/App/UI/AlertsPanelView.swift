import SwiftUI

// MARK: - Aviation Alerts Panel  (ws4kp / WeatherStar 4000 port)
struct AlertsPanelView: View {
    @StateObject private var engine = NWSAlertsEngine.shared
    @EnvironmentObject var viewModel: WeatherViewModel
    @State private var selectedAlert: NWSAlert?
    @State private var selectedAVWX: AVWXAlert?
    @State private var filter: AlertFilter = .all

    enum AlertFilter: String, CaseIterable {
        case all = "All"
        case aviation = "Aviation"
        case sigmet = "SIGMET/AIRMET"
    }

    var filteredAlerts: [NWSAlert] {
        switch filter {
        case .all:      return engine.alerts
        case .aviation: return engine.alerts.filter { $0.isAviationRelevant }
        case .sigmet:   return []
        }
    }

    var filteredAVWX: [AVWXAlert] {
        switch filter {
        case .sigmet, .aviation: return engine.avwxAlerts
        case .all:               return engine.avwxAlerts
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    Text("Aviation Alerts")
                        .font(.title3).fontWeight(.bold)
                    if engine.alertCount > 0 {
                        Text("\(engine.alertCount)")
                            .font(.caption).fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 7).padding(.vertical, 2)
                            .background(Color.red)
                            .cornerRadius(8)
                    }
                }
                Spacer()
                Button {
                    if let loc = viewModel.selectedLocation {
                        engine.fetchAlerts(lat: loc.latitude, lng: loc.longitude)
                        engine.fetchAviationAlerts()
                    } else {
                        engine.fetchAviationAlerts()
                    }
                } label: {
                    Image(systemName: engine.isLoading ? "arrow.clockwise" : "arrow.clockwise")
                        .foregroundColor(AppColors.accentGold)
                        .rotationEffect(engine.isLoading ? .degrees(360) : .zero)
                        .animation(engine.isLoading ? .linear(duration: 1).repeatForever(autoreverses: false) : .default,
                                   value: engine.isLoading)
                }
            }
            .padding()

            // Filter pills
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(AlertFilter.allCases, id: \.rawValue) { f in
                        Button {
                            withAnimation { filter = f }
                        } label: {
                            Text(f.rawValue)
                                .font(.caption).fontWeight(.semibold)
                                .padding(.horizontal, 12).padding(.vertical, 6)
                                .background(filter == f ? AppColors.accentGold : Color(UIColor.secondarySystemFill))
                                .foregroundColor(filter == f ? .white : .primary)
                                .cornerRadius(20)
                        }
                    }
                }
                .padding(.horizontal)
            }
            .padding(.bottom, 8)

            Divider()

            if filteredAlerts.isEmpty && filteredAVWX.isEmpty && !engine.isLoading {
                emptyState
            } else {
                ScrollView {
                    LazyVStack(spacing: 8) {
                        // SIGMET / AIRMET cards first
                        ForEach(filteredAVWX) { avwx in
                            AVWXAlertCard(alert: avwx)
                                .onTapGesture { selectedAVWX = avwx }
                        }
                        // NWS general alerts
                        ForEach(filteredAlerts) { alert in
                            NWSAlertCard(alert: alert)
                                .onTapGesture { selectedAlert = alert }
                        }
                    }
                    .padding()
                }
            }
        }
        .background(.ultraThinMaterial)
        .cornerRadius(18)
        .shadow(color: .black.opacity(0.12), radius: 10, x: 0, y: 5)
        .onAppear {
            engine.fetchAviationAlerts()
            if let loc = viewModel.selectedLocation {
                engine.fetchAlerts(lat: loc.latitude, lng: loc.longitude)
            }
        }
        .onChange(of: viewModel.selectedLocation?.latitude) { _, lat in
            if let loc = viewModel.selectedLocation { engine.fetchAlerts(lat: loc.latitude, lng: loc.longitude) }
        }
        .sheet(item: $selectedAlert) { alert in
            AlertDetailSheet(alert: alert)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.shield.fill")
                .font(.system(size: 42))
                .foregroundColor(.green)
            Text("No Active Alerts")
                .font(.headline)
            Text("No SIGMETs, AIRMETs or weather\nalerts for the selected area.")
                .font(.subheadline).foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

// MARK: - SIGMET / AIRMET Card
struct AVWXAlertCard: View {
    let alert: AVWXAlert

    var hazardColor: Color {
        switch alert.hazard {
        case "ICE":  return .cyan
        case "TURB": return .orange
        case "TS":   return .yellow
        case "IFR", "LIFR": return .red
        default:     return .purple
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(alert.type)
                    .font(.caption).fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 8).padding(.vertical, 3)
                    .background(alert.type == "SIGMET" ? Color.red : Color.orange)
                    .cornerRadius(6)
                if let hazard = alert.hazard {
                    Text(hazard)
                        .font(.caption).fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 6).padding(.vertical, 3)
                        .background(hazardColor)
                        .cornerRadius(6)
                }
                if let sev = alert.severity {
                    Text(sev)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                Spacer()
                if let to = alert.validTo {
                    Text("Exp \(to.formatted(.dateTime.hour().minute()))")
                        .font(.caption2).foregroundColor(.secondary)
                }
            }
            Text(alert.rawText)
                .font(.system(.caption, design: .monospaced))
                .foregroundColor(.primary)
                .lineLimit(3)
        }
        .padding(12)
        .background(Color(UIColor.secondarySystemFill))
        .cornerRadius(12)
    }
}

// MARK: - NWS Alert Card
struct NWSAlertCard: View {
    let alert: NWSAlert

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Circle()
                    .fill(alert.severityColor)
                    .frame(width: 8, height: 8)
                Text(alert.event)
                    .font(.subheadline).fontWeight(.semibold)
                Spacer()
                Text(alert.severity)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            if let headline = alert.headline {
                Text(headline)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            if let expires = alert.expires {
                Text("Expires \(expires.formatted(.dateTime.month(.abbreviated).day().hour().minute()))")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(12)
        .background(Color(UIColor.secondarySystemFill))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(alert.severityColor.opacity(0.4), lineWidth: 1)
        )
    }
}

// MARK: - Alert Detail Sheet
struct AlertDetailSheet: View {
    let alert: NWSAlert
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Severity badge
                    HStack {
                        Text(alert.severity.uppercased())
                            .font(.caption).fontWeight(.bold).foregroundColor(.white)
                            .padding(.horizontal, 10).padding(.vertical, 4)
                            .background(alert.severityColor)
                            .cornerRadius(8)
                        Text(alert.urgency)
                            .font(.caption).foregroundColor(.secondary)
                        Spacer()
                    }

                    if let area = alert.areaDesc {
                        Label(area, systemImage: "map")
                            .font(.subheadline)
                    }

                    if let headline = alert.headline {
                        Text(headline)
                            .font(.headline)
                    }

                    if let desc = alert.description {
                        Text(desc)
                            .font(.body)
                            .foregroundColor(.secondary)
                    }

                    if let exp = alert.expires {
                        Label("Expires \(exp.formatted(.dateTime.weekday().month(.abbreviated).day().hour().minute()))",
                              systemImage: "clock")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
            }
            .navigationTitle(alert.event)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
