import CoreData

final class CoreDataStack {
    static let shared = CoreDataStack()

    let container: NSPersistentContainer

    private init() {
        container = NSPersistentContainer(name: "MemoryMap")
        container.loadPersistentStores { _, error in
            if let error = error {
                fatalError("❌ Core Data load error: \(error)")
            }
        }
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }

    var context: NSManagedObjectContext {
        container.viewContext
    }

    func save() {
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                print("❌ Save error: \(error)")
            }
        }
    }
}
