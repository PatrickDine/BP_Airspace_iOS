import SwiftUI

struct RoutePanelView: View {
    @State private var departure = ""
    @State private var arrival = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Route Planning")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            VStack(spacing: 12) {
                TextField("Departure (e.g. KJFK)", text: $departure)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .autocapitalization(.allCharacters)
                
                TextField("Arrival (e.g. EGLL)", text: $arrival)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .autocapitalization(.allCharacters)
            }
            
            Button(action: {
                HapticEngine.shared.heavyImpact()
                HapticEngine.shared.success()
                // Trigger AI Route calculation
            }) {
                HStack {
                    Image(systemName: "sparkles")
                    Text("Optimize with AI")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(12)
                .shadow(color: Color.blue.opacity(0.4), radius: 5, x: 0, y: 3)
            }
            
            Spacer()
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.15), radius: 10, x: 0, y: 5)
    }
}

struct FuelPanelView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Fuel Analytics")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Text("Active route fuel burn is currently being modeled based on real-time headwind vectors.")
                .foregroundColor(.secondary)
                .font(.subheadline)
            
            HStack {
                Text("Est. Burn Rate:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Text("2,400 kg/hr")
                    .font(.headline)
                    .monospacedDigit()
            }
            .padding()
            .background(Color(.secondarySystemFill))
            .cornerRadius(8)
            
            Spacer()
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.15), radius: 10, x: 0, y: 5)
    }
}
