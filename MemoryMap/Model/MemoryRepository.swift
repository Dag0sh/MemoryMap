import CoreData
import CoreLocation
import UIKit

final class MemoryRepository {
    private let coreDataStack: CoreDataStack
    private var context: NSManagedObjectContext { coreDataStack.context }

    init(coreDataStack: CoreDataStack = .shared) {
        self.coreDataStack = coreDataStack
    }

    // MARK: - Fetch

    func fetchAllPins() throws -> [MemoryPin] {
        let request: NSFetchRequest<MemoryPin> = MemoryPin.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \MemoryPin.date, ascending: false)]
        do {
            return try context.fetch(request)
        } catch {
            throw CoreDataError.fetchFailed(error)
        }
    }

    // MARK: - Create

    /// `configuration.coordinate` — явный выбор пользователя (приоритет).
    /// `fallbackLocation` — GPS-координата, если пользователь не выбрал вручную.
    func createPin(configuration: PinConfiguration,
                   fallbackLocation: CLLocation? = nil) throws -> MemoryPin {
        let pin = MemoryPin(context: context)
        pin.id = UUID()
        pin.title = configuration.title
        pin.sticker = configuration.sticker
        pin.date = Date()

        let coord = configuration.coordinate ?? fallbackLocation?.coordinate
        if let c = coord {
            pin.latitude  = c.latitude
            pin.longitude = c.longitude
        }

        attachPhotos(configuration.images, to: pin)
        try coreDataStack.save()
        return pin
    }

    // MARK: - Update

    func updatePin(_ pin: MemoryPin, configuration: PinConfiguration) throws {
        pin.title = configuration.title
        pin.sticker = configuration.sticker
        pin.updatedAt = Date()
        if let c = configuration.coordinate {
            pin.latitude  = c.latitude
            pin.longitude = c.longitude
        }
        attachPhotos(configuration.images, to: pin)
        try coreDataStack.save()
    }

    // MARK: - Delete

    func deletePin(_ pin: MemoryPin) throws {
        context.delete(pin)
        try coreDataStack.save()
    }

    func deletePhoto(_ photo: PhotoEntity) throws {
        context.delete(photo)
        try coreDataStack.save()
    }

    // MARK: - Private

    private func attachPhotos(_ images: [UIImage], to pin: MemoryPin) {
        for image in images {
            guard let data = PhotoService.compressImage(image, quality: 0.8) else { continue }
            let photo = PhotoEntity(context: context)
            photo.id = UUID()
            photo.imageData = data
            photo.date = Date()
            photo.pin = pin
        }
    }
}
