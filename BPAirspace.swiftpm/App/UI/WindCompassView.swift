import SwiftUI

/// Windy-style wind direction compass showing speed + cardinal direction.
struct WindCompassView: View {
    let speed: Double        // km/h
    let direction: Int       // degrees FROM (meteorological)
    let unitSystem: String

    private var displaySpeed: String {
        unitSystem == "imperial"
            ? String(format: "%.0f", speed * 0.539957)
            : String(format: "%.0f", speed)
    }
    private var unitLabel: String { unitSystem == "imperial" ? "kts" : "km/h" }

    private var cardinal: String {
        let dirs = ["N","NNE","NE","ENE","E","ESE","SE","SSE",
                    "S","SSW","SW","WSW","W","WNW","NW","NNW"]
        let idx = Int((Double(direction) + 11.25).truncatingRemainder(dividingBy: 360) / 22.5)
        return dirs[max(0, min(idx, 15))]
    }

    /// Arrow points in the direction the wind is blowing TO
    private var arrowAngle: Double { Double((direction + 180) % 360) }

    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                // Outer ring
                Circle()
                    .stroke(Color.secondary.opacity(0.20), lineWidth: 1)
                    .frame(width: 76, height: 76)

                // Compass tick marks at N / E / S / W
                ForEach([0, 90, 180, 270], id: \.self) { deg in
                    Rectangle()
                        .fill(Color.secondary.opacity(0.4))
                        .frame(width: 1, height: 6)
                        .offset(y: -34)
                        .rotationEffect(.degrees(Double(deg)))
                }

                // "N" label
                Text("N")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundColor(.secondary)
                    .offset(y: -25)

                // Wind arrow
                Image(systemName: "location.north.fill")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [WeatherColorMap.wind(speed), WeatherColorMap.wind(speed * 0.6)],
                            startPoint: .top, endPoint: .bottom
                        )
                    )
                    .rotationEffect(.degrees(arrowAngle))
            }
            .frame(width: 76, height: 76)

            // Speed + unit
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(displaySpeed)
                    .font(.system(size: 14, weight: .bold))
                    .monospacedDigit()
                Text(unitLabel)
                    .font(.system(size: 9))
                    .foregroundColor(.secondary)
            }

            // Cardinal direction
            Text(cardinal)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.secondary)
        }
    }
}
