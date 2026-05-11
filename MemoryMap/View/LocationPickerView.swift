// LocationPickerView.swift
import MapKit
import SwiftUI

struct LocationPickerView: View {
    @Environment(\.dismiss) private var dismiss

    /// Выбранная координата — возвращается при подтверждении
    @Binding var coordinate: CLLocationCoordinate2D?

    /// Начальный регион карты
    let initialRegion: MKCoordinateRegion

    @State private var region: MKCoordinateRegion
    @State private var isDragging = false

    init(coordinate: Binding<CLLocationCoordinate2D?>, initialRegion: MKCoordinateRegion) {
        self._coordinate = coordinate
        self.initialRegion = initialRegion

        // Если уже есть координата — центрируем на ней
        let center = coordinate.wrappedValue ?? initialRegion.center
        self._region = State(initialValue: MKCoordinateRegion(
            center: center,
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        ))
    }

    var body: some View {
        ZStack {
            // Карта (пользователь двигает — центр = выбранная точка)
            Map(coordinateRegion: $region, showsUserLocation: true)
                .ignoresSafeArea()

            // Перекрестие
            VStack(spacing: 0) {
                Image(systemName: "mappin.circle.fill")
                    .font(.system(size: 36))
                    .foregroundColor(.blue)
                    .shadow(radius: 4)
                    .scaleEffect(isDragging ? 1.2 : 1.0)
                    .animation(.spring(response: 0.3), value: isDragging)

                // Тень под иконкой для ощущения «висящей» точки
                Ellipse()
                    .fill(Color.black.opacity(isDragging ? 0.15 : 0.25))
                    .frame(width: 20, height: 6)
                    .scaleEffect(isDragging ? 0.7 : 1.0)
                    .animation(.spring(response: 0.3), value: isDragging)
            }

            // Кнопка подтверждения
            VStack {
                Spacer()
                Button {
                    coordinate = region.center
                    dismiss()
                } label: {
                    Label("Выбрать это место", systemImage: "checkmark.circle.fill")
                        .font(.headline)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 14)
                        .background(.blue)
                        .foregroundColor(.white)
                        .clipShape(Capsule())
                        .shadow(radius: 6)
                }
                .padding(.bottom, 48)
            }

            // Координаты текущей точки (для ориентира)
            VStack {
                HStack {
                    Text(String(format: "%.5f, %.5f",
                                region.center.latitude,
                                region.center.longitude))
                        .font(.caption2.monospacedDigit())
                        .padding(6)
                        .background(.ultraThinMaterial)
                        .clipShape(Capsule())
                        .padding(12)
                    Spacer()
                }
                Spacer()
            }
        }
        .navigationTitle("Выберите место")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Отмена") { dismiss() }
            }
        }
        // Отслеживаем движение карты через onChange региона
        .onChange(of: region.center.latitude)  { _ in isDragging = true }
        .onChange(of: region.center.longitude) { _ in isDragging = true }
        .onReceive(
            Timer.publish(every: 0.3, on: .main, in: .common).autoconnect()
        ) { _ in
            if isDragging { isDragging = false }
        }
    }
}
