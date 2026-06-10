import SwiftUI

struct SidebarView: View {
    @Binding var selectedTab: Tab
    
    enum Tab {
        case map, route, fuel, ai
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // Logo
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(AppColors.accentGold)
                    .frame(width: 38, height: 38)
                Text("P")
                    .font(.system(size: 20, weight: .bold, design: .default))
                    .foregroundColor(.white)
            }
            .padding(.top, 20)
            .padding(.bottom, 20)
            
            // Nav Items
            NavItem(icon: "map.fill", isSelected: selectedTab == .map) {
                selectedTab = .map
            }
            NavItem(icon: "airplane", isSelected: selectedTab == .route) {
                selectedTab = .route
            }
            NavItem(icon: "fuelpump.fill", isSelected: selectedTab == .fuel) {
                selectedTab = .fuel
            }
            NavItem(icon: "sparkles", isSelected: selectedTab == .ai) {
                selectedTab = .ai
            }
            
            Spacer()
        }
        .frame(width: 64)
        .background(AppColors.bgCard)
        .overlay(
            Rectangle()
                .frame(width: 1)
                .foregroundColor(AppColors.textSecondary.opacity(0.1)),
            alignment: .trailing
        )
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
                .cornerRadius(8)
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
