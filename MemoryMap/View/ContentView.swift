// ContentView.swift
import MapKit
import SwiftUI

struct ContentView: View {
    @StateObject private var mapVM = MapViewModel()
    @StateObject private var locManager = LocationManager()
    @State private var showingAdd = false
    @State private var selectedPin: MemoryPin?
    @State private var editPin: MemoryPin?
    @State private var showingDiagnostics = false
    @State private var showingList = false
    @State private var isReady = false
    // Disambiguation: пины в одной точке
    @State private var clusterPins: [MemoryPin] = []
    @State private var showingClusterPicker = false

    var body: some View {
        ZStack {
            mapContent
            if !isReady {
                LaunchView()
                    .transition(.opacity)
                    .zIndex(1)
            }
        }
        .animation(.easeInOut(duration: 0.45), value: isReady)
    }

    // MARK: - Map content

    private var mapContent: some View {
        ZStack(alignment: .bottomTrailing) {
            Map(
                coordinateRegion: $mapVM.region,
                showsUserLocation: true,
                annotationItems: mapVM.pinAnnotations
            ) { annotation in
                MapAnnotation(coordinate: annotation.coordinate) {
                    StickerView(pin: annotation.pin, selectedPin: selectedPin)
                        .onTapGesture {
                            handleTap(on: annotation.pin)
                        }
                        .onLongPressGesture { editPin = annotation.pin }
                }
            }
            .mapStyle(.standard(elevation: .realistic))
            .ignoresSafeArea()

            // Кнопки управления (снизу)
            VStack {
                Spacer()
                HStack {
                    Button { showingList = true } label: {
                        Image(systemName: "list.bullet")
                            .font(.title2)
                            .padding()
                            .background(Color.purple.opacity(0.8))
                            .foregroundColor(.white)
                            .clipShape(Circle())
                            .shadow(radius: 5)
                    }

                    Button { showingDiagnostics = true } label: {
                        Image(systemName: "info.circle.fill")
                            .font(.title2)
                            .padding()
                            .background(Color.orange.opacity(0.8))
                            .foregroundColor(.white)
                            .clipShape(Circle())
                            .shadow(radius: 5)
                    }

                    Button {
                        if let loc = locManager.currentLocation {
                            withAnimation(.easeInOut) {
                                mapVM.region = MKCoordinateRegion(
                                    center: loc.coordinate,
                                    span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                                )
                            }
                        }
                    } label: {
                        Image(systemName: "location.circle.fill")
                            .font(.title2)
                            .padding()
                            .background(Color.green.opacity(0.8))
                            .foregroundColor(.white)
                            .clipShape(Circle())
                            .shadow(radius: 5)
                    }

                    Spacer()

                    Button { showingAdd = true } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .padding()
                            .background(Color.blue.opacity(0.8))
                            .foregroundColor(.white)
                            .clipShape(Circle())
                            .shadow(radius: 5)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 40)
            }

            // Кнопки зума (справа по центру)
            VStack(spacing: 8) {
                Button {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        mapVM.region.span = MKCoordinateSpan(
                            latitudeDelta:  mapVM.region.span.latitudeDelta  / 2,
                            longitudeDelta: mapVM.region.span.longitudeDelta / 2
                        )
                    }
                } label: {
                    Image(systemName: "plus.magnifyingglass")
                        .font(.title2)
                        .padding(12)
                        .background(Color.white.opacity(0.9))
                        .clipShape(Circle())
                        .shadow(radius: 3)
                }

                Button {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        mapVM.region.span = MKCoordinateSpan(
                            latitudeDelta:  mapVM.region.span.latitudeDelta  * 2,
                            longitudeDelta: mapVM.region.span.longitudeDelta * 2
                        )
                    }
                } label: {
                    Image(systemName: "minus.magnifyingglass")
                        .font(.title2)
                        .padding(12)
                        .background(Color.white.opacity(0.9))
                        .clipShape(Circle())
                        .shadow(radius: 3)
                }
            }
            .frame(maxHeight: .infinity, alignment: .center)
            .padding(.trailing, 16)
        }
        // MARK: Sheets
        .sheet(isPresented: $showingAdd) {
            AddMemoryView(viewModel: mapVM, location: locManager.currentLocation)
        }
        .sheet(isPresented: $showingList) {
            PinListView(viewModel: mapVM) { pin in
                showingList = false
                withAnimation(.easeInOut) {
                    mapVM.region = MKCoordinateRegion(
                        center: pin.coordinate,
                        span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
                    )
                }
            }
        }
        .sheet(item: $selectedPin) { pin in
            PinDetailView(pin: pin)
        }
        .sheet(item: $editPin) { pin in
            EditMemoryView(viewModel: mapVM, pin: pin)
        }
        .sheet(isPresented: $showingDiagnostics) {
            NavigationView {
                DiagnosticsView(viewModel: mapVM, locationManager: locManager)
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Готово") { showingDiagnostics = false }
                        }
                    }
            }
        }
        // MARK: Disambiguation
        .confirmationDialog("Выберите воспоминание", isPresented: $showingClusterPicker, titleVisibility: .visible) {
            ForEach(clusterPins, id: \.id) { pin in
                Button(pin.title ?? "Без названия") { selectedPin = pin }
            }
        }
        // MARK: Lifecycle
        .task {
            await mapVM.fetchPins()
            withAnimation { isReady = true }
            if let loc = locManager.currentLocation {
                withAnimation {
                    mapVM.region = MKCoordinateRegion(
                        center: loc.coordinate,
                        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                    )
                }
            }
        }
        .onReceive(locManager.$currentLocation) { loc in
            guard let loc, mapVM.pins.isEmpty else { return }
            withAnimation {
                mapVM.region = MKCoordinateRegion(
                    center: loc.coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                )
            }
        }
        .alert("Ошибка", isPresented: .constant(mapVM.errorMessage != nil)) {
            Button("OK") { mapVM.errorMessage = nil }
        } message: {
            if let error = mapVM.errorMessage { Text(error) }
        }
    } // end mapContent

    // MARK: - Private

    private func handleTap(on pin: MemoryPin) {
        let nearby = mapVM.nearbyPins(to: pin)
        if nearby.count > 1 {
            clusterPins = nearby
            showingClusterPicker = true
        } else {
            selectedPin = pin
        }
    }
}

// MARK: - StickerView

struct StickerView: View {
    let pin: MemoryPin
    let selectedPin: MemoryPin?

    private var backgroundColor: Color {
        let colors: [Color] = [.blue, .green, .orange, .purple, .pink, .red, .teal, .indigo]
        return colors[abs(pin.id.hashValue) % colors.count]
    }

    private var size: CGFloat {
        let photoCount = (pin.photos as? Set<PhotoEntity>)?.count ?? 0
        return photoCount > 5 ? 64 : photoCount > 2 ? 56 : photoCount > 0 ? 52 : 48
    }

    private var iconSize: CGFloat { size * 0.55 }

    var body: some View {
        ZStack {
            Circle()
                .fill(backgroundColor)
                .shadow(color: .black.opacity(0.3), radius: 6, x: 0, y: 3)
                .frame(width: size, height: size)

            Image(systemName: pin.safeSticker)
                .resizable()
                .scaledToFit()
                .frame(width: iconSize, height: iconSize)
                .foregroundColor(.white)
        }
        .overlay(Circle().stroke(Color.white.opacity(0.9), lineWidth: 2.5))
        .scaleEffect(selectedPin?.id == pin.id ? 1.3 : 1.0)
        .animation(.spring(response: 0.35, dampingFraction: 0.6), value: selectedPin?.id)
    }
}

#Preview {
    ContentView()
}
