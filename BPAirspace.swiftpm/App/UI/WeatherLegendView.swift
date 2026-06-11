import SwiftUI

/// Windy-style horizontal colour-scale legend bar.
struct WeatherLegendView: View {
    @EnvironmentObject var viewModel: WeatherViewModel

    private var items: [(String, Color)] {
        WeatherColorMap.legendItems(for: viewModel.activeLayer)
    }

    var body: some View {
        if items.isEmpty { EmptyView() } else {
            VStack(spacing: 3) {
                // Colour bar
                HStack(spacing: 0) {
                    ForEach(items.indices, id: \.self) { i in
                        items[i].1
                    }
                }
                .frame(height: 8)
                .cornerRadius(4)

                // Labels
                HStack {
                    ForEach(items.indices, id: \.self) { i in
                        Text(items[i].0)
                            .font(.system(size: 9))
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity)
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(.ultraThinMaterial)
            .cornerRadius(10)
            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        }
    }
}
