import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = WeatherViewModel()
    @Environment(\.horizontalSizeClass) var sizeClass
    
    // Bottom Sheet state for iPhone
    @State private var showConditionsSheet = true
    
    // Sidebar state
    @State private var selectedTab: SidebarView.Tab = .map
    
    var body: some View {
        ZStack {
            // Main Map Background
            MapView()
                .environmentObject(viewModel)
                .ignoresSafeArea()
            
            if sizeClass == .regular {
                // iPad / Mac Layout (Floating Panels)
                VStack {
                    TopBarView()
                        .environmentObject(viewModel)
                        .padding(.horizontal)
                        .padding(.top, 16)
                    
                    HStack(alignment: .top) {
                        SidebarView(selectedTab: $selectedTab) // The original sidebar with navigation icons
                            .environmentObject(viewModel)
                            .padding(.leading)
                        
                        LayerToolbarView()
                            .environmentObject(viewModel)
                            .padding(.leading, 8)
                        
                        Spacer()
                        
                        VStack(spacing: 16) {
                            OperationsPanelView()
                                .frame(width: 320)
                            
                            CurrentConditionsView()
                                .environmentObject(viewModel)
                                .frame(width: 320)
                        }
                        .padding(.trailing)
                    }
                    
                    Spacer()
                    
                    ForecastSliderView()
                        .environmentObject(viewModel)
                        .padding(.horizontal)
                        .padding(.bottom, 24)
                }
            } else {
                // iPhone Layout (Compact)
                VStack {
                    TopBarView()
                        .environmentObject(viewModel)
                        .padding(.horizontal)
                        .padding(.top, 16)
                    
                    HStack(alignment: .top) {
                        LayerToolbarView()
                            .environmentObject(viewModel)
                            .padding(.horizontal)
                        Spacer()
                    }
                    
                    Spacer()
                    
                    ForecastSliderView()
                        .environmentObject(viewModel)
                        .padding(.horizontal)
                        .padding(.bottom, 100) // Padding for sheet
                }
            }
        }
        .sheet(isPresented: .constant(sizeClass == .compact)) {
            // Bottom Sheet for iPhone
            CurrentConditionsView()
                .environmentObject(viewModel)
                .presentationDetents([.medium, .large])
                .presentationBackground(.ultraThinMaterial)
                .presentationDragIndicator(.visible)
                .interactiveDismissDisabled()
        }
    }
}
