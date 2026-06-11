import SwiftUI

struct ForecastSliderView: View {
    @EnvironmentObject var viewModel: WeatherViewModel

    private var maxIndex: Double {
        Double(max(viewModel.hourlyDataPoints.count - 1, 167))
    }

    var body: some View {
        VStack(spacing: 8) {
            // Top row: time label + play/pause + reset
            HStack(spacing: 12) {
                // Time display
                VStack(alignment: .leading, spacing: 1) {
                    if let pt = viewModel.currentDataPoint {
                        Text(dayLabel(pt.time))
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.secondary)
                        Text(utcLabel(pt.time))
                            .font(.system(size: 15, weight: .bold))
                            .monospacedDigit()
                    } else {
                        Text("Now")
                            .font(.system(size: 15, weight: .bold))
                    }
                }
                .frame(width: 90, alignment: .leading)

                Spacer()

                // Active layer name + unit
                HStack(spacing: 4) {
                    Image(systemName: viewModel.activeLayer.iconName)
                        .font(.system(size: 11))
                    Text(viewModel.activeLayer.rawValue)
                        .font(.system(size: 11, weight: .semibold))
                }
                .foregroundColor(viewModel.activeLayer.accentColor)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(viewModel.activeLayer.accentColor.opacity(0.12))
                .cornerRadius(8)

                // Play / Pause
                Button {
                    HapticEngine.shared.selection()
                    viewModel.isAnimatingForecast
                        ? viewModel.stopForecastAnimation()
                        : viewModel.startForecastAnimation()
                } label: {
                    Image(systemName: viewModel.isAnimatingForecast
                          ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(
                            LinearGradient(colors: [viewModel.activeLayer.accentColor,
                                                    viewModel.activeLayer.accentColor.opacity(0.6)],
                                           startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                }

                // Reset to now
                Button {
                    viewModel.stopForecastAnimation()
                    withAnimation { viewModel.forecastIndex = 0 }
                } label: {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 18))
                        .foregroundColor(.secondary)
                }
            }

            // Slider
            Slider(
                value: Binding(
                    get: { Double(viewModel.forecastIndex) },
                    set: { v in
                        let i = Int(v)
                        if i != viewModel.forecastIndex {
                            HapticEngine.shared.selection()
                            viewModel.forecastIndex = i
                        }
                    }
                ),
                in: 0...maxIndex, step: 1
            )
            .tint(viewModel.activeLayer.accentColor)

            // Day markers below slider
            HStack {
                ForEach(dayMarkers, id: \.label) { marker in
                    Text(marker.label)
                        .font(.system(size: 9))
                        .foregroundColor(marker.isCurrent ? viewModel.activeLayer.accentColor : .secondary)
                        .fontWeight(marker.isCurrent ? .bold : .regular)
                        .frame(maxWidth: .infinity, alignment: marker.alignment)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
        .cornerRadius(18)
        .shadow(color: .black.opacity(0.15), radius: 10, x: 0, y: 5)
    }

    // MARK: - Day Markers
    private struct DayMarker {
        let label: String
        let isCurrent: Bool
        let alignment: Alignment
    }

    private var dayMarkers: [DayMarker] {
        let cal = Calendar.current
        let pts = viewModel.hourlyDataPoints
        guard !pts.isEmpty else {
            return [
                DayMarker(label: "Today",   isCurrent: true,  alignment: .leading),
                DayMarker(label: "+3 days", isCurrent: false, alignment: .center),
                DayMarker(label: "+7 days", isCurrent: false, alignment: .trailing)
            ]
        }

        var markers: [DayMarker] = []
        var seen: Set<Int> = []
        let currentDay = cal.component(.day, from: pts[min(viewModel.forecastIndex, pts.count-1)].time)

        for (i, pt) in pts.enumerated() {
            let day = cal.component(.day, from: pt.time)
            if !seen.contains(day) {
                seen.insert(day)
                let isCurrent = day == currentDay
                let dayN = seen.count
                let align: Alignment = dayN == 1 ? .leading : (dayN == pts.count / 24 ? .trailing : .center)
                let label: String
                if dayN == 1 { label = "Today" }
                else if dayN == 2 { label = "Tmrw" }
                else {
                    let f = DateFormatter(); f.dateFormat = "EEE"
                    label = f.string(from: pt.time)
                }
                markers.append(DayMarker(label: label, isCurrent: isCurrent, alignment: align))
                if markers.count >= 7 { break }
            }
            let _ = i  // suppress unused warning
        }
        return markers.isEmpty ? [DayMarker(label: "Today", isCurrent: true, alignment: .leading)] : markers
    }

    // MARK: - Labels
    private func dayLabel(_ date: Date) -> String {
        let cal = Calendar.current
        if cal.isDateInToday(date)     { return "Today" }
        if cal.isDateInTomorrow(date)  { return "Tomorrow" }
        let f = DateFormatter(); f.dateFormat = "EEE, MMM d"
        return f.string(from: date)
    }

    private func utcLabel(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "HH:mm 'UTC'"
        f.timeZone = TimeZone(identifier: "UTC")
        return f.string(from: date)
    }
}
