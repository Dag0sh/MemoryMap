// PinDetailView.swift
import SwiftUI
import MapKit
import CoreLocation

struct PinDetailView: View {
    @ObservedObject var pin: MemoryPin
    var onFindOnMap: (() -> Void)? = nil

    @Environment(\.dismiss) private var dismiss

    @State private var currentPhotoIndex = 0
    @State private var showFullScreen = false
    @State private var locationName = "Определяем адрес..."

    private var sortedPhotos: [PhotoEntity] {
        (pin.photos as? Set<PhotoEntity> ?? [])
            .sorted { ($0.date ?? .distantPast) < ($1.date ?? .distantPast) }
    }

    private var pinColor: Color {
        let colors: [Color] = [.blue, .green, .orange, .purple, .pink, .red, .teal, .indigo]
        return colors[abs((pin.id ?? UUID()).hashValue) % colors.count]
    }

    private let geocoder = CLGeocoder()

    var body: some View {
        NavigationView {
            GeometryReader { geo in
                ZStack(alignment: .top) {
                    Color(.systemGroupedBackground).ignoresSafeArea()

                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 0) {
                            photoHero(height: geo.size.height * 0.58)
                            infoCard
                                .padding(.horizontal)
                                .padding(.top, -28)
                                .padding(.bottom, 24)
                        }
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Воспоминание")
                        .font(.headline)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .symbolRenderingMode(.hierarchical)
                            .font(.title3)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .fullScreenCover(isPresented: $showFullScreen) {
                FullScreenPhotoGallery(photos: sortedPhotos, startIndex: currentPhotoIndex)
            }
            .onAppear { reverseGeocode() }
        }
    }

    // MARK: - Photo hero

    @ViewBuilder
    private func photoHero(height: CGFloat) -> some View {
        if sortedPhotos.isEmpty {
            ZStack {
                Color(.systemGray5)
                VStack(spacing: 8) {
                    Image(systemName: "photo.slash")
                        .font(.system(size: 44))
                        .foregroundColor(.secondary)
                    Text("Нет фото")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            .frame(height: height)
        } else {
            TabView(selection: $currentPhotoIndex) {
                ForEach(sortedPhotos.indices, id: \.self) { i in
                    if let data = sortedPhotos[i].imageData,
                       let ui = UIImage(data: data) {
                        Image(uiImage: ui)
                            .resizable()
                            .scaledToFill()
                            .clipped()
                            .tag(i)
                            .onTapGesture { showFullScreen = true }
                    }
                }
            }
            .tabViewStyle(.page(indexDisplayMode: sortedPhotos.count > 1 ? .always : .never))
            .frame(height: height)
            .clipped()
        }
    }

    // MARK: - Info card

    private var infoCard: some View {
        VStack(alignment: .leading, spacing: 0) {

            // Стикер + заголовок
            HStack(alignment: .center, spacing: 14) {
                ZStack {
                    Circle()
                        .fill(pinColor)
                        .frame(width: 48, height: 48)
                        .shadow(color: pinColor.opacity(0.4), radius: 6, y: 3)
                    Image(systemName: pin.safeSticker)
                        .font(.title3)
                        .foregroundColor(.white)
                }

                Text(pin.title ?? "Без названия")
                    .font(.title3.bold())
                    .lineLimit(2)
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 14)

            Divider().padding(.horizontal, 20)

            // Дата создания
            if let date = pin.date {
                infoRow(
                    icon: "calendar",
                    color: .orange,
                    text: "Создан: \(date.formatted(.dateTime.weekday(.wide).day().month(.wide).year()))"
                )
                Divider().padding(.horizontal, 20)
            }

            // Адрес
            infoRow(
                icon: "mappin.and.ellipse",
                color: .blue,
                text: locationName
            )

            // Количество фото
            if !sortedPhotos.isEmpty {
                Divider().padding(.horizontal, 20)
                infoRow(
                    icon: "photo.on.rectangle",
                    color: .purple,
                    text: "\(sortedPhotos.count) \(photoWord(sortedPhotos.count))"
                )
            }

            // Дата изменения
            if let updated = pin.updatedAt {
                Divider().padding(.horizontal, 20)
                infoRow(
                    icon: "pencil.and.clock",
                    color: .indigo,
                    text: "Изменён: \(updated.formatted(.dateTime.day().month(.wide).year().hour().minute()))"
                )
            }

            // Кнопка "Найти на карте"
            if let onFindOnMap, pin.latitude != 0 || pin.longitude != 0 {
                Divider().padding(.horizontal, 20)
                Button {
                    dismiss()
                    onFindOnMap()
                } label: {
                    Label("Найти на карте", systemImage: "map.fill")
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.blue)
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }

            Spacer(minLength: 12)
        }
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .shadow(color: .black.opacity(0.08), radius: 16, y: 4)
    }

    private func infoRow(icon: String, color: Color, text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 22)
                .padding(.top, 1)
            Text(text)
                .font(.subheadline)
                .foregroundColor(.primary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }

    // MARK: - Helpers

    private func photoWord(_ count: Int) -> String {
        switch count % 10 {
        case 1 where count % 100 != 11: return "фото"
        case 2...4 where !(11...14 ~= count % 100): return "фото"
        default: return "фото"
        }
    }

    // MARK: - Geocoding

    private func reverseGeocode() {
        guard pin.latitude != 0 || pin.longitude != 0 else {
            locationName = "Местоположение не указано"
            return
        }
        let location = CLLocation(latitude: pin.latitude, longitude: pin.longitude)
        geocoder.reverseGeocodeLocation(location) { placemarks, _ in
            DispatchQueue.main.async {
                guard let placemark = placemarks?.first else {
                    locationName = formatCoordinates()
                    return
                }
                let parts = [
                    placemark.subThoroughfare,
                    placemark.thoroughfare,
                    placemark.locality,
                    placemark.administrativeArea,
                    placemark.country
                ].compactMap { $0 }
                withAnimation {
                    locationName = parts.isEmpty ? formatCoordinates() : parts.joined(separator: ", ")
                }
            }
        }
    }

    private func formatCoordinates() -> String {
        String(format: "%.5f, %.5f", pin.latitude, pin.longitude)
    }
}
