import CoreData

enum CoreDataError: Error, LocalizedError {
    case saveFailed(Error)
    case fetchFailed(Error)
    case deleteFailed(Error)
    
    var errorDescription: String? {
        switch self {
        case .saveFailed(let error):
            return "Не удалось сохранить данные: \(error.localizedDescription)"
        case .fetchFailed(let error):
            return "Не удалось загрузить данные: \(error.localizedDescription)"
        case .deleteFailed(let error):
            return "Не удалось удалить данные: \(error.localizedDescription)"
        }
    }
}

final class CoreDataStack {
    static let shared = CoreDataStack()

    let container: NSPersistentContainer
    private let modelName: String

    private init(modelName: String = "MemoryMap") {
        self.modelName = modelName
        container = NSPersistentContainer(name: modelName)

        let description = container.persistentStoreDescriptions.first
        description?.shouldMigrateStoreAutomatically = true
        description?.shouldInferMappingModelAutomatically = true

        container.loadPersistentStores { _, error in
            if let error = error {
                fatalError("❌ Core Data load error: \(error)")
            }
        }
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }

    var context: NSManagedObjectContext {
        container.viewContext
    }
    
    /// Создает фоновый контекст для тяжелых операций
    func newBackgroundContext() -> NSManagedObjectContext {
        return container.newBackgroundContext()
    }

    /// Сохраняет изменения в контексте с обработкой ошибок
    /// - Throws: CoreDataError если сохранение не удалось
    func save() throws {
        guard context.hasChanges else { return }
        
        do {
            try context.save()
        } catch {
            context.rollback()
            throw CoreDataError.saveFailed(error)
        }
    }
    
    /// Выполняет операцию в фоновом контексте
    /// - Parameter block: Блок кода для выполнения
    func performBackgroundTask(_ block: @escaping (NSManagedObjectContext) -> Void) {
        container.performBackgroundTask(block)
    }
}
