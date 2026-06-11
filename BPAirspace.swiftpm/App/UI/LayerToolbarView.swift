import SwiftUI

struct LayerToolbarView: View {
    @EnvironmentObject var viewModel: WeatherViewModel
    @Environment(\.horizontalSizeClass) var sizeClass

    var body: some View {
        if sizeClass == .compact {
            // iPhone: horizontal scroll strip
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(WeatherLayer.allCases) { layer in
                        LayerButton(layer: layer)
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
            }
            .background(.ultraThinMaterial)
            .cornerRadius(14)
        } else {
            // iPad: vertical strip
            VStack(spacing: 6) {
                ForEach(WeatherLayer.allCases) { layer in
                    LayerButton(layer: layer)
                }
            }
            .padding(8)
            .background(.ultraThinMaterial)
            .cornerRadius(16)
        }
    }
}

struct LayerButton: View {
    let layer: WeatherLayer
    @EnvironmentObject var viewModel: WeatherViewModel

    private var isActive: Bool { viewModel.activeLayer == layer }

    var body: some View {
        Button {
            withAnimation(.spring(response: 0.30, dampingFraction: 0.68)) {
                viewModel.activeLayer = layer
            }
            HapticEngine.shared.lightImpact()
        } label: {
            VStack(spacing: 3) {
                Image(systemName: layer.iconName)
                    .font(.system(size: 17, weight: .semibold))
                    .frame(width: 42, height: 42)
                    .foregroundStyle(isActive ? .white : layer.accentColor)
                    .background(
                        RoundedRectangle(cornerRadius: 11, style: .continuous)
                            .fill(isActive ? layer.accentColor : layer.accentColor.opacity(0.12))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 11, style: .continuous)
                            .stroke(isActive ? layer.accentColor : .clear, lineWidth: 1.5)
                    )
                    .shadow(color: isActive ? layer.accentColor.opacity(0.45) : .clear,
                            radius: 6, x: 0, y: 3)

                Text(layer.rawValue)
                    .font(.system(size: 9, weight: isActive ? .bold : .medium))
                    .foregroundColor(isActive ? layer.accentColor : .secondary)
            }
            .frame(width: 52)
        }
        .buttonStyle(.plain)
        .scaleEffect(isActive ? 1.06 : 1.0)
        .animation(.spring(response: 0.30, dampingFraction: 0.68), value: isActive)
    }
}
