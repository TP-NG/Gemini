//
//  TestHelpers.swift
//  TrackingTests
//

// TrackingTests/TestHelpers.swift
import CoreData

extension NSPersistentContainer {
    static func inMemoryContainer(name: String) -> NSPersistentContainer {
        let container = NSPersistentContainer(name: name)
        let description = NSPersistentStoreDescription()
        description.url = URL(fileURLWithPath: "/dev/null")
        description.type = NSInMemoryStoreType
        container.persistentStoreDescriptions = [description]
        
        container.loadPersistentStores { _, error in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }
        return container
    }
}
