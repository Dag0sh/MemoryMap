// AddMemoryView.swift
import SwiftUI
import PhotosUI
import MapKit

struct AddMemoryView: View {
    @ObservedObject var viewModel: MapViewModel
    let location: CLLocation?
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var selectedSticker = "camera"
    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var images: [IdentifiedImage] = []
    @State private var isProcessingPhotos = false
    @State private var selectedCoordinate: CLLocationCoordinate2D?
    @State private var showingLocationPicker = false

    private var canSave: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || !images.isEmpty
    }

    // Регион для открытия пикера: выбранная точка → GPS → центр карты
    private var pickerRegion: MKCoordinateRegion {
        let center = selectedCoordinate ?? location?.coordinate ?? viewModel.region.center
        return MKCoordinateRegion(
            center: center,
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        )
    }

    var body: some View {
        NavigationView {
            Form {
                titleSection
                stickerSection
                locationSection
                photosSection
            }
            .navigationTitle("Новое воспоминание")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Сохранить") { saveMemory() }
                        .disabled(!canSave)
                }
            }
            .onChange(of: selectedItems) { _ in
                Task { await loadSelectedPhotos() }
            }
            .overlay {
                if viewModel.isLoading || isProcessingPhotos {
                    ProgressView()
                        .scaleEffect(1.5)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.black.opacity(0.2))
                }
            }
            .sheet(isPresented: $showingLocationPicker) {
                NavigationView {
                    LocationPickerView(
                        coordinate: $selectedCoordinate,
                        initialRegion: pickerRegion
                    )
                }
            }
        }
        .onAppear {
            // По умолчанию используем GPS-локацию
            if selectedCoordinate == nil {
                selectedCoordinate = location?.coordinate ?? viewModel.region.center
            }
        }
    }

    // MARK: - Sections

    private var titleSection: some View {
        Section("Название") {
            TextField("Назови воспоминание", text: $title)
                .textInputAutocapitalization(.sentences)
        }
    }

    private var stickerSection: some View {
        Section("Стикер") {
            StickerPicker(selectedSticker: $selectedSticker, stickers: StickerSymbols.extended)
        }
    }

    private var locationSection: some View {
        Section("Место") {
            Button {
                showingLocationPicker = true
            } label: {
                HStack {
                    Image(systemName: "mappin.and.ellipse")
                        .foregroundColor(.blue)
                    if let coord = selectedCoordinate {
                        Text(String(format: "%.5f, %.5f", coord.latitude, coord.longitude))
                            .font(.subheadline)
                            .foregroundColor(.primary)
                    } else {
                        Text("Выбрать на карте")
                            .foregroundColor(.blue)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }

    private var photosSection: some View {
        Section {
            PhotosPicker("Выбрать фото",
                         selection: $selectedItems,
                         maxSelectionCount: 10,
                         matching: .images)

            PhotoGalleryView(
                newImages: images,
                onDeleteNew: { image in images.removeAll { $0.id == image.id } }
            )
        } header: {
            Text("Фотографии")
        } footer: {
            if !images.isEmpty {
                Text("Выбрано: \(images.count) фото").font(.caption)
            }
        }
    }

    // MARK: - Actions

    private func saveMemory() {
        Task {
            let config = PinConfiguration(
                title: title.isEmpty ? nil : title,
                sticker: selectedSticker,
                images: images.map { $0.image },
                coordinate: selectedCoordinate
            )
            await viewModel.addPin(configuration: config, fallbackLocation: location)
            if viewModel.errorMessage == nil { dismiss() }
        }
    }

    private func loadSelectedPhotos() async {
        isProcessingPhotos = true
        defer { isProcessingPhotos = false }
        images = await PhotoService.loadImages(from: selectedItems)
    }
}
