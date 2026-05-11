// EditMemoryView.swift
import PhotosUI
import SwiftUI
import MapKit

struct EditMemoryView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: MapViewModel
    let pin: MemoryPin

    @State private var title: String
    @State private var sticker: String
    @State private var selectedCoordinate: CLLocationCoordinate2D
    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var newImages: [IdentifiedImage] = []
    @State private var existingPhotos: [PhotoEntity] = []
    @State private var showDeleteConfirmation = false
    @State private var isProcessingPhotos = false
    @State private var showingLocationPicker = false

    init(viewModel: MapViewModel, pin: MemoryPin) {
        self.viewModel = viewModel
        self.pin = pin
        _title = State(initialValue: pin.title ?? "")
        _sticker = State(initialValue: pin.sticker ?? "camera")
        _selectedCoordinate = State(initialValue: CLLocationCoordinate2D(
            latitude: pin.latitude,
            longitude: pin.longitude
        ))
        if let photosSet = pin.photos as? Set<PhotoEntity> {
            let sorted = photosSet.sorted { ($0.date ?? .distantPast) < ($1.date ?? .distantPast) }
            _existingPhotos = State(initialValue: sorted)
        }
    }

    private var hasChanges: Bool {
        title != (pin.title ?? "") ||
        sticker != (pin.sticker ?? "camera") ||
        selectedCoordinate.latitude  != pin.latitude ||
        selectedCoordinate.longitude != pin.longitude ||
        !newImages.isEmpty
    }

    private var canSave: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
        !existingPhotos.isEmpty ||
        !newImages.isEmpty
    }

    private var pickerRegion: MKCoordinateRegion {
        MKCoordinateRegion(
            center: selectedCoordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        )
    }

    var body: some View {
        NavigationView {
            Form {
                infoSection
                locationSection
                photosSection
                actionsSection
            }
            .navigationTitle("Редактирование")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Сохранить") { saveChanges() }
                        .disabled(!canSave || !hasChanges)
                }
            }
            .alert("Удалить воспоминание?", isPresented: $showDeleteConfirmation) {
                Button("Отмена", role: .cancel) {}
                Button("Удалить", role: .destructive) { deletePin() }
            } message: {
                Text("Это действие нельзя отменить")
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
                        coordinate: Binding(
                            get: { selectedCoordinate },
                            set: { if let c = $0 { selectedCoordinate = c } }
                        ),
                        initialRegion: pickerRegion
                    )
                }
            }
        }
    }

    // MARK: - Sections

    private var infoSection: some View {
        Section("Информация") {
            TextField("Название", text: $title)
                .textInputAutocapitalization(.sentences)

            VStack(alignment: .leading, spacing: 8) {
                Text("Стикер")
                    .font(.caption)
                    .foregroundColor(.secondary)
                StickerPicker(selectedSticker: $sticker, stickers: StickerSymbols.extended)
            }
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
                    Text(String(format: "%.5f, %.5f",
                                selectedCoordinate.latitude,
                                selectedCoordinate.longitude))
                        .font(.subheadline)
                        .foregroundColor(.primary)
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
            PhotosPicker("Добавить фото",
                         selection: $selectedItems,
                         maxSelectionCount: 10,
                         matching: .images)

            PhotoGalleryView(
                existingPhotos: existingPhotos,
                newImages: newImages,
                onDeleteExisting: { removeExistingPhoto($0) },
                onDeleteNew: { image in newImages.removeAll { $0.id == image.id } }
            )
        } header: {
            Text("Фотографии")
        } footer: {
            if !existingPhotos.isEmpty || !newImages.isEmpty {
                Text("Всего: \(existingPhotos.count + newImages.count) фото").font(.caption)
            }
        }
    }

    private var actionsSection: some View {
        Section {
            Button(role: .destructive) {
                showDeleteConfirmation = true
            } label: {
                Label("Удалить воспоминание", systemImage: "trash")
                    .frame(maxWidth: .infinity, alignment: .center)
            }
        }
    }

    // MARK: - Actions

    private func saveChanges() {
        Task {
            let config = PinConfiguration(
                title: title.isEmpty ? nil : title,
                sticker: sticker,
                images: newImages.map { $0.image },
                coordinate: selectedCoordinate
            )
            await viewModel.updatePin(pin, configuration: config)
            if viewModel.errorMessage == nil { dismiss() }
        }
    }

    private func removeExistingPhoto(_ photo: PhotoEntity) {
        Task {
            await viewModel.deletePhoto(photo)
            existingPhotos.removeAll { $0.id == photo.id }
        }
    }

    private func deletePin() {
        Task {
            await viewModel.deletePin(pin)
            dismiss()
        }
    }

    private func loadSelectedPhotos() async {
        isProcessingPhotos = true
        defer { isProcessingPhotos = false }
        newImages = await PhotoService.loadImages(from: selectedItems)
    }
}
