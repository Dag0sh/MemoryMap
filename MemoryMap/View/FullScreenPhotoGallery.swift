// FullScreenPhotoGallery.swift
import SwiftUI

struct FullScreenPhotoGallery: View {
    let photos: [PhotoEntity]
    let startIndex: Int
    @State private var currentIndex: Int
    @Environment(\.dismiss) var dismiss

    init(photos: [PhotoEntity], startIndex: Int) {
        self.photos = photos
        self.startIndex = startIndex
        _currentIndex = State(initialValue: startIndex)
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            TabView(selection: $currentIndex) {
                ForEach(photos.indices, id: \.self) { index in
                    ZoomableImage(photo: photos[index])
                        .tag(index)
                }
            }
            .tabViewStyle(.page)
            .indexViewStyle(.page(backgroundDisplayMode: .always))

            // Кнопка закрытия
            VStack {
                HStack {
                    Spacer()
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title)
                            .foregroundColor(.white)
                            .background(Color.black.opacity(0.7))
                            .clipShape(Circle())
                    }
                    .padding()
                }
                Spacer()
            }

            // Индикатор
            VStack {
                Spacer()
                Text("\(currentIndex + 1) / \(photos.count)")
                    .font(.headline)
                    .foregroundColor(.white.opacity(0.9))
                    .padding(10)
                    .background(Color.black.opacity(0.6))
                    .clipShape(Capsule())
                    .padding(.bottom, 50)
            }
        }
    }
}

struct ZoomableImage: View {
    let photo: PhotoEntity
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset = CGSize.zero
    @State private var lastOffset = CGSize.zero

    var body: some View {
        if let data = photo.imageData, let ui = UIImage(data: data) {
            Image(uiImage: ui)
                .resizable()
                .scaledToFit()
                .scaleEffect(scale)
                .offset(offset)
                .gesture(
                    MagnificationGesture()
                        .onChanged { value in
                            let delta = value / lastScale
                            lastScale = value
                            scale *= delta
                        }
                        .onEnded { _ in
                            lastScale = 1.0
                            withAnimation {
                                if scale < 1.0 { scale = 1.0; offset = .zero; lastOffset = .zero }
                                if scale > 5.0 { scale = 5.0 }
                            }
                        }
                )
                .simultaneousGesture(
                    DragGesture()
                        .onChanged { value in
                            offset = CGSize(
                                width: lastOffset.width + value.translation.width,
                                height: lastOffset.height + value.translation.height
                            )
                        }
                        .onEnded { _ in
                            lastOffset = offset
                        }
                )
                .gesture(
                    TapGesture(count: 2)
                        .onEnded {
                            withAnimation(.spring()) {
                                if scale > 1.0 {
                                    scale = 1.0
                                    offset = .zero
                                    lastOffset = .zero
                                } else {
                                    scale = 3.0
                                }
                            }
                        }
                )
        }
    }
}
