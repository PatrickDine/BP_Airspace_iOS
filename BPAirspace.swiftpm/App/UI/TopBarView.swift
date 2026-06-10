import SwiftUI

struct TopBarView: View {
    @EnvironmentObject var viewModel: WeatherViewModel
    @State private var searchText = ""
    @State private var searchResults: [GeocodingResult] = []
    @State private var isSearching = false
    
    // Live Clock
    @State private var utcTime = ""
    @State private var localTime = ""
    
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        HStack {
            Text("Weather Map")
                .font(.headline)
                .fontWeight(.bold)
                .padding(.trailing, 8)
            
            // Search Bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("Search Location...", text: $searchText)
                    .onChange(of: searchText) { oldValue, newValue in
                        if newValue.count > 2 {
                            performSearch(query: newValue)
                        } else {
                            searchResults = []
                        }
                    }
                
                if isSearching {
                    ProgressView().scaleEffect(0.8)
                }
            }
            .padding(8)
            .background(Color(UIColor.secondarySystemFill))
            .cornerRadius(8)
            .frame(maxWidth: 300)
            
            Spacer()
            
            // Clocks
            VStack(alignment: .trailing, spacing: 2) {
                HStack(spacing: 12) {
                    Text("UTC")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text("LOCAL")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                HStack(spacing: 12) {
                    Text(utcTime)
                        .font(.caption)
                        .monospacedDigit()
                    Text(localTime)
                        .font(.caption)
                        .monospacedDigit()
                }
            }
            .padding(.trailing, 16)
            
            // Profile
            Circle()
                .fill(Color.orange.opacity(0.8))
                .frame(width: 32, height: 32)
                .overlay(Text("G").font(.caption).fontWeight(.bold).foregroundColor(.white))
        }
        .padding()
        .background(.ultraThinMaterial)
        .overlay(
            VStack {
                if !searchResults.isEmpty {
                    List(searchResults) { result in
                        Button(action: {
                            viewModel.selectedLocation = result
                            viewModel.activeRoute = nil // Clear route to focus on location
                            searchText = result.name
                            searchResults = []
                        }) {
                            VStack(alignment: .leading) {
                                Text(result.name)
                                    .foregroundColor(.primary)
                                if let admin1 = result.admin1, let country = result.country {
                                    Text("\(admin1), \(country)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                    .frame(width: 300, height: 200)
                    .cornerRadius(8)
                    .shadow(radius: 5)
                    .offset(x: -40, y: 30) // Position under search bar
                }
            }, alignment: .top
        )
        .onReceive(timer) { _ in
            updateClocks()
        }
        .onAppear {
            updateClocks()
        }
    }
    
    private func updateClocks() {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        
        formatter.timeZone = TimeZone(identifier: "UTC")
        utcTime = formatter.string(from: Date())
        
        formatter.timeZone = .current
        localTime = formatter.string(from: Date())
    }
    
    private func performSearch(query: String) {
        isSearching = true
        let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let urlString = "https://geocoding-api.open-meteo.com/v1/search?name=\(encodedQuery)&count=5&language=en&format=json"
        
        guard let url = URL(string: urlString) else { return }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                isSearching = false
                guard let data = data else { return }
                if let decoded = try? JSONDecoder().decode(GeocodingResponse.self, from: data) {
                    self.searchResults = decoded.results ?? []
                }
            }
        }.resume()
    }
}
