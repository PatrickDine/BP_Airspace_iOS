import SwiftUI

struct RoutePanelView: View {
    @State private var departure = ""
    @State private var arrival = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Route Planning")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(AppColors.textPrimary)
            
            VStack(spacing: 12) {
                TextField("Departure (e.g. KJFK)", text: $departure)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .autocapitalization(.allCharacters)
                
                TextField("Arrival (e.g. EGLL)", text: $arrival)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .autocapitalization(.allCharacters)
            }
            
            Button(action: {
                // Trigger AI Route calculation
            }) {
                HStack {
                    Image(systemName: "sparkles")
                    Text("Optimize with AI")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(AppColors.accentGold)
                .foregroundColor(.white)
                .cornerRadius(8)
                .shadow(color: AppColors.accentGold.opacity(0.4), radius: 5, x: 0, y: 3)
            }
            
            Spacer()
        }
        .padding()
        .background(AppColors.bgCard)
    }
}

struct FuelPanelView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Fuel Analytics")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(AppColors.textPrimary)
            
            Text("Coming Soon: Real-time fuel burn modeling based on weather patterns.")
                .foregroundColor(AppColors.textSecondary)
                .font(.subheadline)
            
            Spacer()
        }
        .padding()
        .background(AppColors.bgCard)
    }
}
