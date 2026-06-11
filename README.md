# BP Airspace — Professional Aviation Weather iOS App

> A Windy.com-grade interactive weather platform built for professional pilots, designed with Apple's Human Interface Guidelines.

![Platform](https://img.shields.io/badge/Platform-iOS%2017%2B%20%7C%20iPadOS%2017%2B-blue)
![Swift](https://img.shields.io/badge/Swift-5.9-orange)
![License](https://img.shields.io/badge/License-Proprietary-red)
![Build](https://img.shields.io/badge/Build-Passing-brightgreen)

---

## ✈️ Overview

BP Airspace is a native iOS/iPadOS weather application built specifically for professional aviation use. It provides real-time, interactive weather visualization powered by the **Open-Meteo** free weather API, with a user experience modelled after **Windy.com**.

---

## 🌟 Core Features

### 🗺️ Interactive Map (Windy-style)
- **Tap anywhere on the map** to instantly inspect live weather at that exact coordinate
- Animated **pulsing pin** drops at the tapped location
- Full 7-day hourly forecast loaded per tap

### 🌬️ Animated Wind Particles
- Real-time **animated wind streamlines** rendered on Canvas (GPU-accelerated, 30fps)
- Particle speed and density scale with actual wind speed
- Particle colour follows the meteorological wind colour scale (calm → hurricane)
- Direction driven by real wind direction data (meteorological FROM convention)

### 🎨 Real Colour-Coded Weather Overlays
- **8 selectable layers** — single-select (radio button) like Windy:
  - 🌬️ Wind, 🌡️ Temperature, 🌧️ Rain, ☁️ Clouds, ❄️ Snow, 👁️ Visibility, 💧 Humidity, 📊 Pressure
- **MapCircle overlays** at a 3×3 grid covering the visible viewport, each coloured by real data
- Grid auto-refreshes when you finish panning or zooming
- Colour scales match meteorological standards (blue → green → yellow → red)

### ⏱️ 7-Day Forecast Timeline
- **Real UTC date/time labels** at every forecast step
- **Day separator markers** (Today / Tomorrow / Mon / Tue …)
- ▶️ **Play/Pause animation** that auto-advances through the forecast
- ⏮️ Reset to Now button
- Active layer indicator chip showing current selection

### 📊 24-Hour Weather Chart
- **Swift Charts** line + area chart for any active layer
- 6-hour X-axis gridlines with time labels
- **Current forecast index marker** tracks the slider position
- Variable switches based on active layer (temp, wind, rain, cloud, etc.)
- Unit-system aware (metric / imperial)

### 🧭 Wind Compass
- Visual **direction rose** with rotating arrow
- Arrow coloured by wind speed (calm = light blue, gale = red)
- Displays speed, unit, and cardinal direction (N / NNE / NE …)

### 🛫 Route Planning with Real Weather
- Enter **ICAO codes or city names** for departure & arrival
- Geocoded via Open-Meteo's free geocoding API
- **7 waypoints** interpolated along great-circle route
- Live weather fetched at each waypoint
- **Safety colour coding**: 🟢 Safe / 🟡 Caution / 🔴 Danger per waypoint
- Safety summary banner with routing advice

### 📱 iPhone Bottom Sheet (Windy-mobile style)
- **3-detent sheet**: Peek (collapsed) → Medium → Full
- Collapsed state shows emoji icon, location name, and temperature at a glance
- Expand to see full conditions panel and 24hr chart

### ⚙️ Settings
- Unit System: **Metric** (km/h, °C, mm) or **Imperial** (kts, °F, in)
- **Home Airport**: Search and save — app opens on your home airport every launch
- About, EULA, Privacy Policy pages

---

## 🏗️ Architecture

```
BPAirspace.swiftpm/
├── App/
│   ├── WeatherModels.swift        — ViewModel, data models, API layer
│   ├── Engines/
│   │   ├── CoreEngines.swift      — AI Copilot, TEM, Fatigue, Traffic engines
│   │   ├── HazardEngine.swift     — Aviation hazard detection
│   │   └── WeatherAndAirspaceEngines.swift
│   └── UI/
│       ├── ContentView.swift      — Root layout (iPad panels + iPhone sheet)
│       ├── MapView.swift          — MapReader tap, MapCircle overlays, particles
│       ├── LayerToolbarView.swift — 8-layer radio picker
│       ├── ForecastSliderView.swift — Real timestamps + play/pause
│       ├── CurrentConditionsView.swift — WMO emoji, stats grid, chart
│       ├── WeatherChartView.swift — Swift Charts 24hr line chart
│       ├── WeatherColorMap.swift  — Meteorological colour scales
│       ├── WeatherLegendView.swift — Colour scale legend bar
│       ├── WindParticleView.swift — Canvas-based animated wind particles
│       ├── WindCompassView.swift  — Direction rose with speed
│       ├── RoutePanelView.swift   — Route planning + waypoint weather
│       ├── OperationsPanelView.swift — AI briefing + TEM profiles
│       ├── SettingsView.swift     — Units, home airport, legal pages
│       ├── TopBarView.swift       — Search + clock bar
│       └── SidebarView.swift      — iPad navigation tabs
```

---

## 🌐 Data Sources

| Source | Usage |
|---|---|
| [Open-Meteo](https://open-meteo.com/) | 7-day hourly forecast (temperature, wind, rain, snow, clouds, visibility, humidity, pressure) |
| [Open-Meteo Geocoding](https://geocoding-api.open-meteo.com/) | Airport/city search and route geocoding |

All data is **free, no API key required**. Data is cached locally for offline access.

---

## 🛠️ Requirements

- **Xcode 15+** or **Swift Playgrounds 4.5+**
- **iOS 17.0+** / **iPadOS 17.0+**
- Active internet connection for live weather (offline fallback available)

---

## 🚀 Getting Started

1. Clone this repository
2. Open `BPAirspace.swiftpm` in Xcode or Swift Playgrounds
3. Select your development team in Signing & Capabilities
4. Build and run on a device or simulator

---

## 📋 Changelog

### v1.1.0 — Windy.com Feature Replication
- ✅ Tap-to-inspect: tap any map point to load live weather
- ✅ Animated wind particle system (30fps Canvas)
- ✅ Real weather colour overlays via 3×3 viewport grid
- ✅ 7-day forecast with real UTC timestamps + play/pause
- ✅ 24-hour Swift Charts weather chart per layer
- ✅ Wind compass with direction rose
- ✅ Functional route planning with geocoding + waypoint weather
- ✅ Safety colour coding for route segments
- ✅ iPhone 3-detent bottom sheet
- ✅ Windy-style colour scales (temp, wind, rain, cloud, snow, vis, humidity, pressure)

### v1.0.0 — Initial Release
- Core map + weather layers
- Settings (units, home airport, EULA, privacy)
- AI Copilot, TEM, Fatigue engines

---

## 📄 License

Proprietary — © BP Airspace. All rights reserved.
