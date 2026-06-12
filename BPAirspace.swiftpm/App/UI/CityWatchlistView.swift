import SwiftUI

// MARK: - City Watchlist (ported from TakefiveInteractive/WeatherMap)
struct CityWatchlistView: View {
    @EnvironmentObject var viewModel: WeatherViewModel
    @StateObject private var store = CityStore.shared
    @State private var showAddCity = false
    @State private var cityWeather: [Int: WeatherDataPoint] = [:]
    @State private var cityAQI: [Int: AirQualityData] = [:]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "building.2.fill")
                        .foregroundColor(AppColors.accentGold)
                    Text("City Watchlist")
                        .font(.title3).fontWeight(.bold)
                }
                Spacer()
                Button {
                    showAddCity = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                        .foregroundColor(AppColors.accentGold)
                }
            }
            .padding()

            Divider()

            if store.cities.isEmpty {
                emptyState
            } else {
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(store.cities) { city in
                            CityRow(
                                city: city,
                                weather: cityWeather[city.id],
                                aqi: cityAQI[city.id]
                            )
                            .onTapGesture {
                                HapticEngine.shared.mediumImpact()
                                let result = GeocodingResult(
                                    id: city.id, name: city.name,
                                    latitude: city.latitude, longitude: city.longitude,
                                    country: city.country, admin1: city.admin1
                                )
                                viewModel.selectedLocation = result
                                viewModel.fetchWeather(lat: city.latitude, lng: city.longitude)
                                viewModel.fetchGridWeather(centerLat: city.latitude,
                                                           centerLng: city.longitude, span: 15)
                            }
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    store.remove(id: city.id)
                                } label: {
                                    Label("Remove", systemImage: "trash")
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                }
            }
        }
        .background(.ultraThinMaterial)
        .cornerRadius(18)
        .shadow(color: .black.opacity(0.12), radius: 10, x: 0, y: 5)
        .sheet(isPresented: $showAddCity) {
            AddCityView()
                .environmentObject(viewModel)
        }
        .onAppear { fetchAllCityWeather() }
        .onChange(of: store.cities.count) { _, _ in fetchAllCityWeather() }
    }

    // MARK: - Empty State
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "building.2").font(.system(size: 42)).foregroundColor(.secondary)
            Text("No cities saved").font(.headline).foregroundColor(.secondary)
            Text("Tap + to add airports or cities\nto your watchlist")
                .font(.subheadline).foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            Button {
                showAddCity = true
            } label: {
                Label("Add City", systemImage: "plus")
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(AppColors.accentGold)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    // MARK: - Fetch weather for all saved cities
    private func fetchAllCityWeather() {
        for city in store.cities {
            guard cityWeather[city.id] == nil else { continue }
            let fields = "temperature_2m,wind_speed_10m,wind_direction_10m,wind_gusts_10m,cloud_cover,rain,snowfall,visibility,weather_code,relative_humidity_2m,surface_pressure,apparent_temperature,uv_index"
            let urlStr = "https://api.open-meteo.com/v1/forecast?latitude=\(city.latitude)&longitude=\(city.longitude)&hourly=\(fields)&forecast_days=1&timezone=auto"
            guard let url = URL(string: urlStr) else { continue }

            let cityID = city.id
            URLSession.shared.dataTask(with: url) { data, _, _ in
                guard let data = data,
                      let decoded = try? JSONDecoder().decode(OpenMeteoResponse.self, from: data),
                      let pt = makePoint(from: decoded) else { return }
                DispatchQueue.main.async { self.cityWeather[cityID] = pt }
            }.resume()

            AirQualityEngine.shared.fetch(lat: city.latitude, lng: city.longitude) { aq in
                if let aq = aq { cityAQI[cityID] = aq }
            }
        }
    }

    private func makePoint(from resp: OpenMeteoResponse) -> WeatherDataPoint? {
        let h = resp.hourly
        guard let times = h.time, !times.isEmpty else { return nil }
        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withFullDate, .withTime, .withColonSeparatorInTime]
        let date = iso.date(from: times[0] + ":00") ?? Date()
        return WeatherDataPoint(
            time: date,
            temperature:       h.temperature_2m?[0] ?? 0,
            windSpeed:         h.wind_speed_10m?[0] ?? 0,
            windDirection:     h.wind_direction_10m?[0] ?? 0,
            windGusts:         h.wind_gusts_10m?[0] ?? 0,
            cloudCover:        h.cloud_cover?[0] ?? 0,
            rain:              h.rain?[0] ?? 0,
            snowfall:          h.snowfall?[0] ?? 0,
            visibility:        h.visibility?[0] ?? 10000,
            humidity:          h.relative_humidity_2m?[0] ?? 50,
            weatherCode:       h.weather_code?[0] ?? 0,
            pressure:          h.surface_pressure?[0] ?? 1013,
            apparentTemp:      h.apparent_temperature?[0] ?? 0,
            uvIndex:           h.uv_index?[0] ?? 0
        )
    }
}

// MARK: - City Row
struct CityRow: View {
    let city: SavedCity
    let weather: WeatherDataPoint?
    let aqi: AirQualityData?
    @AppStorage("unitSystem") var unitSystem: String = "metric"

    var body: some View {
        HStack(spacing: 12) {
            // Flag + name
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(city.flagEmoji).font(.title3)
                    Text(city.name)
                        .font(.subheadline).fontWeight(.semibold)
                        .lineLimit(1)
                }
                if let r = city.admin1 ?? city.country {
                    Text(r).font(.caption).foregroundColor(.secondary)
                }
            }

            Spacer()

            // Weather snapshot
            if let w = weather {
                VStack(alignment: .trailing, spacing: 2) {
                    Text(formatTemp(w.temperature))
                        .font(.headline).fontWeight(.bold).monospacedDigit()
                    Text(wmoEmoji(w.weatherCode))
                        .font(.title3)
                }
            } else {
                ProgressView().scaleEffect(0.7)
            }

            // AQI pill
            if let aq = aqi {
                Text(aq.aqiLabel)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(aq.aqiColor)
                    .cornerRadius(8)
            }
        }
        .padding(12)
        .background(Color(UIColor.secondarySystemFill))
        .cornerRadius(13)
    }

    private func formatTemp(_ c: Double) -> String {
        unitSystem == "imperial"
            ? String(format: "%.0f°F", c * 9/5 + 32)
            : String(format: "%.0f°C", c)
    }

    private func wmoEmoji(_ code: Int) -> String {
        switch code {
        case 0: return "☀️"; case 1,2: return "🌤️"; case 3: return "☁️"
        case 45,48: return "🌫️"; case 51...65: return "🌧️"
        case 71...75: return "🌨️"; case 80...82: return "🌦️"
        case 95,96,99: return "⛈️"; default: return "🌡️"
        }
    }
}
