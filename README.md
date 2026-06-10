# BP Airspace Evolution

**Briefing Point GO - Aviation Operational Intelligence Platform**

BP Airspace has been radically upgraded from a simple geospatial map into a fully native iOS Operational Intelligence Engine. This repository contains the complete Swift 6 / SwiftUI implementation of the massive Intelligence Engine Matrix, natively rendering critical meteorological data using Apple MapKit and Metal.

## 🚀 Engine Architecture

The architecture has been completely decoupled into single-responsibility intelligence actors:

- **Weather Intelligence Engine (WIE)**: The core data ingestion engine. Aggregates Open-Meteo forecasts and simulated NOAA/AWC METARs using robust structured concurrency (`async/await`).
- **Hazard Engine**: Actively scans WIE feeds to detect operational threats such as Convective Activity, Wind Shear, and Low Visibility.
- **TEM Engine (Threat & Error Management)**: Analyzes detected hazards and automatically generates standardized Threat, Error, and Mitigation briefs for the flight crew.
- **Fatigue Engine**: Computes an Operational Stress Index dynamically based on environmental severity and flight duration.
- **AI Copilot Engine**: Processes numerical meteorological data into human-readable, pilot-focused guidance (e.g., "Expect deviation 20 NM due to convective activity").
- **Radar Engine**: Prepared to ingest volumetric datasets (PyART/PyCWR) and map reflectivity to MapKit Overlays using Metal Shaders.

## 📱 Human Interface Guidelines (HIG)

- **Advanced Layer Manager**: Total control over MapKit `.ultraThinMaterial` overlays for Radar, Weather, Airports, NOTAMs, and Traffic.
- **Operations Panel**: A minimalist, low-cognitive-load floating panel that aggregates TEM profiles, Fatigue status, and AI Copilot Briefings perfectly synchronized with the map.
- **Offline Reliability**: Backed by `OfflineCacheManager` to store aggregated intelligence locally to the filesystem, guaranteeing full Operational Awareness even during Airplane mode.

## 🛠️ Tech Stack

- **100% Native iOS**. No WebViews, no React Native, no Flutter.
- **Swift 6 & SwiftUI**
- **MapKit** for ultra-smooth 60fps rendering.
- **Combine & ObservableObjects** for reactive engine states.

## 📦 How to Run

1. Open `BPAirspace.swiftpm` in **Xcode 15+** or the **Swift Playgrounds App**.
2. Target an **iOS 17.0+** simulator or device.
3. If necessary, clean your build folder (`Cmd + Shift + K`).
4. Press **Play** to launch the Operational Map!
