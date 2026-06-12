import SwiftUI

struct SidebarView: View {
    @Binding var selectedTab: Tab
    
    enum Tab {
        case map, route, fuel, ai, cities
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // Logo
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(AppColors.accentGold)
                    .frame(width: 38, height: 38)
                Text("BP")
                    .font(.system(size: 20, weight: .bold, design: .default))
                    .foregroundColor(.white)
            }
            .padding(.top, 20)
            .padding(.bottom, 20)
            
            // Nav Items
            NavItem(icon: "map.fill", isSelected: selectedTab == .map) {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                    selectedTab = .map
                }
                HapticEngine.shared.selection()
            }
            NavItem(icon: "airplane", isSelected: selectedTab == .route) {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                    selectedTab = .route
                }
                HapticEngine.shared.selection()
            }
            NavItem(icon: "fuelpump.fill", isSelected: selectedTab == .fuel) {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                    selectedTab = .fuel
                }
                HapticEngine.shared.selection()
            }
            NavItem(icon: "sparkles", isSelected: selectedTab == .ai) {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                    selectedTab = .ai
                }
                HapticEngine.shared.selection()
            }
            NavItem(icon: "building.2.fill", isSelected: selectedTab == .cities) {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                    selectedTab = .cities
                }
                HapticEngine.shared.selection()
            }

            Spacer()
        }
        .frame(width: 64)
        .background(.ultraThinMaterial)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
    }
}

struct NavItem: View {
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(isSelected ? AppColors.accentGold : AppColors.textSecondary)
                .frame(width: 44, height: 44)
                .background(isSelected ? AppColors.accentGold.opacity(0.15) : Color.clear)
                .cornerRadius(12)
                .overlay(
                    HStack {
                        if isSelected {
                            Rectangle()
                                .fill(AppColors.accentGold)
                                .frame(width: 3, height: 24)
                                .cornerRadius(1.5)
                        }
                    },
                    alignment: .leading
                )
        }
    }
}
