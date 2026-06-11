import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                Section(header: Text("General")) {
                    NavigationLink(destination: Text("Units & Preferences (Coming Soon)").navigationTitle("Units")) {
                        Label("Units", systemImage: "ruler")
                    }
                    NavigationLink(destination: Text("Map Settings (Coming Soon)").navigationTitle("Map Options")) {
                        Label("Map Options", systemImage: "map")
                    }
                }
                
                Section(header: Text("Information")) {
                    NavigationLink(destination: AboutView()) {
                        Label("About BP Airspace", systemImage: "info.circle")
                    }
                    NavigationLink(destination: LegalView()) {
                        Label("Legal & Privacy", systemImage: "doc.text")
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct AboutView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Image(systemName: "airplane")
                    .font(.system(size: 60))
                    .foregroundColor(.orange)
                    .padding(.top, 40)
                
                Text("BP Airspace")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Version 1.0.0")
                    .foregroundColor(.secondary)
                
                Text("BP Airspace is a premium, native iOS aviation situational awareness platform designed to bring Apple-quality design to flight planning and tracking.")
                    .multilineTextAlignment(.center)
                    .padding()
                
                Spacer()
            }
        }
        .navigationTitle("About")
    }
}

struct LegalView: View {
    var body: some View {
        List {
            NavigationLink(destination: EULAView()) {
                Text("End User License Agreement (EULA)")
            }
            NavigationLink(destination: PrivacyPolicyView()) {
                Text("Privacy Policy")
            }
        }
        .navigationTitle("Legal")
    }
}

struct EULAView: View {
    var body: some View {
        ScrollView {
            Text("""
            End User License Agreement (EULA)
            
            This is a standard end-user license agreement for BP Airspace. By using this application, you agree that this software is provided for situational awareness only and should not be used as a primary means of navigation.
            
            1. License Grant
            You are granted a revocable, non-exclusive, non-transferable, limited right to install and use the application on wireless electronic devices owned or controlled by you.
            
            2. Restrictions on Use
            You agree not to use the application in a manner that could compromise flight safety or violate aviation regulations.
            
            3. Disclaimer of Warranty
            The application is provided "AS IS", without warranty of any kind.
            """)
            .padding()
        }
        .navigationTitle("EULA")
    }
}

struct PrivacyPolicyView: View {
    var body: some View {
        ScrollView {
            Text("""
            Privacy Policy
            
            Your privacy is critically important to us.
            
            1. Data Collection
            We do not collect or store your location data or flight plans on our servers without your explicit consent. All cached weather data and flight routes are stored locally on your device using SwiftData/FileManager.
            
            2. Third-Party Services
            We utilize Open-Meteo for weather forecasting. Your search queries and location coordinates may be sent to these services anonymously to retrieve weather information.
            
            3. Changes
            We reserve the right to modify this privacy policy at any time.
            """)
            .padding()
        }
        .navigationTitle("Privacy Policy")
    }
}
