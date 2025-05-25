//
//  TrackingSessionTests.swift
//  TrackingTests
//

// TrackingTests/TrackingSessionTests.swift
import XCTest
import CoreData
import CoreLocation
@testable import Tracking

class TrackingSessionTests: XCTestCase {
    var context: NSManagedObjectContext!
    var container: NSPersistentContainer!
    
    override func setUp() {
        super.setUp()
        container = NSPersistentContainer.inMemoryContainer(name: "Tracking")
        context = container.viewContext
        
        // Core Data Model Setup
        let entity = NSEntityDescription.entity(forEntityName: "TrackingSession", in: context)!
        let _ = NSManagedObject(entity: entity, insertInto: context)
    }
    
    override func tearDown() {
        context = nil
        container = nil
        super.tearDown()
    }
    
    func testDistanceCalculation() throws {
        let session = TrackingSession(context: context)
        session.startTime = Date()
        
        // Realistische Testdaten (Berliner Dom → Alexanderplatz → Museum für Naturkunde)
        addLocation(to: session, lat: 52.519008, lon: 13.401236) // Berliner Dom
        addLocation(to: session, lat: 52.521518, lon: 13.413408) // Alexanderplatz (~1km östlich)
        addLocation(to: session, lat: 52.530982, lon: 13.413408) // Museum für Naturkunde (~1km nördlich)
        
        // Vorberechnete Distanzen mit CoreLocation
        let loc1 = CLLocation(latitude: 52.519008, longitude: 13.401236)
        let loc2 = CLLocation(latitude: 52.521518, longitude: 13.413408)
        let loc3 = CLLocation(latitude: 52.530982, longitude: 13.413408)
        
        let expectedDistance12 = loc1.distance(from: loc2)
        let expectedDistance23 = loc2.distance(from: loc3)
        let expectedTotal = expectedDistance12 + expectedDistance23
        
        // Test
        session.updateMetrics()
        
        XCTAssertEqual(session.totalDistance, expectedTotal, accuracy: 1.0,
                       "Distanzberechnung stimmt nicht überein")
        
        print("""
        Test-Ergebnisse:
        - Berechnete Distanz: \(session.totalDistance)m
        - Erwartete Distanz: \(expectedTotal)m
        - Differenz: \(abs(session.totalDistance - expectedTotal))m
        """)
    }
    
    private func addLocation(to session: TrackingSession, lat: Double, lon: Double) {
        let loc = SavedLocation(context: context)
        loc.latitude = lat
        loc.longitude = lon
        loc.timestamp = Date()
        session.addToLocations(loc)
    }
}
