import SwiftUI

// MARK: - Add City Search Sheet  (ported from TakefiveInteractive/WeatherMap)
struct AddCityView: View {
    @EnvironmentObject var viewModel: WeatherViewModel
    @StateObject private var store = CityStore.shared
    @Environment(\.dismiss) var dismiss

    @State private var query = ""
    @State private var results: [GeocodingResult] = []
    @State private var isSearching = false
    @State private var added: Set<Int> = []

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search bar
                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass").foregroundColor(.secondary)
                    TextField("Search airport or city…", text: $query)
                        .autocapitalization(.words)
                        .disableAutocorrection(true)
                        .onChange(of: query) { _, v in search(v) }
                    if isSearching { ProgressView().scaleEffect(0.8) }
                    if !query.isEmpty {
                        Button { query = "" } label: {
                            Image(systemName: "xmark.circle.fill").foregroundColor(.secondary)
                        }
                    }
                }
                .padding(12)
                .background(Color(UIColor.secondarySystemFill))
                .cornerRadius(12)
                .padding()

                // Results
                List(results) { result in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(result.name).fontWeight(.medium)
                            if let a1 = result.admin1, let c = result.country {
                                Text("\(a1), \(c)").font(.caption).foregroundColor(.secondary)
                            }
                        }
                        Spacer()
                        let alreadySaved = store.contains(id: result.id) || added.contains(result.id)
                        Button {
                            guard !alreadySaved else { return }
                            let city = SavedCity(from: result)
                            store.add(city)
                            added.insert(result.id)
                            HapticEngine.shared.mediumImpact()
                        } label: {
                            Image(systemName: alreadySaved ? "checkmark.circle.fill" : "plus.circle.fill")
                                .font(.title3)
                                .foregroundColor(alreadySaved ? .green : AppColors.accentGold)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.vertical, 4)
                }
                .listStyle(.plain)
            }
            .navigationTitle("Add City")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private func search(_ text: String) {
        guard text.count > 1 else { results = []; return }
        isSearching = true
        let q = text.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let url = URL(string: "https://geocoding-api.open-meteo.com/v1/search?name=\(q)&count=10&language=en&format=json")!
        URLSession.shared.dataTask(with: url) { data, _, _ in
            DispatchQueue.main.async {
                isSearching = false
                if let data, let dec = try? JSONDecoder().decode(GeocodingResponse.self, from: data) {
                    results = dec.results ?? []
                }
            }
        }.resume()
    }
}
