import MapKit

// Аннотация пина с (возможно скорректированными) координатами для отображения
struct PinAnnotation: Identifiable {
    let id: UUID
    let pin: MemoryPin
    let coordinate: CLLocationCoordinate2D
}

@MainActor
final class MapViewModel: ObservableObject {
    @Published var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 55.751244, longitude: 37.618423),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    ) {
        didSet { updateAnnotations() }
    }
    @Published var pins: [MemoryPin] = [] {
        didSet { updateAnnotations() }
    }
    @Published private(set) var pinAnnotations: [PinAnnotation] = []
    @Published var errorMessage: String?
    @Published var isLoading = false

    private let repository: MemoryRepository

    init(repository: MemoryRepository = MemoryRepository()) {
        self.repository = repository
    }

    // MARK: - Fetch

    func fetchPins() async {
        isLoading = true
        defer { isLoading = false }
        do {
            pins = try repository.fetchAllPins()
            errorMessage = nil
        } catch {
            errorMessage = "Не удалось загрузить воспоминания: \(error.localizedDescription)"
        }
    }

    // MARK: - Create

    /// `configuration.coordinate` — приоритетная локация (выбрана вручную).
    /// `fallbackLocation` — GPS, если пользователь не выбрал точку на карте.
    func addPin(configuration: PinConfiguration, fallbackLocation: CLLocation? = nil) async {
        guard configuration.isValid else {
            errorMessage = "Добавьте название или фото"
            return
        }
        isLoading = true
        defer { isLoading = false }
        do {
            _ = try repository.createPin(configuration: configuration, fallbackLocation: fallbackLocation)
            await refreshPins()
        } catch {
            errorMessage = "Не удалось сохранить воспоминание: \(error.localizedDescription)"
        }
    }

    // MARK: - Update

    func updatePin(_ pin: MemoryPin, configuration: PinConfiguration) async {
        guard configuration.isValid else {
            errorMessage = "Добавьте название или фото"
            return
        }
        isLoading = true
        defer { isLoading = false }
        do {
            try repository.updatePin(pin, configuration: configuration)
            await refreshPins()
        } catch {
            errorMessage = "Не удалось обновить воспоминание: \(error.localizedDescription)"
        }
    }

    // MARK: - Delete

    func deletePhoto(_ photo: PhotoEntity) async {
        isLoading = true
        defer { isLoading = false }
        do {
            try repository.deletePhoto(photo)
            await refreshPins()
        } catch {
            errorMessage = "Не удалось удалить фото: \(error.localizedDescription)"
        }
    }

    func deletePin(_ pin: MemoryPin) async {
        isLoading = true
        defer { isLoading = false }
        do {
            try repository.deletePin(pin)
            await refreshPins()
        } catch {
            errorMessage = "Не удалось удалить воспоминание: \(error.localizedDescription)"
        }
    }

    // MARK: - Cluster / Spread

    private func updateAnnotations() {
        var result: [PinAnnotation] = []
        var processed = Set<UUID>()

        let threshold    = region.span.latitudeDelta * 0.008
        let spreadRadius = region.span.latitudeDelta * 0.014
        let sorted = pins.sorted { ($0.id?.uuidString ?? "") < ($1.id?.uuidString ?? "") }

        for pin in sorted {
            guard let pinID = pin.id, !processed.contains(pinID) else { continue }

            let cluster = sorted.filter { other in
                guard let otherID = other.id else { return false }
                return !processed.contains(otherID) &&
                    abs(other.latitude - pin.latitude) < threshold &&
                    abs(other.longitude - pin.longitude) < threshold
            }
            cluster.compactMap { $0.id }.forEach { processed.insert($0) }

            if cluster.count == 1 {
                result.append(PinAnnotation(id: pinID, pin: pin, coordinate: pin.coordinate))
            } else {
                let cLat = cluster.map { $0.latitude }.reduce(0, +) / Double(cluster.count)
                let cLon = cluster.map { $0.longitude }.reduce(0, +) / Double(cluster.count)
                let lonFactor = cos(cLat * .pi / 180)

                for (i, cp) in cluster.enumerated() {
                    guard let cpID = cp.id else { continue }
                    let angle = (2.0 * .pi / Double(cluster.count)) * Double(i) - (.pi / 2)
                    let coord = CLLocationCoordinate2D(
                        latitude:  cLat + spreadRadius * cos(angle),
                        longitude: cLon + spreadRadius * sin(angle) / lonFactor
                    )
                    result.append(PinAnnotation(id: cpID, pin: cp, coordinate: coord))
                }
            }
        }
        pinAnnotations = result
    }

    /// Все пины, расположенные достаточно близко к данному (включая сам пин).
    func nearbyPins(to pin: MemoryPin) -> [MemoryPin] {
        let threshold = region.span.latitudeDelta * 0.008
        return pins.filter {
            abs($0.latitude - pin.latitude) < threshold &&
            abs($0.longitude - pin.longitude) < threshold
        }
    }

    // MARK: - Private

    private func refreshPins() async {
        do {
            pins = try repository.fetchAllPins()
            errorMessage = nil
        } catch {
            errorMessage = "Не удалось обновить список: \(error.localizedDescription)"
        }
    }
}
