import SwiftUI

struct ContentView: View {
    @State private var selectedTab: SidebarView.Tab = .map
    @StateObject private var weatherVM = WeatherViewModel()
    
    var body: some View {
        HStack(spacing: 0) {
            // Sidebar Navigation Rail
            SidebarView(selectedTab: $selectedTab)
            
            // Main Content Area
            ZStack {
                // Background Map Layer
                MapView(weatherVM: weatherVM)
                
                // Sliding Panels based on tab selection
                HStack {
                    Spacer()
                    if selectedTab == .route {
                        RoutePanelView()
                            .frame(width: 360)
                            .transition(.move(edge: .trailing))
                            .zIndex(1)
                    } else if selectedTab == .fuel {
                        FuelPanelView()
                            .frame(width: 360)
                            .transition(.move(edge: .trailing))
                            .zIndex(1)
                    } else if selectedTab == .ai {
                        // AI Insight Panel
                        VStack {
                            Text("AI Insights")
                                .font(.title2)
                                .fontWeight(.bold)
                            Text("Analyzing atmospheric data for optimal trajectories...")
                                .foregroundColor(AppColors.textSecondary)
                                .padding(.top, 4)
                        }
                        .padding()
                        .frame(width: 360, alignment: .topLeading)
                        .background(AppColors.bgCard)
                        .transition(.move(edge: .trailing))
                        .zIndex(1)
                    }
                }
                .animation(.easeInOut, value: selectedTab)
            }
        }
        .background(AppColors.bgDark)
        .preferredColorScheme(.light)
    }
}

// Entry Point
@main
struct BPAirspaceApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

// Preview
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
