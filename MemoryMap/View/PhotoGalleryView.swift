// PhotoGalleryView.swift
import SwiftUI

/// Горизонтальная галерея фотографий с возможностью удаления
struct PhotoGalleryView: View {
    let existingPhotos: [PhotoEntity]
    let newImages: [IdentifiedImage]
    let onDeleteExisting: ((PhotoEntity) -> Void)?
    let onDeleteNew: ((IdentifiedImage) -> Void)?
    
    init(
        existingPhotos: [PhotoEntity] = [],
        newImages: [IdentifiedImage] = [],
        onDeleteExisting: ((PhotoEntity) -> Void)? = nil,
        onDeleteNew: ((IdentifiedImage) -> Void)? = nil
    ) {
        self.existingPhotos = existingPhotos
        self.newImages = newImages
        self.onDeleteExisting = onDeleteExisting
        self.onDeleteNew = onDeleteNew
    }
    
    var hasPhotos: Bool {
        !existingPhotos.isEmpty || !newImages.isEmpty
    }
    
    var body: some View {
        if hasPhotos {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    // Существующие фото
                    ForEach(existingPhotos, id: \.id) { photo in
                        photoThumbnail(for: photo)
                    }
                    
                    // Новые фото
                    ForEach(newImages) { item in
                        newPhotoThumbnail(for: item)
                    }
                }
                .padding(.horizontal, 4)
            }
            .frame(height: 100)
        }
    }
    
    @ViewBuilder
    private func photoThumbnail(for photo: PhotoEntity) -> some View {
        if let data = photo.imageData, let uiImage = UIImage(data: data) {
            ZStack(alignment: .topTrailing) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 100, height: 80)
                    .clipped()
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.white.opacity(0.6), lineWidth: 2)
                    )
                
                if let onDelete = onDeleteExisting {
                    Button {
                        withAnimation {
                            onDelete(photo)
                        }
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.red)
                            .background(Color.white.clipShape(Circle()))
                            .shadow(radius: 2)
                    }
                    .offset(x: 8, y: -8)
                }
            }
        }
    }
    
    @ViewBuilder
    private func newPhotoThumbnail(for item: IdentifiedImage) -> some View {
        ZStack(alignment: .topTrailing) {
            Image(uiImage: item.image)
                .resizable()
                .scaledToFill()
                .frame(width: 100, height: 80)
                .clipped()
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.blue.opacity(0.6), lineWidth: 2)
                )
            
            if let onDelete = onDeleteNew {
                Button {
                    withAnimation {
                        onDelete(item)
                    }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.red)
                        .background(Color.white.clipShape(Circle()))
                        .shadow(radius: 2)
                }
                .offset(x: 8, y: -8)
            }
        }
    }
}

#Preview {
    Form {
        Section("Фото") {
            PhotoGalleryView(
                existingPhotos: [],
                newImages: [
                    IdentifiedImage(image: UIImage(systemName: "photo")!),
                    IdentifiedImage(image: UIImage(systemName: "photo.fill")!)
                ]
            )
        }
    }
}
