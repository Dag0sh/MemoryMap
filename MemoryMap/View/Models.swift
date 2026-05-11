// Models.swift
import UIKit

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
    
    init(title: String? = nil, sticker: String = "camera", images: [UIImage] = []) {
        self.title = title
        self.sticker = sticker
        self.images = images
    }
    
    var isValid: Bool {
        // Пин валиден если есть хотя бы название или фото
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
