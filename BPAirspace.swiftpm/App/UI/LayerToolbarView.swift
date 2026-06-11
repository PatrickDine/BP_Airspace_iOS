import SwiftUI

struct LayerToolbarView: View {
    @EnvironmentObject var viewModel: WeatherViewModel
    @Environment(\.horizontalSizeClass) var sizeClass
    
    var body: some View {
        if sizeClass == .compact {
            // Horizontal scroll for iPhone
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(WeatherLayer.allCases) { layer in
                        LayerButton(layer: layer)
                    }
                }
                .padding()
            }
            .background(.ultraThinMaterial)
            .cornerRadius(12)
        } else {
            // Vertical stack for iPad
            VStack(spacing: 12) {
                ForEach(WeatherLayer.allCases) { layer in
                    LayerButton(layer: layer)
                }
            }
            .padding(12)
            .background(.ultraThinMaterial)
            .cornerRadius(16)
        }
    }
}

struct LayerButton: View {
    let layer: WeatherLayer
    @EnvironmentObject var viewModel: WeatherViewModel
    
    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                viewModel.toggleLayer(layer)
            }
            HapticEngine.shared.lightImpact()
        }) {
            Image(systemName: layer.iconName)
                .font(.system(size: 20))
                .foregroundColor(viewModel.activeLayers.contains(layer) ? .white : .primary)
                .frame(width: 44, height: 44)
                .background(viewModel.activeLayers.contains(layer) ? Color.blue : Color(UIColor.systemBackground).opacity(0.6))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(color: .black.opacity(0.1), radius: 3, x: 0, y: 2)
        }
    }
}
