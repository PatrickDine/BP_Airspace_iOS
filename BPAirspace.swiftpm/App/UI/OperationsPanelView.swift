import SwiftUI

struct OperationsPanelView: View {
    @StateObject private var hazardEngine = HazardEngine.shared
    @StateObject private var temEngine = TEMEngine.shared
    @StateObject private var fatigueEngine = FatigueEngine.shared
    @StateObject private var aiEngine = AICopilotEngine.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Image(systemName: "sparkles")
                    .foregroundColor(.purple)
                Text("AI Copilot")
                    .font(.headline)
                    .fontWeight(.bold)
            }
            
            Text(aiEngine.currentBriefing)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            
            Divider()
            
            // Hazards
            Text("Active Hazards")
                .font(.subheadline)
                .fontWeight(.bold)
            
            if hazardEngine.activeHazards.isEmpty {
                Text("No operational hazards detected.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                ForEach(hazardEngine.activeHazards) { hazard in
                    HStack {
                        Image(systemName: hazard.severity == .severe ? "exclamationmark.triangle.fill" : "exclamationmark.circle.fill")
                            .foregroundColor(hazard.severity == .severe ? .red : .orange)
                        Text(hazard.type.rawValue)
                            .font(.caption)
                            .fontWeight(.semibold)
                    }
                }
            }
            
            Divider()
            
            // TEM Profiles
            Text("TEM Profiles")
                .font(.subheadline)
                .fontWeight(.bold)
            
            if temEngine.activeTEMs.isEmpty {
                Text("No TEM required.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                ForEach(temEngine.activeTEMs.prefix(2)) { tem in
                    VStack(alignment: .leading, spacing: 2) {
                        Text("T: \(tem.threat)").font(.caption2).bold()
                        Text("E: \(tem.potentialError)").font(.caption2).foregroundColor(.secondary)
                        Text("M: \(tem.mitigation)").font(.caption2).foregroundColor(.blue)
                    }
                    .padding(.bottom, 4)
                }
            }
            
            Divider()
            
            // Fatigue & Stress
            HStack {
                Text("Operational Stress Index:")
                    .font(.caption)
                    .fontWeight(.bold)
                Spacer()
                Text("\(fatigueEngine.operationalStressIndex)")
                    .font(.caption)
                    .monospacedDigit()
                    .padding(4)
                    .background(fatigueEngine.operationalStressIndex > 10 ? Color.orange.opacity(0.2) : Color.green.opacity(0.2))
                    .cornerRadius(4)
            }
            Text(fatigueEngine.workloadStatus.rawValue)
                .font(.caption2)
                .foregroundColor(.secondary)
            
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
    }
}
