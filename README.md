# BP Airspace - iOS Native MapKit Port

A completely native iOS re-implementation of the BP Airspace web dashboard, optimized specifically for **iOS 17+** with advanced **Human Interface Guidelines (HIG)** compliance and offline capabilities.

## 🚀 Features

- **HIG-Optimized Layouts:** 
    - **iPad/Mac (.regular)**: Utilizes gorgeous ultra-thin material floating panels over a full-screen map to mimic the premium web experience.
    - **iPhone (.compact)**: Intelligently adapts floating panels into native resizable bottom sheets and scrollable horizontal toolbars.
- **Open-Meteo Integration**: Live dynamic fetches of hourly weather data (Wind, Clouds, Temp, Rain, Snow, Visibility).
- **Offline Caching Engine**: Custom `OfflineCacheManager` seamlessly caches JSON responses from the Geocoding and Weather APIs to the local FileSystem. The app functions flawlessly in Airplane mode once routes are loaded.
- **Native Routing**: Utilizes iOS 17's `MapPolyline` and `MapCameraPosition` for hyper-smooth flight path rendering.
- **Interactive UI**: Forecast slider, live UTC/Local clocks, and interactive layer toggles.

## 🛠️ Tech Stack

- **SwiftUI** for all declarative UI.
- **MapKit** native rendering (Zero web-views).
- **URLSession & Codable** for network and robust offline JSON decoding.

## 📦 How to Run

1. Open `BPAirspace.swiftpm` in **Xcode 15+** or the **Swift Playgrounds App**.
2. Make sure your target is an **iOS 17.0+** device or simulator.
3. If you see ghost warnings regarding Asset Catalogs, run `Cmd + Shift + K` to clean the build folder.
4. Hit **Play**!
