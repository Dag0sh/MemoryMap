// PhotoService.swift
import UIKit
import PhotosUI
import SwiftUI

/// Сервис для работы с фотографиями
@MainActor
final class PhotoService {
    
    /// Загружает изображения из PhotosPicker items
    /// - Parameter items: Выбранные элементы из PhotosPicker
    /// - Returns: Массив загруженных изображений
    static func loadImages(from items: [PhotosPickerItem]) async -> [IdentifiedImage] {
        var loadedImages: [IdentifiedImage] = []
        
        for item in items {
            do {
                if let data = try await item.loadTransferable(type: Data.self),
                   let uiImage = UIImage(data: data) {
                    loadedImages.append(IdentifiedImage(image: uiImage))
                }
            } catch {
                print("⚠️ Не удалось загрузить изображение: \(error.localizedDescription)")
            }
        }
        
        return loadedImages
    }
    
    /// Сжимает изображение для сохранения
    /// - Parameters:
    ///   - image: Исходное изображение
    ///   - quality: Качество сжатия JPEG (0.0 - 1.0)
    /// - Returns: Сжатые данные изображения
    static func compressImage(_ image: UIImage, quality: CGFloat = 0.8) -> Data? {
        return image.jpegData(compressionQuality: quality)
    }
    
    /// Создает thumbnail для изображения
    /// - Parameters:
    ///   - image: Исходное изображение
    ///   - size: Размер thumbnail
    /// - Returns: Уменьшенное изображение
    static func createThumbnail(_ image: UIImage, size: CGSize = CGSize(width: 200, height: 200)) -> UIImage? {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: size))
        }
    }
}
