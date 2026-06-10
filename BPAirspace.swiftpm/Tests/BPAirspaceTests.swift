import XCTest
@testable import AppModule

final class BPAirspaceTests: XCTestCase {
    
    override func setUpWithError() throws {
        // Clear shared state
        HazardEngine.shared.activeHazards = []
        TEMEngine.shared.activeTEMs = []
        FatigueEngine.shared.operationalStressIndex = 0
    }

    func testHazardEngineDetectsCrosswind() throws {
        let weather = AggregatedWeather(windSpeed: 35, windDirection: 270, temperature: 20, visibility: 5000, rawMETAR: nil)
        HazardEngine.shared.analyze(weather: weather)
        
        let expectation = expectation(description: "Hazard Engine Async")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertFalse(HazardEngine.shared.activeHazards.isEmpty, "Hazard should be detected")
            XCTAssertEqual(HazardEngine.shared.activeHazards.first?.type, .crosswind)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testTEMEngineGeneration() throws {
        let hazard = HazardEvent(type: .lowVisibility, severity: .severe, recommendation: "Use CAT III")
        TEMEngine.shared.generateTEM(from: [hazard])
        
        let expectation = expectation(description: "TEM Engine Async")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertEqual(TEMEngine.shared.activeTEMs.count, 1)
            XCTAssertEqual(TEMEngine.shared.activeTEMs.first?.threat, "Low Visibility Procedures (LVP)")
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testFatigueEngineCalculation() throws {
        let hazard1 = HazardEvent(type: .crosswind, severity: .severe, recommendation: "")
        let hazard2 = HazardEvent(type: .thunderstorms, severity: .moderate, recommendation: "")
        
        // severe = +5, moderate = +3. Flight duration = 4.5 * 2 = 9. Total = 17
        FatigueEngine.shared.calculateFatigue(hazards: [hazard1, hazard2], flightDurationHours: 4.5)
        
        let expectation = expectation(description: "Fatigue Engine Async")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertEqual(FatigueEngine.shared.operationalStressIndex, 17)
            XCTAssertEqual(FatigueEngine.shared.workloadStatus, .moderate)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testSmartAlternateEngine() throws {
        let marginalWeather = AggregatedWeather(windSpeed: 35, windDirection: 270, temperature: 20, visibility: 1000, rawMETAR: nil)
        let rank = AirportIntelligenceEngine.shared.analyzeAlternate(weather: marginalWeather, historicalDiversions: 6)
        
        // Base 100 - 40 (vis) - 30 (wind) - 20 (diversions) = 10 -> Avoid
        XCTAssertEqual(rank.rank, .avoid)
        XCTAssertEqual(rank.reasons.count, 3)
    }
    
    func testAICopilotBriefing() throws {
        let weather = AggregatedWeather(windSpeed: 10, windDirection: 270, temperature: 20, visibility: 5000, rawMETAR: nil)
        let hazard = HazardEvent(type: .thunderstorms, severity: .moderate, recommendation: "")
        
        AICopilotEngine.shared.generateBriefing(weather: weather, hazards: [hazard])
        
        let expectation = expectation(description: "AI Copilot Async")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertTrue(AICopilotEngine.shared.currentBriefing.contains("Expect deviation"))
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }
}
