// MemoryPin+Extensions.swift
import Foundation
import CoreLocation
import MapKit

extension MemoryPin {
    /// Координаты пина для отображения на карте
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    /// Отсортированные фотографии по дате
    var sortedPhotos: [PhotoEntity] {
        (photos as? Set<PhotoEntity> ?? [])
            .sorted { ($0.date ?? .distantPast) < ($1.date ?? .distantPast) }
    }
    
    /// Количество фотографий
    var photoCount: Int {
        (photos as? Set<PhotoEntity>)?.count ?? 0
    }
    
    /// Есть ли фотографии
    var hasPhotos: Bool {
        photoCount > 0
    }
    
    /// Безопасное получение стикера с fallback
    var safeSticker: String {
        sticker ?? "camera"
    }
    
    /// Отформатированная дата
    var formattedDate: String {
        guard let date = date else { return "Неизвестная дата" }
        
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        formatter.locale = Locale(identifier: "ru_RU")
        
        return formatter.string(from: date)
    }
}

extension PhotoEntity {
    /// Конвертация imageData в UIImage
    var uiImage: UIImage? {
        guard let data = imageData else { return nil }
        return UIImage(data: data)
    }
}
