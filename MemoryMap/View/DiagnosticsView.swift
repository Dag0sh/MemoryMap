// DiagnosticsView.swift
import SwiftUI
import CoreLocation

/// View для диагностики проблем с локацией и пинами
struct DiagnosticsView: View {
    @ObservedObject var viewModel: MapViewModel
    @ObservedObject var locationManager: LocationManager
    
    var body: some View {
        List {
            Section("📍 Геолокация") {
                HStack {
                    Text("Статус авторизации:")
                    Spacer()
                    Text(authStatusText)
                        .foregroundColor(authStatusColor)
                }
                
                if let location = locationManager.currentLocation {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Текущая локация:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("Lat: \(location.coordinate.latitude, specifier: "%.6f")")
                        Text("Lon: \(location.coordinate.longitude, specifier: "%.6f")")
                        Text("Точность: ±\(location.horizontalAccuracy, specifier: "%.0f")m")
                    }
                    .font(.caption)
                } else {
                    Text("Локация не определена")
                        .foregroundColor(.orange)
                }
                
                Button("Запросить разрешение") {
                    locationManager.requestLocationPermission()
                }
                
                Button("Начать обновления") {
                    locationManager.startUpdatingLocation()
                }
            }
            
            Section("🗺 Карта и пины") {
                HStack {
                    Text("Количество пинов:")
                    Spacer()
                    Text("\(viewModel.pins.count)")
                }
                
                HStack {
                    Text("Регион карты:")
                    Spacer()
                    VStack(alignment: .trailing) {
                        Text("Lat: \(viewModel.region.center.latitude, specifier: "%.4f")")
                        Text("Lon: \(viewModel.region.center.longitude, specifier: "%.4f")")
                    }
                    .font(.caption)
                }
                
                if viewModel.isLoading {
                    HStack {
                        ProgressView()
                        Text("Загрузка...")
                    }
                }
                
                if let error = viewModel.errorMessage {
                    Text("Ошибка: \(error)")
                        .foregroundColor(.red)
                        .font(.caption)
                }
                
                Button("Обновить пины") {
                    Task {
                        await viewModel.fetchPins()
                    }
                }
            }
            
            Section("🧪 Тестовые действия") {
                Button("Создать тестовый пин") {
                    Task {
                        let config = PinConfiguration(
                            title: "Тестовый пин \(Date().timeIntervalSince1970)",
                            sticker: "star",
                            images: []
                        )
                        
                        await viewModel.addPin(
                            configuration: config,
                            fallbackLocation: locationManager.currentLocation
                        )
                    }
                }
                
                Button("Очистить ошибки") {
                    viewModel.errorMessage = nil
                }
            }
            
            Section("ℹ️ Системная информация") {
                Text("iOS: \(UIDevice.current.systemVersion)")
                Text("Модель: \(UIDevice.current.model)")
                Text("Симулятор: \(isSimulator ? "Да" : "Нет")")
            }
        }
        .navigationTitle("Диагностика")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private var authStatusText: String {
        switch locationManager.authorizationStatus {
        case .notDetermined:
            return "Не определено"
        case .restricted:
            return "Ограничено"
        case .denied:
            return "Запрещено"
        case .authorizedAlways:
            return "Разрешено всегда"
        case .authorizedWhenInUse:
            return "Разрешено при использовании"
        @unknown default:
            return "Неизвестно"
        }
    }
    
    private var authStatusColor: Color {
        switch locationManager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            return .green
        case .denied, .restricted:
            return .red
        case .notDetermined:
            return .orange
        @unknown default:
            return .gray
        }
    }
    
    private var isSimulator: Bool {
        #if targetEnvironment(simulator)
        return true
        #else
        return false
        #endif
    }
}

#Preview {
    NavigationView {
        DiagnosticsView(
            viewModel: MapViewModel(),
            locationManager: LocationManager()
        )
    }
}
