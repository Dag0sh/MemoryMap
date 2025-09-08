import PhotosUI
import SwiftUI

extension Sequence {
    func asyncCompactMap<T>(_ transform: @escaping (Element) async -> T?) async -> [T] {
        var results = [T?](repeating: nil, count: Array(self).count)
        await withTaskGroup(of: (Int, T?).self) { group in
            for (index, element) in self.enumerated() {
                group.addTask {
                    return (index, await transform(element))
                }
            }

            for await (index, value) in group {
                results[index] = value
            }
        }
        return results.compactMap { $0 }
    }
}

struct AddMemoryView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: MapViewModel
    let location: CLLocation?

    @State private var title = ""
    @State private var sticker = "📷"
    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var images: [UIImage] = []

    var body: some View {
        NavigationView {
            Form {
                Section("Info") {
                    TextField("Title", text: $title)
                    TextField("Sticker", text: $sticker)
                }

                Section("Photos") {
                    PhotosPicker(
                        selection: $selectedItems,
                        maxSelectionCount: 10,
                        matching: .images
                    ) {
                        Text("Select photos")
                    }
                    ScrollView(.horizontal) {
                        HStack {
                            ForEach(images, id: \.self) { img in
                                Image(uiImage: img)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 100, height: 80)
                                    .clipped()
                                    .cornerRadius(8)
                            }
                        }
                    }
                }

                Button("Save") {
                    viewModel.addPin(
                        title: title,
                        sticker: sticker,
                        location: location,
                        images: images
                    )
                    dismiss()
                }
            }
            .navigationTitle("New Memory")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        
            .onChange(of: selectedItems) { _ in
                Task {
                    let imgs: [UIImage] = await selectedItems.asyncCompactMap { item in
                        if let data = try? await item.loadTransferable(type: Data.self),
                           let ui = UIImage(data: data) {
                            return ui
                        }
                        return nil // корректно возвращаем nil для отбрасывания
                    }
                    images = imgs
                }
            }
        }
    }
}
