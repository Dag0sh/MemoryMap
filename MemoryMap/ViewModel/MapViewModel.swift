import MapKit
import CoreData

@MainActor
final class MapViewModel: ObservableObject {
    @Published var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 55.751244, longitude: 37.618423),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    @Published var pins: [MemoryPin] = []

    private let context = CoreDataStack.shared.context

    func fetchPins() {
        let request: NSFetchRequest<MemoryPin> = MemoryPin.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \MemoryPin.date, ascending: false)]
        do {
            pins = try context.fetch(request)
        } catch {
            print("❌ Fetch error: \(error)")
        }
    }

    func addPin(title: String?, sticker: String?, location: CLLocation?, images: [UIImage]) {
        let pin = MemoryPin(context: context)
        pin.id = UUID()
        pin.title = title
        pin.date = Date()
        pin.sticker = sticker
        if let loc = location {
            pin.latitude = loc.coordinate.latitude
            pin.longitude = loc.coordinate.longitude
        }

        for img in images {
            if let data = img.jpegData(compressionQuality: 0.8) {
                let photo = PhotoEntity(context: context)
                photo.id = UUID()
                photo.imageData = data
                photo.date = Date()
                photo.pin = pin
            }
        }

        CoreDataStack.shared.save()
        fetchPins()
    }
}
