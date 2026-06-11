import SwiftUI
import Charts

/// 24-hour scrollable line chart for the active weather layer.
struct WeatherChartView: View {
    @EnvironmentObject var viewModel: WeatherViewModel
    @AppStorage("unitSystem") var unitSystem: String = "metric"

    /// First 24 data points (1 day)
    private var points: [WeatherDataPoint] {
        Array(viewModel.hourlyDataPoints.prefix(24))
    }

    private var chartColor: Color { viewModel.activeLayer.accentColor }

    var body: some View {
        if points.isEmpty {
            Text("No data")
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            Chart {
                ForEach(points) { pt in
                    AreaMark(
                        x: .value("Time", pt.time),
                        y: .value("Value", displayValue(pt))
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [chartColor.opacity(0.55), chartColor.opacity(0.05)],
                            startPoint: .top, endPoint: .bottom
                        )
                    )
                    .interpolationMethod(.catmullRom)

                    LineMark(
                        x: .value("Time", pt.time),
                        y: .value("Value", displayValue(pt))
                    )
                    .foregroundStyle(chartColor)
                    .lineStyle(StrokeStyle(lineWidth: 2))
                    .interpolationMethod(.catmullRom)
                }

                // Current forecast index marker
                if viewModel.forecastIndex < points.count {
                    let current = points[viewModel.forecastIndex]
                    RuleMark(x: .value("Now", current.time))
                        .foregroundStyle(Color.white.opacity(0.7))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 3]))
                        .annotation(position: .top) {
                            Text(timeStr(current.time))
                                .font(.system(size: 8))
                                .foregroundColor(.secondary)
                        }
                }
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .hour, count: 6)) { value in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                        .foregroundStyle(Color.secondary.opacity(0.3))
                    AxisValueLabel(format: .dateTime.hour(.defaultDigits(amPM: .abbreviated)))
                        .font(.system(size: 9))
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) { _ in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                        .foregroundStyle(Color.secondary.opacity(0.3))
                    AxisValueLabel()
                        .font(.system(size: 9))
                }
            }
            .chartYAxisLabel(yLabel, position: .leading)
        }
    }

    private var yLabel: String {
        switch viewModel.activeLayer {
        case .temperature: return unitSystem == "imperial" ? "°F" : "°C"
        case .wind:        return unitSystem == "imperial" ? "kts" : "km/h"
        case .visibility:  return "km"
        default:           return viewModel.activeLayer.unit
        }
    }

    private func displayValue(_ pt: WeatherDataPoint) -> Double {
        switch viewModel.activeLayer {
        case .temperature:
            return unitSystem == "imperial" ? pt.temperature * 9/5 + 32 : pt.temperature
        case .wind:
            return unitSystem == "imperial" ? pt.windSpeed * 0.539957 : pt.windSpeed
        case .rain:        return pt.rain
        case .clouds:      return Double(pt.cloudCover)
        case .snow:        return pt.snowfall
        case .visibility:
            return unitSystem == "imperial"
                ? (pt.visibility / 1000.0) * 0.621371
                : pt.visibility / 1000.0
        case .humidity:    return Double(pt.humidity)
        case .pressure:    return pt.pressure
        }
    }

    private func timeStr(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        f.timeZone = TimeZone(identifier: "UTC")
        return f.string(from: date)
    }
}
