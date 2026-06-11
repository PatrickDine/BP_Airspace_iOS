import SwiftUI
import UIKit

/// Windy-style colour scales for all weather variables.
/// Each function maps a physical value to a SwiftUI Color using
/// the same meteorological palettes used by Windy.com.
struct WeatherColorMap {

    // MARK: - Temperature  (-30°C → blue … 40°C → red)
    static func temperature(_ celsius: Double) -> Color {
        let t = clamp((celsius + 30.0) / 70.0)   // -30…40 → 0…1
        return gradient(t, stops: [
            (0.00, rgb(0,   0,   200)),   // -30°C  deep blue
            (0.20, rgb(0,  90,   255)),   // -16°C  bright blue
            (0.35, rgb(0,  200,  230)),   // -5.5°C cyan
            (0.50, rgb(50, 210,   80)),   //  5°C   green
            (0.65, rgb(255, 230,   0)),   // 15.5°C yellow
            (0.80, rgb(255, 130,   0)),   // 26°C   orange
            (1.00, rgb(200,   0,   0))    // 40°C   deep red
        ])
    }

    // MARK: - Wind Speed  (0 → calm … 120+ km/h → hurricane)
    static func wind(_ kmh: Double) -> Color {
        let t = clamp(kmh / 120.0)
        return gradient(t, stops: [
            (0.00, rgb(200, 230, 255)),   // calm – very light blue
            (0.15, rgb(100, 200, 255)),   // 18 km/h
            (0.30, rgb(  0, 200, 130)),   // 36 km/h green
            (0.50, rgb(220, 220,   0)),   // 60 km/h yellow
            (0.70, rgb(255, 130,   0)),   // 84 km/h orange
            (0.85, rgb(220,   0,   0)),   // 102 km/h red
            (1.00, rgb(130,   0, 130))    // 120+  magenta
        ])
    }

    // MARK: - Rain  (0 → clear … 20+ mm → heavy)
    static func rain(_ mm: Double) -> Color {
        guard mm > 0.05 else { return .clear }
        let t = clamp(mm / 20.0)
        return gradient(t, stops: [
            (0.00, rgba(180, 200, 255, 0.30)),
            (0.25, rgba(100, 150, 255, 0.55)),
            (0.55, rgba( 50,  80, 220, 0.75)),
            (0.80, rgba(100,   0, 200, 0.90)),
            (1.00, rgba(180,   0, 180, 1.00))
        ])
    }

    // MARK: - Cloud Cover  (0 → clear … 100% → overcast)
    static func cloud(_ percent: Int) -> Color {
        let t = Double(percent) / 100.0
        if t < 0.05 { return .clear }
        return Color.white.opacity(t * 0.65)
    }

    // MARK: - Snow  (0 → none … 10+ cm → heavy)
    static func snow(_ cm: Double) -> Color {
        guard cm > 0.05 else { return .clear }
        let t = clamp(cm / 10.0)
        return Color(hue: 0.57, saturation: 0.15 + t * 0.25, brightness: 1.0).opacity(0.3 + t * 0.5)
    }

    // MARK: - Visibility  (0 m → zero vis … 10 km → clear)
    static func visibility(_ metres: Double) -> Color {
        let t = clamp(metres / 10000.0)
        if t > 0.85 { return .clear }
        return gradient(1 - t, stops: [
            (0.00, rgba(255, 255,   0, 0.15)),
            (0.50, rgba(255, 160,   0, 0.45)),
            (1.00, rgba(180,  60,   0, 0.70))
        ])
    }

    // MARK: - Humidity  (0 % → dry … 100% → saturated)
    static func humidity(_ pct: Double) -> Color {
        let t = clamp(pct / 100.0)
        return gradient(t, stops: [
            (0.00, rgb(220, 250, 220)),
            (0.50, rgb( 50, 180,  80)),
            (1.00, rgb(  0,  80, 120))
        ]).opacity(0.55)
    }

    // MARK: - Pressure  (960 → low … 1040+ hPa → high)
    static func pressure(_ hPa: Double) -> Color {
        let t = clamp((hPa - 960.0) / 80.0)
        return gradient(t, stops: [
            (0.00, rgb(180,   0, 200)),
            (0.50, rgb(100, 100, 200)),
            (1.00, rgb(  0, 200, 100))
        ]).opacity(0.60)
    }

    // MARK: - Legend Items
    static func legendItems(for layer: WeatherLayer) -> [(String, Color)] {
        switch layer {
        case .temperature:
            return [("-30", temperature(-30)), ("-15", temperature(-15)),
                    ("0",   temperature(0)),   ("15",  temperature(15)),
                    ("30",  temperature(30)),  ("40+", temperature(40))]
        case .wind:
            return [("0", wind(0)), ("20", wind(20)), ("40", wind(40)),
                    ("60", wind(60)), ("80", wind(80)), ("120+", wind(120))]
        case .rain:
            return [("0.5", rain(0.5)), ("2", rain(2)), ("5", rain(5)),
                    ("10", rain(10)), ("20+", rain(20))]
        case .clouds:
            return [("10%", cloud(10)), ("30%", cloud(30)), ("60%", cloud(60)), ("100%", cloud(100))]
        case .humidity:
            return [("20%", humidity(20)), ("50%", humidity(50)), ("80%", humidity(80)), ("100%", humidity(100))]
        case .pressure:
            return [("960", pressure(960)), ("980", pressure(980)),
                    ("1013", pressure(1013)), ("1030+", pressure(1030))]
        default:
            return []
        }
    }

    // MARK: - Private Helpers
    private static func clamp(_ v: Double) -> Double { max(0, min(1, v)) }

    private static func rgb(_ r: Int, _ g: Int, _ b: Int) -> Color {
        Color(red: Double(r)/255, green: Double(g)/255, blue: Double(b)/255)
    }

    private static func rgba(_ r: Int, _ g: Int, _ b: Int, _ a: Double) -> Color {
        Color(red: Double(r)/255, green: Double(g)/255, blue: Double(b)/255).opacity(a)
    }

    /// Multi-stop gradient interpolation
    private static func gradient(_ t: Double, stops: [(Double, Color)]) -> Color {
        guard stops.count >= 2 else { return stops.first?.1 ?? .white }
        for i in 0..<(stops.count - 1) {
            let (t0, c0) = stops[i]
            let (t1, c1) = stops[i + 1]
            if t >= t0 && t <= t1 {
                let s = (t - t0) / (t1 - t0)
                return blend(c0, c1, t: s)
            }
        }
        return stops.last!.1
    }

    private static func blend(_ a: Color, _ b: Color, t: Double) -> Color {
        var r0: CGFloat = 0, g0: CGFloat = 0, b0: CGFloat = 0, a0: CGFloat = 0
        var r1: CGFloat = 0, g1: CGFloat = 0, b1: CGFloat = 0, a1: CGFloat = 0
        UIColor(a).getRed(&r0, green: &g0, blue: &b0, alpha: &a0)
        UIColor(b).getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
        let ct = CGFloat(t)
        return Color(
            red:   Double(r0 + (r1 - r0) * ct),
            green: Double(g0 + (g1 - g0) * ct),
            blue:  Double(b0 + (b1 - b0) * ct)
        ).opacity(Double(a0 + (a1 - a0) * ct))
    }
}
