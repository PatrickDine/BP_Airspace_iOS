import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = WeatherViewModel()
    @Environment(\.horizontalSizeClass) var sizeClass
    @State private var selectedTab: SidebarView.Tab = .map
    @State private var sheetDetent: PresentationDetent = .fraction(0.18)

    var body: some View {
        ZStack {
            // Full-bleed map
            MapView()
                .environmentObject(viewModel)
                .ignoresSafeArea()

            if sizeClass == .regular {
                iPadLayout
            } else {
                iPhoneLayout
            }
        }
        // iPhone bottom sheet
        .sheet(isPresented: .constant(sizeClass == .compact)) {
            iPhoneSheet
        }
    }

    // MARK: - iPad
    private var iPadLayout: some View {
        VStack(spacing: 0) {
            // Top bar
            TopBarView()
                .environmentObject(viewModel)
                .padding(.horizontal)
                .padding(.top, 16)
                .padding(.bottom, 8)

            HStack(alignment: .top, spacing: 0) {
                // Left: nav icons + layer picker
                VStack(spacing: 10) {
                    SidebarView(selectedTab: $selectedTab)
                        .environmentObject(viewModel)
                    LayerToolbarView()
                        .environmentObject(viewModel)
                }
                .padding(.leading, 12)

                Spacer()

                // Right: context panel
                VStack(spacing: 0) {
                    Group {
                        switch selectedTab {
                        case .map:
                            CurrentConditionsView().environmentObject(viewModel)
                        case .route:
                            RoutePanelView().environmentObject(viewModel)
                        case .fuel:
                            FuelPanelView()
                        case .ai:
                            OperationsPanelView()
                        }
                    }
                    .frame(maxHeight: .infinity)
                }
                .frame(width: 340)
                .padding(.trailing, 12)
            }

            Spacer()

            // Legend + timeline
            VStack(spacing: 8) {
                WeatherLegendView()
                    .environmentObject(viewModel)
                    .padding(.horizontal)

                ForecastSliderView()
                    .environmentObject(viewModel)
                    .padding(.horizontal)
            }
            .padding(.bottom, 24)
        }
    }

    // MARK: - iPhone overlay (controls only — sheet handles detail)
    private var iPhoneLayout: some View {
        VStack(spacing: 0) {
            TopBarView()
                .environmentObject(viewModel)
                .padding(.horizontal)
                .padding(.top, 16)
                .padding(.bottom, 8)

            // Layer picker
            HStack(alignment: .top) {
                LayerToolbarView()
                    .environmentObject(viewModel)
                    .padding(.leading, 12)
                Spacer()
            }

            Spacer()

            // Legend + timeline above sheet
            let sliderBottom = sheetDetent == .fraction(0.18) ? 140.0
                             : sheetDetent == .medium          ? 370.0 : 600.0
            VStack(spacing: 8) {
                WeatherLegendView()
                    .environmentObject(viewModel)
                    .padding(.horizontal)

                ForecastSliderView()
                    .environmentObject(viewModel)
                    .padding(.horizontal)
            }
            .padding(.bottom, sliderBottom)
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: sheetDetent)
        }
    }

    // MARK: - iPhone bottom sheet
    private var iPhoneSheet: some View {
        VStack(spacing: 0) {
            // Mini peek strip when collapsed
            if sheetDetent == .fraction(0.18), let pt = viewModel.currentDataPoint {
                HStack(spacing: 16) {
                    Text(wmoEmoji(pt.weatherCode)).font(.title2)
                    Text(viewModel.selectedLocation?.name ?? "Tap map")
                        .font(.subheadline).fontWeight(.semibold)
                        .lineLimit(1)
                    Spacer()
                    Text(formatTemp(pt.temperature))
                        .font(.headline).monospacedDigit()
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
            } else {
                CurrentConditionsView()
                    .environmentObject(viewModel)
                    .padding()
            }
        }
        .presentationDetents([.fraction(0.18), .medium, .large], selection: $sheetDetent)
        .presentationBackground(.ultraThinMaterial)
        .presentationDragIndicator(.visible)
        .presentationBackgroundInteraction(.enabled(upThrough: .large))
        .interactiveDismissDisabled()
    }

    // MARK: - Helpers
    private func wmoEmoji(_ code: Int) -> String {
        switch code {
        case 0: return "☀️"; case 1,2: return "🌤️"; case 3: return "☁️"
        case 45,48: return "🌫️"; case 51...65: return "🌧️"
        case 71...75: return "🌨️"; case 80...82: return "🌦️"
        case 95,96,99: return "⛈️"; default: return "🌡️"
        }
    }
    @AppStorage("unitSystem") private var unitSystem: String = "metric"
    private func formatTemp(_ c: Double) -> String {
        unitSystem == "imperial"
            ? String(format: "%.0f°F", c * 9/5 + 32)
            : String(format: "%.0f°C", c)
    }
}
