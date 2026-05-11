// Models.swift
import UIKit
import CoreLocation

/// Идентифицируемое изображение для SwiftUI
struct IdentifiedImage: Identifiable {
    let id = UUID()
    let image: UIImage
}

/// Конфигурация для создания/редактирования пина
struct PinConfiguration {
    var title: String?
    var sticker: String
    var images: [UIImage]
    /// Явно выбранная пользователем координата (перекрывает GPS-локацию)
    var coordinate: CLLocationCoordinate2D?

    init(title: String? = nil,
         sticker: String = "camera",
         images: [UIImage] = [],
         coordinate: CLLocationCoordinate2D? = nil) {
        self.title = title
        self.sticker = sticker
        self.images = images
        self.coordinate = coordinate
    }

    var isValid: Bool {
        !(title?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true) || !images.isEmpty
    }
}

/// Константы для символов стикеров
enum StickerSymbols {
    static let common = [
        "camera", "heart", "star", "sun.max", "moon", "leaf", "flower", "gift",
        "music.note", "book"
    ]
    
    static let extended = common + [
        "cloud", "bolt", "flame", "snowflake", "umbrella",
        "car", "airplane", "tram", "bicycle", "pawprint", "fish", "bird"
    ]
}
