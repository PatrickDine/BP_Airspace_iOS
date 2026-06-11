import SwiftUI

// MARK: - Particle Model
private struct WindParticle {
    var x: CGFloat
    var y: CGFloat
    var opacity: Double
    var tailLen: CGFloat
    var speedMult: CGFloat   // per-particle speed multiplier for variety
}

// MARK: - Particle System
private class WindParticleSystem: ObservableObject {
    @Published var particles: [WindParticle] = []
    private var timer: Timer?
    private var size: CGSize = .zero

    var windSpeed: Double = 20      // km/h
    var windDirection: Int = 270    // FROM degrees

    /// Destination unit vector in screen coordinates
    private var dx: CGFloat {
        let rad = Double((windDirection + 180) % 360) * .pi / 180.0
        return CGFloat(sin(rad))
    }
    private var dy: CGFloat {
        let rad = Double((windDirection + 180) % 360) * .pi / 180.0
        return CGFloat(-cos(rad))
    }
    /// Base pixels-per-tick
    private var baseSpeed: CGFloat {
        CGFloat(min(windSpeed / 25.0, 5.0)) + 0.4
    }

    func start(in size: CGSize) {
        self.size = size
        if particles.isEmpty { spawn(count: particleCount) }
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0 / 30.0, repeats: true) { [weak self] _ in
            self?.step()
        }
    }

    func stop() { timer?.invalidate(); timer = nil }

    func update(speed: Double, direction: Int) {
        windSpeed     = speed
        windDirection = direction
    }

    private var particleCount: Int { max(50, min(Int(windSpeed * 2.5), 160)) }

    private func spawn(count: Int) {
        particles = (0..<count).map { _ in
            WindParticle(
                x:         CGFloat.random(in: 0...size.width),
                y:         CGFloat.random(in: 0...size.height),
                opacity:   Double.random(in: 0.25...0.85),
                tailLen:   CGFloat.random(in: 12...35),
                speedMult: CGFloat.random(in: 0.6...1.6)
            )
        }
    }

    private func step() {
        let stepX = dx * baseSpeed
        let stepY = dy * baseSpeed
        let margin: CGFloat = 60

        for i in particles.indices {
            particles[i].x += stepX * particles[i].speedMult
            particles[i].y += stepY * particles[i].speedMult
            particles[i].opacity -= 0.008

            let oob = particles[i].x < -margin || particles[i].x > size.width  + margin
                   || particles[i].y < -margin || particles[i].y > size.height + margin
            let dead = particles[i].opacity <= 0

            if oob || dead {
                // Respawn on the upwind edge
                if abs(stepX) >= abs(stepY) {
                    // Predominantly horizontal wind
                    particles[i].x = stepX > 0 ? -margin : size.width + margin
                    particles[i].y = CGFloat.random(in: 0...size.height)
                } else {
                    particles[i].x = CGFloat.random(in: 0...size.width)
                    particles[i].y = stepY > 0 ? -margin : size.height + margin
                }
                particles[i].opacity   = Double.random(in: 0.45...0.90)
                particles[i].speedMult = CGFloat.random(in: 0.6...1.6)
            }
        }
    }
}

// MARK: - Wind Particle View
struct WindParticleView: View {
    @EnvironmentObject var viewModel: WeatherViewModel
    @StateObject private var system = WindParticleSystem()

    var body: some View {
        GeometryReader { geo in
            Canvas { ctx, size in
                let speed = system.windSpeed
                let dir   = system.windDirection
                let destRad = Double((dir + 180) % 360) * .pi / 180.0
                let color = WeatherColorMap.wind(speed)

                for p in system.particles {
                    // Tail
                    let tailEndX = p.x - CGFloat(sin(destRad)) * p.tailLen
                    let tailEndY = p.y + CGFloat(cos(destRad)) * p.tailLen
                    var path = Path()
                    path.move(to: CGPoint(x: p.x, y: p.y))
                    path.addLine(to: CGPoint(x: tailEndX, y: tailEndY))
                    ctx.stroke(path,
                               with: .color(color.opacity(p.opacity * 0.8)),
                               lineWidth: 1.4)
                    // Head dot
                    let dot = CGRect(x: p.x - 2, y: p.y - 2, width: 4, height: 4)
                    ctx.fill(Path(ellipseIn: dot),
                             with: .color(color.opacity(min(p.opacity + 0.15, 1.0))))
                }
            }
            .onAppear {
                if let pt = viewModel.currentDataPoint {
                    system.update(speed: pt.windSpeed, direction: pt.windDirection)
                }
                system.start(in: geo.size)
            }
            .onDisappear { system.stop() }
            .onChange(of: viewModel.currentDataPoint?.windSpeed) { _, v in
                if let v = v { system.windSpeed = v }
            }
            .onChange(of: viewModel.currentDataPoint?.windDirection) { _, v in
                if let v = v { system.windDirection = v }
            }
        }
    }
}
