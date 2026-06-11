import SwiftUI

struct ForecastSliderView: View {
    @EnvironmentObject var viewModel: WeatherViewModel
    
    var body: some View {
        HStack {
            Text("FORECAST")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.secondary)
            
            Slider(
                value: Binding(
                    get: { Double(viewModel.forecastIndex) },
                    set: { newValue in
                        if Int(newValue) != viewModel.forecastIndex {
                            HapticEngine.shared.selection()
                        }
                        viewModel.forecastIndex = Int(newValue)
                    }
                ),
                in: 0...71, // 3 days * 24 hours
                step: 1
            )
            .tint(.orange)
            
            Text(timeLabel)
                .font(.caption)
                .fontWeight(.bold)
                .frame(width: 80, alignment: .trailing)
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.15), radius: 10, x: 0, y: 5)
    }
    
    private var timeLabel: String {
        if viewModel.forecastIndex == 0 {
            return "Now"
        } else {
            return "+\(viewModel.forecastIndex) hrs"
        }
    }
}
