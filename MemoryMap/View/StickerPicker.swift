// StickerPicker.swift
import SwiftUI

/// Компонент для выбора стикера из доступных символов
struct StickerPicker: View {
    @Binding var selectedSticker: String
    let stickers: [String]
    let columns: Int
    
    init(
        selectedSticker: Binding<String>,
        stickers: [String] = StickerSymbols.extended,
        columns: Int = 6
    ) {
        self._selectedSticker = selectedSticker
        self.stickers = stickers
        self.columns = columns
    }
    
    var body: some View {
        LazyVGrid(
            columns: Array(repeating: GridItem(.flexible()), count: columns),
            spacing: 12
        ) {
            ForEach(stickers, id: \.self) { sticker in
                Button {
                    withAnimation(.spring(response: 0.3)) {
                        selectedSticker = sticker
                    }
                } label: {
                    Image(systemName: sticker)
                        .font(.title2)
                        .frame(width: 44, height: 44)
                        .background(selectedSticker == sticker ? Color.blue : Color.gray.opacity(0.2))
                        .foregroundColor(selectedSticker == sticker ? .white : .primary)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State private var selected = "camera"
        
        var body: some View {
            Form {
                Section("Выберите стикер") {
                    StickerPicker(selectedSticker: $selected)
                }
            }
        }
    }
    
    return PreviewWrapper()
}
