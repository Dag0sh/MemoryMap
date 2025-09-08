import MapKit
import SwiftUI

struct ContentView: View {
    @StateObject private var mapVM = MapViewModel()
    @StateObject private var locManager = LocationManager()
    @State private var showingAdd = false
    @State private var selectedPin: MemoryPin?

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Map(
                coordinateRegion: $mapVM.region,
                annotationItems: mapVM.pins
            ) { pin in
                MapAnnotation(
                    coordinate: CLLocationCoordinate2D(
                        latitude: pin.latitude,
                        longitude: pin.longitude
                    )
                ) {
                    Text(pin.sticker ?? "📍")
                        .font(.title2)
                        .onTapGesture {
                            selectedPin = pin
                        }
                }
            }
            .ignoresSafeArea()

            VStack {
                Spacer()
                HStack {
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
                        Label("Location", systemImage: "location.circle.fill")
                            .font(.title2)
                            .padding()
                            .background(Color.green.opacity(0.8))
                            .foregroundColor(.white)
                            .clipShape(Capsule())
                            .shadow(radius: 5)
                    }

                    Spacer()

                    Button {
                        showingAdd = true
                    } label: {
                        Label("Add Memory", systemImage: "plus.circle.fill")
                            .font(.title2)
                            .padding()
                            .background(Color.blue.opacity(0.8))
                            .foregroundColor(.white)
                            .clipShape(Capsule())
                            .shadow(radius: 5)
                    }
                }
                .padding()
            }
            .sheet(isPresented: $showingAdd) {
                        AddMemoryView(viewModel: mapVM, location: locManager.currentLocation)
                    }
            // Sheet для просмотра выбранного пина
            .sheet(item: $selectedPin) { pin in
                VStack {
                    Text(pin.title ?? "Без названия")
                        .font(.headline)
                        .padding(.bottom, 5)

                    if let photosSet = pin.photos as? Set<PhotoEntity>, !photosSet.isEmpty {
                        let photos = photosSet.sorted { ($0.date ?? Date.distantPast) < ($1.date ?? Date.distantPast) }
                        ScrollView(.horizontal) {
                            HStack {
                                ForEach(photos, id: \.id) { photo in
                                    if let data = photo.imageData,
                                       let ui = UIImage(data: data) {
                                        Image(uiImage: ui)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 150, height: 120)
                                            .clipped()
                                            .cornerRadius(8)
                                    }
                                }
                            }
                        }
                        .frame(height: 130)
                    } else {
                        Text("Нет фото")
                    }

                    Spacer()
                }
                .padding()
            }
            .onAppear {
                mapVM.fetchPins()
                if let loc = locManager.currentLocation {
                    withAnimation {
                        mapVM.region = MKCoordinateRegion(
                            center: loc.coordinate,
                            span: MKCoordinateSpan(
                                latitudeDelta: 0.01,
                                longitudeDelta: 0.01
                            )
                        )
                    }
                }
            }
        }
    }
}
