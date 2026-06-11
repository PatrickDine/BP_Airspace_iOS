import SwiftUI

struct CurrentConditionsView: View {
    @EnvironmentObject var viewModel: WeatherViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Text("Current Conditions")
                    .font(.headline)
                    .fontWeight(.bold)
                Spacer()
                HStack(spacing: 4) {
                    Circle()
                        .fill(viewModel.isLoading ? Color.orange : Color.green)
                        .frame(width: 8, height: 8)
                    Text(viewModel.isLoading ? "LOADING" : "LIVE")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(viewModel.isLoading ? .orange : .green)
                }
            }
            
            Divider()
            
            if let weather = viewModel.weatherData {
                let hourIndex = min(viewModel.forecastIndex, (weather.hourly.time?.count ?? 1) - 1)
                
                VStack(alignment: .leading, spacing: 12) {
                    ConditionRow(title: "Location", value: viewModel.selectedLocation?.name ?? "Selected Route")
                    
                    if hourIndex >= 0 {
                        ConditionRow(title: "Time", value: formatTime(weather.hourly.time?[hourIndex] ?? ""))
                        ConditionRow(title: "Temperature", value: String(format: "%.1f°C", weather.hourly.temperature_2m?[hourIndex] ?? 0.0))
                        ConditionRow(title: "Wind", value: String(format: "%.1f km/h @ %d°", weather.hourly.wind_speed_10m?[hourIndex] ?? 0.0, weather.hourly.wind_direction_10m?[hourIndex] ?? 0))
                        ConditionRow(title: "Wind Gusts", value: String(format: "%.1f km/h", weather.hourly.wind_gusts_10m?[hourIndex] ?? 0.0))
                        ConditionRow(title: "Cloud Cover", value: "\(weather.hourly.cloud_cover?[hourIndex] ?? 0)%")
                        ConditionRow(title: "Rain", value: String(format: "%.1f mm", weather.hourly.rain?[hourIndex] ?? 0.0))
                        ConditionRow(title: "Snowfall", value: String(format: "%.1f cm", weather.hourly.snowfall?[hourIndex] ?? 0.0))
                        ConditionRow(title: "Visibility", value: String(format: "%.1f km", (weather.hourly.visibility?[hourIndex] ?? 0.0) / 1000.0))
                        ConditionRow(title: "Humidity", value: "\(weather.hourly.relative_humidity_2m?[hourIndex] ?? 0)%")
                        ConditionRow(title: "Condition Code", value: "\(weather.hourly.weather_code?[hourIndex] ?? 0)")
                    }
                }
            } else {
                Text("No weather data available.\nTap a route or search to load.")
                    .foregroundColor(.secondary)
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical)
            }
            
            Divider()
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Active Layers")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                if viewModel.activeLayers.isEmpty {
                    Text("No layers active. Toggle layers on the left.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else {
                    HStack {
                        ForEach(Array(viewModel.activeLayers), id: \.self) { layer in
                            Text(layer.rawValue)
                                .font(.caption2)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.blue.opacity(0.2))
                                .cornerRadius(8)
                        }
                    }
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
    }
    
    private func formatTime(_ timeString: String) -> String {
        let formatter = ISO8601DateFormatter()
        // Open-Meteo returns "2026-06-10T00:00"
        let cleanString = timeString.count == 16 ? timeString + ":00Z" : timeString
        guard let date = formatter.date(from: cleanString) else { return timeString }
        
        let displayFormatter = DateFormatter()
        displayFormatter.dateFormat = "MMM d, h:mm a"
        return displayFormatter.string(from: date)
    }
}

struct ConditionRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .foregroundColor(.secondary)
                .font(.subheadline)
            Spacer()
            Text(value)
                .fontWeight(.medium)
                .font(.subheadline)
        }
    }
}
